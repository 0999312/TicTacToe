---
phase: 01-ui-animations
reviewed: 2026-06-17T12:00:00Z
depth: quick
files_reviewed: 11
files_reviewed_list:
  - autoload/audio_controller.gd
  - autoload/game_manager.gd
  - scripts/main.gd
  - scripts/board.gd
  - scripts/cell.gd
  - scripts/panels/main_menu.gd
  - scripts/panels/hud.gd
  - scripts/panels/game_over.gd
  - scripts/panels/pause_menu.gd
  - scripts/panels/settings.gd
  - scripts/utils/ui_helpers.gd
findings:
  critical: 3
  warning: 4
  info: 0
  total: 7
status: issues_found
---

# Phase 01: Code Review Report

**Reviewed:** 2026-06-17T12:00:00Z
**Depth:** quick
**Files Reviewed:** 11
**Status:** issues_found

## Summary

Reviewed 11 source files at quick depth focusing on Godot-specific bugs, EventBus lifecycle pairing, GUIDE context issues, and missing null checks. Found 3 critical bugs (game state corruption during pause, animation not playing on all winning cells, accumulating signal connections) and 4 warnings (missing cleanup, visual no-op, type check too broad, touch detection incomplete).

The EventBus subscriptions correctly use StringName event types matching `class_name` declarations, and the EventBus stale listener cleanup mitigates some lifecycle issues. However, the shared GUIDE action resource between board and pause menu creates a real game-state corruption path.

## Critical Issues

### CR-01: Pause menu shares `place_mark` action resource with board — Esc during pause places a mark

**File:** `scripts/panels/pause_menu.gd:30-38`, `scripts/board.gd:100`

**Issue:** The pause menu's `_on_open()` loads the same `res://resources/actions/place_mark.tres` action resource that the board uses for gameplay input. When Esc is pressed during pause, GUIDE routes the input through the pause menu's mapping context, which triggers `place_mark_action.just_triggered`. This signal has **both** connections:

- `_on_esc_pressed` (pause menu, connected with CONNECT_ONE_SHOT on line 38) — calls `UIManager.back(UILayer.POPUP)` to close the pause menu.
- `_on_place_mark` (board, connected on line 100) — calls `GameManager.place_mark(cursor_index)`.

Because `GameManager.state` remains `GameState.PLAYING` during pause (no pause state exists), the board's handler does not early-return. It places a mark at the current cursor position before the pause menu closes. This corrupts the game board while the player believes the game is frozen.

**Additional escalation:** If the player opens Settings from the pause menu (which opens on top as a NORMAL-layer panel) and then presses Esc, the ONE_SHOT connection for `_on_esc_pressed` is consumed prematurely (closing Settings and returning to pause menu). On the next Esc press, only `_on_place_mark` fires — the player can no longer resume with Esc.

**Fix:** Do not share the `place_mark` action resource. Create a dedicated action for pause-resume, or use a separate GUIDE context that does not route through a shared action. Alternatively, add a `_paused` flag to `GameManager` (or check PauseMenu is open) as an additional guard in `_on_place_mark`:

```gdscript
# In board.gd _on_place_mark, add:
if GameManager.state != GameManager.GameState.PLAYING:
    return
if not _gameplay_context:
    return  # guide context disabled during pause
```

Or better, disconnect the board's signal connection in `_on_game_paused` and reconnect in `_on_game_resumed`:

```gdscript
# board.gd
func _on_game_paused(_event: Event) -> void:
    if _gameplay_context:
        GUIDE.disable_mapping_context(_gameplay_context)
    if _place_mark_action:
        _place_mark_action.just_triggered.disconnect(_on_place_mark)

func _on_game_resumed(_event: Event) -> void:
    if _gameplay_context:
        GUIDE.enable_mapping_context(_gameplay_context, false, 0)
    if _place_mark_action and not _place_mark_action.just_triggered.is_connected(_on_place_mark):
        _place_mark_action.just_triggered.connect(_on_place_mark)
```

---

### CR-02: `_animate_winning_cells` only animates the last winning cell

**File:** `scripts/board.gd:294-303`

**Issue:** The method iterates over all winning cell indices and creates a pulse tween for each, but the `_pulse_tween` member variable is shared. Each loop iteration:
1. Kills the previous tween (`if _pulse_tween: _pulse_tween.kill()`)
2. Creates a new tween, overwriting the reference

This means only the **last** winning cell receives the pulse animation. The first two cells' tweens are killed before they begin.

```gdscript
# Line 298-303 — for each winning cell:
for c in cells:
    if c is Cell and c.cell_index == idx and c.highlight:
        if _pulse_tween:
            _pulse_tween.kill()  # KILLS the tween from the PREVIOUS cell
        _pulse_tween = create_tween().set_parallel(true).set_loops(2)
```

**Fix:** Use a single tween that animates all winning cells in parallel, or use an array of tweens:

```gdscript
# Option 1: Single tween, add all cells as parallel properties
func _animate_winning_cells(win_indices: Array) -> void:
    var cells := get_tree().get_nodes_in_group("cell")
    if _pulse_tween:
        _pulse_tween.kill()
    _pulse_tween = create_tween().set_parallel(true).set_loops(2)
    for idx in win_indices:
        for c in cells:
            if c is Cell and c.cell_index == idx and c.highlight:
                var initial_a := c.highlight.modulate.a
                _pulse_tween.tween_property(c.highlight, "modulate:a", 0.6, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
                _pulse_tween.tween_property(c.highlight, "modulate:a", 0.0, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
```

