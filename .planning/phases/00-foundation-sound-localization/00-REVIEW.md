---
phase: 00-foundation-sound-localization
reviewed: 2026-06-17T10:00:00Z
depth: standard
files_reviewed: 9
files_reviewed_list:
  - autoload/audio_controller.gd
  - autoload/settings_manager.gd
  - project.godot
  - resources/sound/sound_registry.gd
  - resources/theme/default_theme.tres
  - scenes/main.tscn
  - scripts/main.gd
  - translations/en_US.json
  - translations/zh_CN.json
findings:
  critical: 1
  warning: 5
  info: 5
  total: 11
status: issues_found
---

# Phase 00: Code Review Report

**Reviewed:** 2026-06-17T10:00:00Z
**Depth:** Standard
**Files Reviewed:** 9
**Status:** Issues Found

## Summary

This review covers the sound system (AudioController, SoundRegistry), settings persistence (SettingsManager), project configuration (project.godot), UI and input orchestration (main.gd, main.tscn), theme (default_theme.tres), and translation files (en_US.json, zh_CN.json) for the Tic-Tac-Toe game.

Key concerns:
- **BLOCKER**: `SoundManager` is NOT registered in `project.godot[autoload]`. The `SoundManager` singleton is only available during editor sessions because the `sound_manager` editor plugin calls `add_autoload_singleton` in its `_enter_tree()`. In any exported/standalone build, all `SoundManager.*` references across the codebase will fail because the identifier is never declared outside the editor.
- Settings persistence is fragile -- `save()` only fires on `WM_CLOSE_REQUEST`, and key splitting silently drops non-conforming keys.
- Win/lose audio feedback is semantically wrong in PvP mode (lose sound plays when Player O wins).
- Several quality issues around type coercion, redundant branching, and dead registry state.

---

## Critical Issues

### BL-01: SoundManager autoload registration missing from project.godot

**File:** `project.godot:23-32`
**Issue:** The `[autoload]` section registers `GameManager`, `RegistryManager`, `EventBus`, `SettingsManager`, `I18NManager`, `UIManager`, `GUIDE`, and `AudioController`, but does NOT register `SoundManager`. The `sound_manager` editor plugin (`addons/sound_manager/plugin.gd:6`) calls `add_autoload_singleton("SoundManager", ...)` in its `_enter_tree()`, which makes the singleton available during editor sessions and would normally persist the entry to `project.godot`. However, the current `project.godot` file either was regenerated from scratch (shown as "new file" in the commit diff) or the plugin-persisted entry was lost during manual edits.

**Consequence:** Every `SoundManager.*` call in `audio_controller.gd` (lines 32-34, 106-107, 115, 123, 132, 138, 144, 151, 153, 161, 166) and any other script that references `SoundManager` globally will produce "The identifier 'SoundManager' is not declared" at runtime in any exported/standalone build. The game is non-functional outside the editor without this entry.

**Fix:** Add `SoundManager` to the `[autoload]` section of `project.godot`:

```diff
 [autoload]

 GameManager="*res://autoload/game_manager.gd"
 RegistryManager="*uid://djenx0rf18ew7"
 EventBus="*uid://dqjaimeyl43vd"
 SettingsManager="*res://autoload/settings_manager.gd"
 I18NManager="*uid://wj05s0mpoqn"
 UIManager="*uid://b0mn85k3pon1l"
 GUIDE="*res://addons/guide/guide.gd"
 AudioController="*res://autoload/audio_controller.gd"
+SoundManager="*res://addons/sound_manager/sound_manager.gd"
```

---

## Warnings

### WR-01: Settings saved only on WM_CLOSE_REQUEST, silent data loss on programmatic exit

**File:** `autoload/settings_manager.gd:68-71`

