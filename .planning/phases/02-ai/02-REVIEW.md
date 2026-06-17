---
phase: 02-ai
reviewed: 2026-06-17T12:00:00Z
depth: standard
files_reviewed: 8
files_reviewed_list:
  - autoload/game_manager.gd
  - scripts/events/ai_thinking_event.gd
  - scripts/panels/hud.gd
  - scenes/panels/hud.tscn
  - test/test_game_manager.gd
  - translations/zh_CN.json
  - translations/en_US.json
  - project.godot
findings:
  critical: 1
  warning: 3
  info: 2
  total: 6
status: issues_found
---

# Phase 02: Code Review Report

**Reviewed:** 2026-06-17T12:00:00Z
**Depth:** standard
**Files Reviewed:** 8
**Status:** issues_found

## Summary

Reviewed the AI enhancement phase covering the alpha-beta minimax implementation, AI thinking event, HUD panel localization and AI state display, difficulty settings, and tests. One critical bug was found in the EASY difficulty level: the `random_chance` parameter is never applied because the `depth >= max_depth` check short-circuits before the random evaluation check. This means EASY mode plays deterministic depth-1 heuristic instead of intentionally imperfect play. Three warnings and two informational items also identified.

## Critical Issues

### CR-01: `random_chance` never applied on EASY difficulty due to early depth check

**File:** `autoload/game_manager.gd:259-262`
**Issue:** The `random_chance` parameter that is intended to inject random/imperfect play on lower difficulties is completely ineffective for EASY difficulty (`max_depth=1`).

The `_minimax` function checks `depth >= max_depth` at line 259 and returns `_evaluate()` immediately. This check runs BEFORE the `random_chance` evaluation at line 262. When `max_depth=1` (EASY), every call to `_minimax` enters with `depth=1`, immediately satisfying the depth cutoff.

The call chain from `_do_ai_move()`:
- Line 207: `max_depth = 1, random_chance = 0.8` (EASY)
- Line 218: `_find_best_move(1, 0.8)`
- Line 233: `_minimax(false, 1, ..., 1, 0.8)` -- depth=1, max_depth=1
- Line 259: `depth >= max_depth` → `1 >= 1` → **TRUE** → returns `_evaluate()` immediately
- Line 262: `random_chance > 0.0 and randf() < random_chance` → **NEVER REACHED**

The `random_chance` only matters when `depth < max_depth`, i.e., when there is room to explore deeper before the cutoff. On MEDIUM (`max_depth=4`, `random_chance=0.15`), the random check works as intended because minimax recurses deeper. But on EASY, it is dead code.

**Consequence:** EASY plays deterministic depth-1 heuristic, making it behave as a fixed-strategy bot rather than an intentionally imperfect/random opponent. The `random_chance=0.8` parameter has zero effect.

**Fix:** Move the random chance check to also execute at the `_find_best_move` level, or restructure the depth check so that randomness is applied before short-circuiting. For example:

```gdscript
func _minimax(is_maximizing: bool, depth: int, alpha: int, beta: int, max_depth: int, random_chance: float) -> int:
    # Random chance first (before terminal checks so random early-out works at all depths)
    if random_chance > 0.0 and randf() < random_chance:
        return 0
    
    var winner := _check_winner()
    if winner != -1:
        return INF_SCORE - depth if winner == ai_player else depth - INF_SCORE
    if _is_board_full():
        return 0
    if depth >= max_depth:
        return _evaluate()
    # ... rest of minimax
```

Alternatively, apply random move injection at the `_find_best_move` level:

```gdscript
func _find_best_move(max_depth: int, random_chance: float) -> int:
    # ... existing code ...
    if randf() < random_chance:
        return _pick_random_empty()    # Pick randomly instead of best
    # ... existing minimax search ...
```

## Warnings

### WR-01: EASY test passes for wrong reason -- does not validate random behavior

**File:** `test/test_game_manager.gd:81-100`
**Issue:** `test_ai_easy_random` is designed to verify that EASY difficulty (`max_depth=1, random_chance=0.8`) produces suboptimal moves due to randomness. However, because `random_chance` is never applied (see CR-01), the test passes only because the depth-1 heuristic `_evaluate()` happens to produce a suboptimal move (picking cell 5 instead of blocking at cell 2) for this specific board configuration. The test does not actually validate random/imperfect behavior.

The test sets up a board `[0, -1, -1, 1, -1, -1, -1, -1, -1]` where block (cell 2) scores 2 by heuristic, but cell 5 scores 3 by greedily building O's own line. The depth-1 AI always picks cell 5, which happens to be suboptimal. If `_evaluate()` is modified in the future (e.g., adding threat detection), the heuristic might correctly prioritize blocking, and the test would silently fail or break.