---

### CR-03: Duplicate signal connections to action resources accumulate on each game restart

**File:** `scripts/board.gd:100-105`

**Issue:** `_setup_guide_input()` loads action resources via `load()` (lines 38-43), which returns **cached** Resource instances. Signal connections are made on these shared action objects (lines 100-105) without disconnecting previous connections.

When the player returns to menu and starts a new game:
1. Old Board is freed (`_exit_tree()` calls `_disable_guide_context()` which nulls the context but does NOT disconnect signals).
2. New Board is created, subscribes to events, and `_on_game_started` calls `_setup_guide_input()`.
3. `load()` returns the same action Resource objects.
4. `.connect()` adds **another** connection on the already-connected signals.

After N menu-game cycles, each input triggers the handler N times. `_on_nav_stick` accumulates stick values N times per frame, making analog stick navigation hypersensitive. `_on_place_mark` calls `GameManager.place_mark()` N times (second+ calls are no-ops due to state guards, but still wasteful).

**Fix:** Disconnect before connecting, or guard with `is_connected()`:

```gdscript
# In _setup_guide_input, before connecting:
if not _place_mark_action.just_triggered.is_connected(_on_place_mark):
    _place_mark_action.just_triggered.connect(_on_place_mark)
# ... same for all other action connections
```

Or disconnect in `_exit_tree()`:

```gdscript
func _exit_tree() -> void:
    EventBus.unsubscribe(...)
    _disable_guide_context()
    if _place_mark_action:
        _place_mark_action.just_triggered.disconnect(_on_place_mark)
    # ... disconnect all action signals
```

## Warnings

### WR-01: Cell.gd missing EventBus unsubscriptions

**File:** `scripts/cell.gd:17-21`

**Issue:** `Cell._ready()` subscribes to 5 EventBus events (`CellPlacedEvent`, `GameStartedEvent`, `GameWonEvent`, `GameDrawEvent`, `CursorMovedEvent`) but has no `_exit_tree()` to unsubscribe them. When the Board is freed (menu->game->menu cycle), Cell nodes are freed but their Callable references remain in EventBus.

The EventBus has stale listener cleanup in `publish()` (lines 28-31 of event_bus.gd) that detects freed objects via `is_instance_valid()`, which mitigates the crash risk. However, this is a fragile pattern:
- Stale Callables are retained until the next `publish()` of each event type.
- If stale cleanup is ever modified or removed, this becomes a use-after-free bug.
- Convention across the rest of the codebase (board.gd, audio_controller.gd, hud.gd) properly pairs subscribe/unsubscribe.

**Fix:** Add `_exit_tree()` to clean up all subscriptions:

```gdscript
func _exit_tree() -> void:
    EventBus.unsubscribe(&"CellPlacedEvent", _on_cell_placed)
    EventBus.unsubscribe(&"GameStartedEvent", _on_game_started)
    EventBus.unsubscribe(&"GameWonEvent", _on_game_over)
    EventBus.unsubscribe(&"GameDrawEvent", _on_game_over)
    EventBus.unsubscribe(&"CursorMovedEvent", _on_cursor_moved)
```

---

### WR-02: Win line alpha tween is a no-op

**File:** `scripts/board.gd:280, 290`

**Issue:** The `Line2D` node created for the win line has `default_color` set to `WIN_LINE_COLOR` which has alpha 1.0 (line 280: `WIN_LINE_COLOR: Color = Color(0.91, 0.72, 0.29, 1)`). Immediately afterward, the tween animates `default_color:a` to 1.0 (line 290). Since the starting value is already 1.0, the alpha animation has no visible effect.

The intended effect likely was to fade the line in from invisible (alpha 0) while the width springs from 0 to 6. Without this, the line appears at full opacity immediately, then the width springs in.

**Fix:** Set alpha to 0 before the tween, then animate to 1.0:

```gdscript
# After creating win_line, before the tween:
win_line.default_color = WIN_LINE_COLOR
win_line.default_color.a = 0.0
win_line.width = 0.0

# Or use modulate for the whole node:
win_line.modulate = Color(1, 1, 1, 0)
# Then tween modulate:a instead of default_color:a
```

---

### WR-03: `_is_mouse_or_touch_active` does not check touch input

**File:** `scripts/board.gd:207`

**Issue:** The function name implies it checks for both mouse and touch input, but the implementation only checks `Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)`. On devices where touch does not simulate mouse events (or when mouse is not connected), this returns `false` and the touch-based cell selection via position lookup is bypassed.

**Fix:** Add touch state detection or use the more general `Input.is_action_pressed("place_mark")` approach:

```gdscript
func _is_mouse_or_touch_active() -> bool:
    if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
        return true
    if Input.is_action_pressed("touch"):
        return true  # if touch action is defined
    return false
```

---

### WR-04: `_on_place_mark` uses broad `Area2D` type check

**File:** `scripts/board.gd:177`

**Issue:** The mouse-position-based cell lookup checks `c is Area2D` which matches any Area2D node in the "cell" group. While all Cell nodes are Area2D, so this works incidentally, it provides no type safety. A non-Cell Area2D accidentally added to the "cell" group would be silently matched.

**Fix:** Use the more specific `Cell` class:

```gdscript
for c in cells:
    if c is Cell and local_pos.distance_to(c.position) < 80.0:
        cell_idx = c.cell_index
        break
```

---

_Reviewed: 2026-06-17T12:00:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: quick_