**Issue:** The `save()` method is only called inside `_notification(what)` when `what == NOTIFICATION_WM_CLOSE_REQUEST`. If `get_tree().quit()` is called from any other code path (e.g., an in-game "Quit" button, a settings panel's back navigation, or the `_on_back_to_menu_pressed` handler if extended in the future), the `_notification` handler is NOT triggered and settings are silently lost. Additionally, settings are never persisted mid-session -- if the game crashes after a setting change, the change is lost.

**Fix:** Either save on every `set()` call for immediate persistence, or at minimum add a dedicated `save()` call before any programmatic quit:

```gdscript
func set(key: String, value: Variant) -> void:
    _cache[key] = value
    EventBus.publish(SettingChangedEvent.new(key, value))
    save()  # persist immediately
```

Or, if deferred saves are preferred to avoid disk IO on every change:

```gdscript
# Add a public method for explicit save from exit paths:
func quit_game() -> void:
    save()
    get_tree().quit()
```

---

### WR-02: Config save silently drops keys without exactly two path segments

**File:** `autoload/settings_manager.gd:28-31`

**Issue:** The `save()` method splits each cache key by `/` and only writes entries where `parts.size() == 2`. If any key has zero, one, or three-plus segments, the entry is silently skipped with no warning. While all current keys (`audio/sfx_volume`, `audio/music_volume`, `gameplay/difficulty`, `language/locale`) conform to the two-segment pattern, any future key that deviates will silently fail to persist.

```gdscript
for key in _cache.keys():
    var parts := key.split("/")
    if parts.size() == 2:
        _config.set_value(parts[0], parts[1], _cache[key])
    # else: silently skipped -- no warning logged
```

**Fix:** Add a warning for skipped keys, or handle arbitrary nesting:

```gdscript
for key in _cache.keys():
    var parts := key.split("/")
    if parts.size() == 2:
        _config.set_value(parts[0], parts[1], _cache[key])
    else:
        push_warning("SettingsManager: skipping key with unexpected format: %s" % key)
```

---

### WR-03: Win/lose sound distinction incorrectly applied in PvP mode

**File:** `autoload/audio_controller.gd:126-132`

**Issue:** The `_on_game_won` handler determines whether to play the "win" or "lose" sound by comparing the winner against `GameManager.player_side`. However, in PvP mode, `player_side` defaults to `Player.X` (set by `GameManager.start_game()`'s default parameter). When Player O wins in PvP mode, `is_player_win` evaluates to `false` and the "lose" sound plays -- which is semantically incorrect because there is no "player side" in PvP; both are human players.

```gdscript
func _on_game_won(event: Event) -> void:
    var winner: int = event.get("winner")
    var is_player_win := winner == GameManager.player_side  # wrong in PvP
```

**Fix:** Check game mode before applying win/lose distinction:

```gdscript
func _on_game_won(event: Event) -> void:
    var winner: int = event.get("winner")
    var key := "tic_tac_toe:sounds/game/win"
    if GameManager.mode == GameManager.GameMode.PVAI:
        var is_player_win := winner == GameManager.player_side
        key = "tic_tac_toe:sounds/game/win" if is_player_win else "tic_tac_toe:sounds/game/lose"
    var sound := _sound_cache.get(key) as AudioStream
    if sound:
        SoundManager.play_sound(sound)
```

---

### WR-04: Silent type coercion in volume change handler masks malformed events

**File:** `autoload/audio_controller.gd:149-153`

**Issue:** The `_on_setting_changed` handler reads `event.get("value")` (returning `Variant`) and applies `as float` coercion without type checking. If the event payload is malformed, contains null, or carries a non-numeric type (e.g., a string from a serialization error), the `as float` cast silently returns `0.0`, and `clampf(0.0, 0.0, 1.0)` passes it through. The user sees no error and volume is silently reset to zero.

```gdscript
SoundManager.set_sound_volume(clampf(value as float, 0.0, 1.0))
```

**Fix:** Add type validation or safe coercion with fallback:

```gdscript
func _on_setting_changed(event: Event) -> void:
    var key: String = event.get("key")
    var value = event.get("value")
    if typeof(value) != TYPE_FLOAT and typeof(value) != TYPE_INT:
        return
    var vol: float = clampf(value as float, 0.0, 1.0)
    if key == "audio/sfx_volume":
        SoundManager.set_sound_volume(vol)
    elif key == "audio/music_volume":
        SoundManager.set_music_volume(vol)
```

---

### WR-05: SoundManager bus routing points to buses that may not exist

**File:** `autoload/audio_controller.gd:31-34`

**Issue:** `_setup_bus_routing()` calls `SoundManager.set_default_music_bus("Music")` unconditionally. While `_ensure_audio_buses()` (called just before) attempts to create the "Music" bus, the bus creation could fail silently (e.g., if `AudioServer.add_bus()` returns an error or if the bus count exceeds the maximum). There is no validation that the bus exists or was successfully created before SoundManager is told to route audio through it. If routing points to a non-existent bus name, SoundManager's behavior is undefined (it may silently drop audio or use the Master bus instead, depending on implementation).

**Fix:** Validate bus existence before routing, or use a single method that creates and then routes:

```gdscript
func _setup_bus_routing() -> void:
    if AudioServer.get_bus_index("SFX") != -1:
        SoundManager.set_default_sound_bus("SFX")
        SoundManager.set_default_ui_sound_bus("SFX")
    if AudioServer.get_bus_index("Music") != -1:
        SoundManager.set_default_music_bus("Music")
```

---

## Info

### IN-01: Redundant branching in `_load_config`

**File:** `autoload/settings_manager.gd:37-43`

`_populate_cache_from_config()` is called in both branches of the `if err != OK` check. The early return on line 41 is misleading -- both paths converge on the same call. Simpler: remove the early return and always call `_populate_cache_from_config()` after the if/else.

---

### IN-02: `_config` object is never updated after `_ready`

**File:** `autoload/settings_manager.gd:10,28-31`

The `_config` (ConfigFile) object is loaded once in `_ready()`, read to populate `_cache`, and then never updated except in `save()` where data flows from `_cache` to `_config` directly to disk. The `_config` object in memory is never refreshed from `_cache`. If `_ready()` hypothetically ran again, `_config` would be stale and on-disk values would overwrite in-memory changes. Mitigated by autoload single-instance guarantee.

---

### IN-03: SoundRegistry registered globally but never consumed via the registry

**File:** `autoload/audio_controller.gd:40-41,74-80`

A `SoundRegistry` is created, registered with `RegistryManager` under the key `"sound"`, populated with 7 sound entries, then immediately iterated to populate the local `_sound_cache`. After the loop at line 80, the `SoundRegistry` object is never accessed again through `RegistryManager`. The global registration is dead state -- no system queries `RegistryManager.get_registry("sound")`. Either remove the registry registration (since all lookups go through `_sound_cache`) or use the registry as the live lookup source instead of duplicating into `_sound_cache`.

---

### IN-04: @export variables on autoload serve only as script defaults

**File:** `autoload/settings_manager.gd:3-6`

The four `@export var` declarations on the autoload script are used as fallback default values in `_populate_cache_from_config()`. Since autoload singletons are instantiated from script (not a scene), the exported values are never serialized in the editor; they always reflect the script literal defaults. This conflates editor-visible configuration with compile-time constants. Consider `const` or static defaults instead of `@export` for clarity:

```gdscript
const DEFAULT_SFX_VOLUME: float = 0.8
const DEFAULT_MUSIC_VOLUME: float = 0.8
const DEFAULT_DIFFICULTY: int = 1
const DEFAULT_LOCALE: String = "zh_CN"
```

---

### IN-05: Translation file load return value ignored

**File:** `scripts/main.gd:31-32`

`I18NManager.load_translation(...)` returns `bool` indicating success or failure, but the return value is discarded. If translation files are missing or malformed, the error is only printed to the console (via `printerr` inside `load_translation`) and the game continues with untranslated keys as text. Consider checking the return value and providing a fallback or user-visible error.

---

_Reviewed: 2026-06-17T10:00:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
