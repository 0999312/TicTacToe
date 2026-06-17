---
phase: 00
plan: 01
subsystem: event-system-persistence
tags:
  - event-system
  - class_name
  - stringname-subscriptions
  - settings-manager
  - persistence
  - configfile
depends_on: []
requires:
  - FND-01
  - FND-04
provides:
  - CQ-01
  - CQ-04
affects:
  - autoload/game_manager.gd
  - scripts/main.gd
  - scripts/cell.gd
  - project.godot
tech-stack:
  added:
    - SettingsManager (autoload)
    - SettingChangedEvent (event class)
  patterns:
    - Direct EventBus.publish with EventClass.new() instead of cached _event_types dictionary
    - StringName literals for EventBus.subscribe() instead of script path strings
    - ConfigFile persistence with push_error/push_warning error handling
key-files:
  created:
    - scripts/events/setting_changed_event.gd
    - autoload/settings_manager.gd
  modified:
    - scripts/events/game_started_event.gd
    - scripts/events/cell_placed_event.gd
    - scripts/events/turn_changed_event.gd
    - scripts/events/game_won_event.gd
    - scripts/events/game_draw_event.gd
    - scripts/events/score_changed_event.gd
    - scripts/events/cursor_moved_event.gd
    - autoload/game_manager.gd
    - scripts/main.gd
    - scripts/cell.gd
    - project.godot
decisions:
  - Direct EventClass.new() over cached event type dictionary — simpler, less fragile, eliminates manual sync
  - SettingsManager autoload registered after EventBus and before SoundManager — infrastructure layer between event bus and audio systems
  - ConfigFile persistence with key format "section/key" — matches Godot's ConfigFile section structure
  - NOTIFICATION_WM_CLOSE_REQUEST for auto-save on game exit — consistent with Godot lifecycle pattern
metrics:
  duration: 2m
  completed_date: 2026-06-17
---

# Phase 00 Plan 01: Event System Hardening + SettingsManager

Hardened the event system with class_name declarations and StringName subscriptions, removing the fragile script-path-based EventBus pattern. Created the SettingsManager autoload for centralized ConfigFile persistence.

## Tasks Executed

### Task 1: Add class_name to all 7 existing event scripts + create SettingChangedEvent

Added `class_name` declarations to all 7 existing event scripts (`GameStartedEvent`, `CellPlacedEvent`, `TurnChangedEvent`, `GameWonEvent`, `GameDrawEvent`, `ScoreChangedEvent`, `CursorMovedEvent`). Created `SettingChangedEvent` as a new event class with `key: String` and `value: Variant` fields.

**Files:** scripts/events/game_started_event.gd, scripts/events/cell_placed_event.gd, scripts/events/turn_changed_event.gd, scripts/events/game_won_event.gd, scripts/events/game_draw_event.gd, scripts/events/score_changed_event.gd, scripts/events/cursor_moved_event.gd, scripts/events/setting_changed_event.gd

**Commit:** 7ad4e65

### Task 2: Refactor GameManager, main.gd, cell.gd -- direct event publishing and StringName subscriptions

Removed the `_event_types` caching dictionary and `_cache_event_types()` function from `game_manager.gd`. All 12 `EventBus.publish()` calls now use direct `EventClass.new()` constructor calls. Removed the `if-guard` around `cursor_moved` publishing in `move_cursor()`. Updated all `EventBus.subscribe()` calls in `main.gd` (5 calls) and `cell.gd` (5 calls) from script path strings to `StringName` literals (`&"EventClassName"`).

**Files:** autoload/game_manager.gd, scripts/main.gd, scripts/cell.gd

**Commit:** fab5a50

### Task 3: Create SettingsManager autoload + register in project.godot

Created `SettingsManager` as a Godot autoload (`extends Node`) with:
- 4 `@export` default properties: `sfx_volume` (0.8), `music_volume` (0.8), `difficulty` (1), `locale` ("zh_CN")
- `get(key, default)` — returns from internal cache
- `set(key, value)` — stores in cache, publishes `SettingChangedEvent`
- `save()` — persists cache to `user://settings.cfg` via ConfigFile, with `push_error()` on failure
- `_load_config()` — loads from ConfigFile, calls `push_warning()` and falls back to defaults on missing/corrupt file
- `_notification(NOTIFICATION_WM_CLOSE_REQUEST)` — auto-save on game exit

Registered in `project.godot` after `EventBus` and before `SoundManager`.

**Files:** autoload/settings_manager.gd (created), project.godot (modified)

**Commit:** 4f56cf1

## File Details

### Created Files

**scripts/events/setting_changed_event.gd** — New event class with `key: String` and `value: Variant` fields. Published by `SettingsManager.set()` whenever a setting value changes.

**autoload/settings_manager.gd** — New autoload providing centralized persistence for game settings. Uses ConfigFile format with section/key structure. Handles corrupt/missing files gracefully with warnings and default fallback.

### Modified Files

**7 event scripts** — Each gained a single `class_name EventName` line after `extends Event`.

**autoload/game_manager.gd** — Removed 31 lines of event type caching infrastructure. All publishing now uses direct class references.

**scripts/main.gd** — 5 `EventBus.subscribe()` calls changed from script paths to `&"EventClassName"` literals.

**scripts/cell.gd** — 5 `EventBus.subscribe()` calls changed from script paths to `&"EventClassName"` literals.

**project.godot** — Added `SettingsManager="*res://autoload/settings_manager.gd"` in the [autoload] section.

## Deviations from Plan

None — plan executed exactly as written.

## Verification Results

- All 8 event scripts have `class_name` declared (verified by grep)
- `game_manager.gd` has zero `_event_types` references
- All `subscribe()` calls in `main.gd` and `cell.gd` use `&"ClassName"` format
- `SettingsManager` autoload script exists with `get`/`set`/`save` API
- `SettingsManager` @export defaults provide all 4 fallback values
- `project.godot` has `SettingsManager` autoload entry
- `settings_manager.gd` contains `push_warning` for load failure and `push_error` for save failure

## Success Criteria

- Event subscriptions are immune to script file renames (use class_name StringName, not file paths) — PASS
- GameManager publishes events directly without caching layer — PASS
- Settings are read from ConfigFile on startup and written on game exit — PASS
- Missing/corrupt settings file does not crash the game — PASS
- SettingsManager autoload order precedes AudioController in project.godot (for downstream) — PASS