Additionally, the loop at line 91-94 resets `gm.board` and `gm.move_count` but does NOT reset `gm.current_player` or `gm.ai_player` back to fresh state (these were set before the loop but would be preserved across iterations). This works because they aren't modified in the loop, but the mutable reuse is fragile.

**Fix:** 
1. Fix CR-01 first so randomness actually works.
2. Then modify the test to actually validate random distribution rather than depending on the heuristic being suboptimal:
```gdscript
func test_ai_easy_random() -> void:
    var gm := _make_gm()
    var counts: Dictionary = {}
    for _i in range(100):
        gm.board = [0, -1, -1, 1, -1, -1, -1, -1, -1]
        gm.move_count = 2
        gm.current_player = gm.Player.O
        gm.ai_player = gm.Player.O
        var move: int = gm._find_best_move(1, 0.8)
        counts[move] = counts.get(move, 0) + 1
    # With random_chance=0.8, the distribution should NOT be a single cell 100%
    assert_gt(counts.size(), 1, "Easy AI should pick different cells across trials")
```

### WR-02: Event property access uses `.get()` instead of typed property access

**File:** `scripts/panels/hud.gd:61,67-69,76,82`
**Issue:** All event handlers use `event.get("property_name")` instead of direct typed property access (`event.property_name`). The `.get()` method on Object returns `null` for missing properties, which gets silently coerced to 0 for `int` variables. This masks typos or API mismatches during development.

Examples:
- Line 61: `var player_val: int = event.get("player")` -- should be `event.player`
- Line 67-69: `event.get("p1_score")`, `event.get("p2_score")`, `event.get("draw_score")` -- should use typed access
- Line 76: `event.get("mode")` -- should be `event.mode`
- Line 82: `event.get("thinking")` -- should be `event.thinking`

All events in the codebase have `class_name` declarations, so direct property access is fully type-safe and preferred. Using `.get()` loses compile-time validation and can silently produce wrong values if event shapes change.

**Fix:**
```gdscript
func _on_turn_changed(event: Event) -> void:
    var player_val: int = event.player    # Direct typed access
    var player_text := "X" if player_val == GameManager.Player.X else "O"
    turn_label.text = tr("hud.turn").format([player_text])
```

### WR-03: `_on_destroy` does not chain to parent class

**File:** `scripts/panels/hud.gd:26`
**Issue:** `hud.gd` extends `UIPanel` (from mc_game_framework) and overrides `_on_destroy()` to unsubscribe from EventBus events. However, it does not call `super()._on_destroy()`.

In GDScript, parent methods are NOT automatically called when a subclass overrides them. If `UIPanel._on_destroy()` performs essential cleanup (e.g., freeing child nodes, releasing resources, deregistering from UIManager), that cleanup will NOT execute for HUD instances.

This pattern is used in other panel scripts as well (`main_menu.gd`, `game_over.gd`, `pause_menu.gd`), suggesting a systemic gap.

**Fix:** Add `super()._on_destroy()` call:
```gdscript
func _on_destroy() -> void:
    super._on_destroy()
    EventBus.unsubscribe(&"TurnChangedEvent", _on_turn_changed)
    # ... rest of unsubscribes
```

## Info

### IN-01: Event subscription in `_ready()` with guard flag may mask lifecycle issues

**File:** `scripts/panels/hud.gd:15-23`
**Issue:** The `_ready()` function uses `_initialized` flag to prevent duplicate EventBus subscriptions. This works as a safety guard, but it means that if the HUD node is ever removed from the scene tree and re-added, `_ready()` will be a no-op after the first call, and EventBus subscriptions will not be re-established. This could cause the panel to stop responding to events after a reparenting or pooling operation.

The `_on_destroy()` method unsubscribes from events, but subsequent re-initialization is blocked by the `_initialized` flag. If UIManager ever pools and reuses HUD instances, the panel will lose event connectivity.

**Suggestion:** Use UIPanel's documented lifecycle methods (`_on_init` for setup, `_on_destroy` for teardown) instead of `_ready()` for EventBus subscription management. This follows the framework conventions and avoids the `_initialized` workaround.

### IN-02: `_on_game_started` handler duplicates `_refresh_all` logic

**File:** `scripts/panels/hud.gd:75-78`
**Issue:** The `_on_game_started` handler duplicates the mode label update logic that already exists in `_refresh_all()`:

```gdscript
func _on_game_started(event: Event) -> void:
    var mode_val: int = event.get("mode")
    var mode_text := tr("hud.mode_pvp") if mode_val == GameManager.GameMode.PVP else tr("hud.mode_pvai")
    mode_label.text = mode_text
```

This could simply call `_refresh_all()` since `_refresh_all()` already reads `GameManager.mode` and updates the mode label. Eliminating the duplication reduces maintenance surface area.

**Suggestion:**
```gdscript
func _on_game_started(_event: Event) -> void:
    _refresh_all()
```

---

_Reviewed: 2026-06-17T12:00:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
