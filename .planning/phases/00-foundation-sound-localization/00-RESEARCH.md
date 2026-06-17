# Phase 0: Foundation, Sound & Localization - Research

**Researched:** 2026-06-17
**Domain:** Godot 4.6 GDScript — event system refactoring, audio architecture, settings persistence, bilingual localization
**Confidence:** HIGH

## Summary

Phase 0 establishes all infrastructure layers for the Tic-Tac-Toe game. The codebase already has a functional event system (mc_game_framework EventBus), audio playback (SoundManager with 4 channels), and localization hooks (I18NManager with JSON-to-Translation loading). What is missing is (1) event system hardening via `class_name` to eliminate script-path fragility, (2) a dedicated AudioController autoload that bridges game events to sound playback, (3) a SettingsManager autoload for ConfigFile-based persistence, and (4) translation JSON files with comprehensive `tr()` adoption.

All decisions are locked in CONTEXT.md. The user has chosen specific implementation patterns: mc_game_framework's ResourceLocation + RegistryManager for sound resources, an EventBus-driven AudioController that never touches GameManager directly, and I18NManager's existing JSON flattening for translations. Research confirms these patterns are well-supported by the existing framework code.

**Primary recommendation:** Execute all decisions as specified in CONTEXT.md. No architectural alternatives needed — the existing framework provides everything required. The highest risk item is the autoload order (SettingsManager before AudioController) and the double SoundManager registration fix, both of which are straightforward but order-sensitive.

## User Constraints (from CONTEXT.md)

### Locked Decisions

**Event System Refactoring**
- D-01: Add `class_name` to all 7 existing event scripts + new Phase 0 events. `get_event_type()` auto-resolves to class name.
- D-02: Remove `_event_types` dictionary and `_cache_event_types()` from GameManager. Publish directly.
- D-03: All subscriptions use StringName literals: `EventBus.subscribe(&"CellPlacedEvent", callback)`.
- D-04: New Phase 0 event: `SettingChangedEvent` with `key: String, value: Variant`.

**Audio Architecture**
- D-05: AudioBusLayout: 2 custom buses under Master — **SFX** and **Music**. UI sounds route through SFX.
- D-06: New `AudioController` autoload (registered after SettingsManager). Listens to EventBus game events, calls SoundManager. GameManager never touches audio.
- D-07: Sound-to-event mapping uses ResourceLocation + RegistryManager. New `SoundRegistry` extends `RegistryBase`. Namespace `tic_tac_toe:`.
- D-08: AudioController preloads all sound resources in `_ready()` from SoundRegistry into a memory cache. No lazy loading.
- D-09: SoundManager channels: `set_default_sound_bus("SFX")`, `set_default_music_bus("Music")` in AudioController._ready().
- D-10: Kenney sound mapping: place mark → drop, win → confirmation, lose → error, draw → bong, button click → click, button hover → tick.
- D-11: Background music: `music/off_to_osaka.mp3` only. Crossfade via `SoundManager.play_music(crossfade_duration)`.
- D-12: Volume recovery: AudioController reads saved values from SettingsManager, applies via `set_sound_volume()`/`set_music_volume()`. Defaults SFX=0.8, Music=0.8.
- D-13: FND-02: Remove SoundManager uid-based entry from `project.godot [autoload]`. Keep plugin-based registration only.
- D-14: FND-03: AudioController._ready() detects SFX/Music buses at runtime, creates if missing.

**Settings Persistence**
- D-15: New `SettingsManager` autoload — centralized ConfigFile persistence. `get(key)`/`set(key, value)` API. `set()` publishes `SettingChangedEvent`.
- D-16: ConfigFile `user://settings.cfg`. Sections: `[audio]` (sfx_volume, music_volume), `[gameplay]` (difficulty), `[language]` (locale).
- D-17: Save strategy: persist on settings screen close or game exit (NOT per-change).
- D-18: Default settings from Resource file (`res://resources/default_settings.tres`). Hardcoded fallbacks.
- D-19: Corrupt/missing config: silent fallback to defaults + `push_warning()`.
- D-20: Autoload order: SettingsManager → AudioController.

**Localization**
- D-21: Translation keys nested JSON by UI panel. I18NManager flattens nested dict to dotted keys.
- D-22: Source language zh_CN, ASCII-only keys. English in separate en_US.json with same structure.
- D-23: CJK font MiSans-Semibold.ttf via global Theme resource at `res://resources/theme/default_theme.tres`.
- D-24: All UI text uses `tr("key.path")`. `LanguageChangedEvent` drives real-time UI refresh.
- D-25: All 16 existing hardcoded Chinese strings replaced with `tr()` calls in a single pass.
- D-26: Translation files loaded at startup. SettingsManager restores last-used locale.

### Claude's Discretion
- Specific kenney sound file selection within each semantic category.
- ResourceLocation path naming within `tic_tac_toe:` namespace.
- SoundRegistry internal structure (RegistryBase patterns).
- Theme resource font size and Control node base type defaults.

### Deferred Ideas (OUT OF SCOPE)
- Second music track for gameplay → Phase 1
- RTL support for Arabic/Hebrew → out of scope
- AudioStreamRandomizer for sound variation → future enhancement

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| FND-01 | EventBus subscriptions use StringName constants | Verified: `Event.get_event_type()` (event.gd:20-22) resolves `get_global_name()` when `class_name` is set. Adding `class_name` to all 7 event scripts makes this work. |
| FND-02 | Remove SoundManager double registration | Verified: SoundManager registered in BOTH `project.godot [autoload]` line 30 AND `addons/sound_manager/plugin.gd:6`. Removing the project.godot entry eliminates the duplicate. |
| FND-03 | Create AudioBusLayout (SFX/Music buses) | Verified: D-14 specifies runtime detection + creation fallback using `AudioServer.add_bus()`, `set_bus_name()`, `set_bus_send()`. |
| FND-04 | Add `push_error`/`push_warning` error handling | New code for SettingsManager (corrupt config) and AudioController (missing buses) should use these. |
| CQ-01 | Eliminate hardcoded `preload()` paths, use `@export` or constants | D-01 to D-03 eliminate script-path subscriptions. Settings resource path can be a const. |
| CQ-04 | Settings persistence via ConfigFile | D-15 to D-19 fully define the ConfigFile approach. Godot 4 `ConfigFile` supports `load()`/`save()` with error codes. |
| SND-01 | Game SFX playback | D-10 maps game events to kenney sounds via AudioController. SoundRegistry provides preloaded resources. |
| SND-02 | Button interaction sounds | D-10: button click → `click_*.wav`, hover → `tick_*.wav`. Routed through SFX bus per D-05. |
| SND-03 | Background music with crossfade | D-11: `off_to_osaka.mp3` with `SoundManager.play_music(crossfade_duration)`. Music class supports fade in/out via Tween. |
| SND-04 | Independent SFX/Music volume control | SoundManager provides `set_sound_volume()`/`set_music_volume()` API. SettingsManager stores persisted values. |
| L10N-01 | Chinese and English JSON translation files | Create `res://translations/zh_CN.json` and `res://translations/en_US.json`. I18NManager.load_translation() handles JSON loading. |
| L10N-02 | CJK font fallback | D-23: MiSans-Semibold.ttf at `fonts/MiSans-Semibold.ttf` (8MB) via global Theme resource. |
| L10N-03 | In-game language switch | I18NManager.set_language() + LanguageChangedEvent + UI component `_refresh_text()` pattern. |
| L10N-04 | All UI text uses `tr()` | 16 hardcoded Chinese strings identified across `main.tscn` (11) and `main.gd` (5). Replace each with `tr("key.path")`. |

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Event dispatching | Autoload (EventBus) | — | Godot singleton pattern, global access. No scene dependency. |
| Game state management | Autoload (GameManager) | — | SSOT for board, turn, scores. All systems read from here. |
| Audio playback | Autoload (AudioController) | Autoload (SoundManager) | AudioController bridges EventBus → SoundManager. SoundManager provides the playback primitives. |
| Sound resource registry | Autoload (RegistryManager + SoundRegistry) | — | RegistryManager manages typed registries. SoundRegistry extends RegistryBase. |
| Settings persistence | Autoload (SettingsManager) | — | Centralized ConfigFile layer. All systems read/write settings through it. |
| Localization | Autoload (I18NManager) | TranslationServer | I18NManager provides JSON loading and language switching. Godot's TranslationServer handles `tr()` resolution. |
| UI panel visibility | Scene (Main) | — | Phase 0 does not refactor to UIManager. Manual `_show_only()` stays for now. |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| mc_game_framework EventBus | 0.0 | Pub/sub event dispatcher | Already the project's cross-system communication backbone. No alternative considered. |
| mc_game_framework ResourceLocation | 0.0 | Namespaced resource identifier | D-07 mandates ResourceLocation pattern for sound registry. Already supports `namespace:path` format. |
| mc_game_framework RegistryBase | 0.0 | Typed registry pattern | D-07: SoundRegistry extends RegistryBase. Provides register/get_entry/has_entry API. |
| SoundManager | 2.6.1 | Audio playback with pooling, crossfade, volume control | Already integrated. 4 channels (sound_effects, ui_sound_effects, ambient_sounds, music). Volume API, bus routing, crossfade. |
| I18NManager | 0.0 | JSON-based translation loading, language switching | Already autoloaded. `load_translation()` parses JSON, flattens nested dicts, registers with TranslationServer. `set_language()` publishes LanguageChangedEvent. |
| ConfigFile | Godot 4.6 built-in | INI-style settings persistence | D-15 mandate. Supports `load()`/`save()` with error codes, section-based organization. |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| TRANSLATION_JSON | — | JSON translation files (zh_CN.json, en_US.json) | Loaded at startup by I18NManager.load_translation(). Nested keys by UI panel. |
| AudioBusLayout | — | Audio bus configuration resource | Created in editor (default_bus_layout.tres) or at runtime via AudioServer. |
| Theme (gui/theme/custom) | — | Global theme for fonts and Control defaults | Set in project.godot. Points to `res://resources/theme/default_theme.tres` with MiSans-Semibold. |

### Alternatives Considered
No alternatives — all decisions are locked per CONTEXT.md.

**Installation (no new packages — all existing):**
No external packages to install. All dependencies are existing Godot addons.

## Package Legitimacy Audit

> No external packages are installed in this phase. All dependencies are existing Godot addons (mc_game_framework, SoundManager, GUIDE, GUT) already present in the codebase. No package registry verification needed.

## Architecture Patterns

### System Architecture Diagram

```
User Input (keyboard/mouse/touch)
        |
        v
   [GUIDE Input] --> main.gd --> [GameManager] --> EventBus.publish()
                                                      |
           +------------------------------------------+------------------------------------+
           |                                          |                                    |
           v                                          v                                    v
     [Cell] (update sprite)                   [Main] (switch UI panel)            [AudioController]
                                                                                      |
                                                                                      v
                                                                              [SoundRegistry]
                                                                           (maps event -> AudioStream)
                                                                                      |
                                                                                      v
                                                                              [SoundManager]
                                                                         (play_sound / play_music)
                                                                                      |
                                                                                      v
                                                                         [AudioServer buses]
                                                                         SFX bus    Music bus
                                                                              \       /
                                                                               v     v
                                                                             [Master bus]
                                                                                 |
                                                                                 v
                                                                           [Speakers]

   [SettingsManager] <-- ConfigFile save/load --> user://settings.cfg
         |
         +---> SettingChangedEvent (on every set())
         |
         v
   [AudioController] reads volumes at startup
   [I18NManager] restores locale at startup

   [I18NManager] <-- JSON translation files --> res://translations/
         |
         +---> LanguageChangedEvent (on set_language())
         |
         v
   [Main + Cell] call _refresh_text() to update UI
```

### Recommended Project Structure
```
res://
├── autoload/
│   ├── game_manager.gd            (existing)
│   ├── settings_manager.gd        (NEW - ConfigFile persistence)
│   └── audio_controller.gd        (NEW - EventBus → SoundManager bridge)
├── scripts/
│   ├── events/
│   │   ├── cell_placed_event.gd   (MODIFY - add class_name)
│   │   ├── game_started_event.gd  (MODIFY - add class_name)
│   │   ├── turn_changed_event.gd  (MODIFY - add class_name)
│   │   ├── game_won_event.gd      (MODIFY - add class_name)
│   │   ├── game_draw_event.gd     (MODIFY - add class_name)
│   │   ├── score_changed_event.gd (MODIFY - add class_name)
│   │   ├── cursor_moved_event.gd  (MODIFY - add class_name)
│   │   └── setting_changed_event.gd (NEW - key: String, value: Variant)
│   ├── main.gd                    (MODIFY - tr() calls, LanguageChangedEvent subscription)
│   └── cell.gd                    (MODIFY - EventBus subscription paths)
├── resources/
│   ├── sound_registry.tres        (NEW - SoundRegistry resource)
│   ├── default_settings.tres      (NEW - default settings values)
│   └── theme/
│       └── default_theme.tres     (NEW - Theme with MiSans-Semibold font)
├── translations/
│   ├── zh_CN.json                 (NEW - source language translations)
│   └── en_US.json                 (NEW - English translations)
└── scenes/
    └── main.tscn                  (MODIFY - Label text → tr() keys)
```

### Pattern 1: Event Class with class_name
**What:** Every event script declares `class_name EventName` so `Event.get_event_type()` resolves to `&"EventName"` instead of the script path.
**When to use:** All event scripts in the project.
**Example:**
```gdscript
# res://scripts/events/cell_placed_event.gd
extends Event
class_name CellPlacedEvent

var cell_index: int
var player: int

func _init(p_cell_index: int, p_player: int) -> void:
    cell_index = p_cell_index
    player = p_player
```
**Source:** [VERIFIED: event.gd:20-22] — `get_event_type()` checks `s.get_global_name()` first.

### Pattern 2: Direct Event Publishing
**What:** Instead of caching event class references, instantiate directly with `EventClass.new(...)`.
**When to use:** Replaces the `_event_types` dictionary pattern in GameManager.
**Example:**
```gdscript
# Before (current code):
EventBus.publish(_event_types["cell_placed"].new(cell_index, current_player))

# After:
EventBus.publish(CellPlacedEvent.new(cell_index, current_player))
```

### Pattern 3: StringName Subscription
**What:** All EventBus subscriptions use `&"EventClassName"` instead of script path strings.
**When to use:** Every EventBus.subscribe() call in the project.
**Example:**
```gdscript
# Before (current code):
EventBus.subscribe("res://scripts/events/cell_placed_event.gd", _on_cell_placed)

# After:
EventBus.subscribe(&"CellPlacedEvent", _on_cell_placed)
```

### Pattern 4: AudioController as EventBus Listener
**What:** AudioController subscribes to game events and dispatches sound playback. No direct coupling between GameManager and audio.
**When to use:** New AudioController autoload.
**Example:**
```gdscript
# res://autoload/audio_controller.gd (conceptual)
extends Node

func _ready() -> void:
    _ensure_audio_buses()
    _cache_sounds()
    _subscribe_events()
    _apply_volumes()

func _subscribe_events() -> void:
    EventBus.subscribe(&"CellPlacedEvent", _on_cell_placed)
    EventBus.subscribe(&"GameWonEvent", _on_game_won)
    EventBus.subscribe(&"GameDrawEvent", _on_game_draw)

func _on_cell_placed(_event: Event) -> void:
    SoundManager.play_sound(_sound_cache["tic_tac_toe:sounds/game/place_mark"])

func _on_game_won(event: Event) -> void:
    var winner: int = event.get("winner")
    # Determine if player won or lost based on GameManager.player_side
    var sound := _sound_cache["tic_tac_toe:sounds/game/win"] if winner == GameManager.player_side else _sound_cache["tic_tac_toe:sounds/game/lose"]
    SoundManager.play_sound(sound)
```

### Pattern 5: SoundRegistry via ResourceLocation
**What:** Sound resources registered in a RegistryBase subclass using ResourceLocation keys under the `tic_tac_toe:` namespace.
**When to use:** AudioController sound resource management.
**Example:**
```gdscript
var registry := SoundRegistry.new()

# Register sounds
var loc := ResourceLocation.from_string("tic_tac_toe:sounds/game/place_mark")
registry.register(loc, preload("res://addons/kenney_interface_sounds/drop_001.wav"))

# Later use
var sound := registry.get_entry(ResourceLocation.from_string("tic_tac_toe:sounds/game/place_mark"))
```
**Source:** [VERIFIED: registry_base.gd:6-10] — register/get_entry/has_entry API with ResourceLocation keys.

### Pattern 6: SettingsManager ConfigFile Persistence
**What:** Autoload singleton wrapping ConfigFile with memory-cached get/set, publish-on-set, strategic save.
**When to use:** New SettingsManager autoload.
**Example:**
```gdscript
# res://autoload/settings_manager.gd (conceptual)
extends Node

const SETTINGS_PATH := "user://settings.cfg"
const DEFAULT_SETTINGS := preload("res://resources/default_settings.tres")

var _config := ConfigFile.new()
var _cache := {}  # "section/key" -> value

func _ready() -> void:
    _load_config()

func get(key: String, default = null) -> Variant:
    return _cache.get(key, default)

func set(key: String, value: Variant) -> void:
    _cache[key] = value
    EventBus.publish(SettingChangedEvent.new(key, value))

func save() -> void:
    for full_key in _cache:
        var parts := full_key.split("/", true, 1)
        _config.set_value(parts[0], parts[1], _cache[full_key])
    var err := _config.save(SETTINGS_PATH)
    if err != OK:
        push_error("SettingsManager: failed to save settings: ", err)
```

### Pattern 7: UI Text Refresh on Language Change
**What:** Components subscribe to LanguageChangedEvent and call `_refresh_text()` to update all tr() calls.
**When to use:** All scenes/scripts that display localized text.
**Example:**
```gdscript
# In Main._ready():
EventBus.subscribe(&"LanguageChangedEvent", _on_language_changed)

func _on_language_changed(_event: Event) -> void:
    _refresh_text()

func _refresh_text() -> void:
    %PvPButton.text = tr("main_menu.pvp")
    %PvAIXButton.text = tr("main_menu.pvai_x")
    # ... etc for all text elements in main.tscn
```

### Anti-Patterns to Avoid
- **Subscriptions using script path strings:** `EventBus.subscribe("res://scripts/events/cell_placed_event.gd", ...)` — fragile if files move. Use `&"CellPlacedEvent"` instead after adding `class_name`.
- **Event caching in GameManager:** `_event_types` dictionary with `load()` calls — redundant once events have `class_name` and are published directly.
- **Saving settings on every change:** Fires ConfigFile I/O on every slider drag. Use per-key `set()` with memory cache, then batch `save()` on close/exit.
- **Calling SoundManager from GameManager:** Breaks separation of concerns. AudioController listens to EventBus instead.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Event dispatching | Custom event system | mc_game_framework EventBus | Already exists with publish/subscribe/unsubscribe, stale listener cleanup, and signal binding. |
| Audio playback pool | Custom AudioStreamPlayer pool | SoundManager | Already exists with 4 channel types, pooling (8 per SFX, 2 music), crossfade Tween, volume API. |
| JSON translation loading | Custom JSON-to-Translation mapper | I18NManager.load_translation() | Already exists with nested dict flattening, Translation creation, TranslationServer registration. |
| Settings INI file parsing | Custom file parser | Godot ConfigFile | Built-in. Handles sections, key-value pairs, Variant type support, user:// path resolution. |
| Resource location parsing | Custom string format | mc_game_framework ResourceLocation | Already supports `namespace:path` format with validation, strict and loose parsing, equality checks. |

**Key insight:** Every infrastructure piece this phase needs already exists in the codebase's framework addons. No new libraries or systems need to be built from scratch — the work is wiring, refactoring subscriptions, and creating configuration files.

## Common Pitfalls

### Pitfall 1: Autoload Registration Order
**What goes wrong:** AudioController tries to read volumes from SettingsManager in `_ready()`, but SettingsManager hasn't loaded its config yet.
**Why it happens:** Godot processes autoloads in the order they appear in `project.godot [autoload]`. If AudioController is listed before SettingsManager, its `_ready()` runs first.
**How to avoid:** D-20 explicitly specifies SettingsManager → AudioController order. Verify the `[autoload]` section in project.godot after editing.
**Warning signs:** AudioController logs "volume settings not found" or uses defaults when settings exist.

### Pitfall 2: SoundManager Double Registration
**What goes wrong:** `SoundManager` is listed in both `project.godot [autoload]` (line 30) and registered by `addons/sound_manager/plugin.gd:_enter_tree()` (line 6). This can cause duplicate singletons or warnings.
**Why it happens:** Both registration mechanisms are valid independently, but together they produce a duplicate.
**How to avoid:** D-13: remove the uid-based entry `SoundManager="*uid://bjex7rgsn4fi1"` from `project.godot [autoload]`. Keep only the plugin-based registration.
**Warning signs:** Godot output log shows "SoundManager already registered" or duplicate autoload warnings.

### Pitfall 3: Bus Divergence After set_default_*_bus()
**What goes wrong:** SoundManager's channel buses are initialized in their `_init()` via `get_possible_bus()`, which tries various case forms. If the SFX bus doesn't exist yet at SoundManager init time (because AudioController creates it later in _ready()), the channel falls back to "Master".
**Why it happens:** SoundManager channels initialize their bus in `_init()`, which runs at autoload creation time — before AudioController._ready() creates the SFX/Music buses.
**How to avoid:** D-14: AudioController._ready() must call `set_default_sound_bus("SFX")` and `set_default_music_bus("Music")` AFTER `_ensure_audio_buses()` creates them. SoundManager channels will switch to the correct bus.
**Warning signs:** `_show_shared_bus_warning()` fires because music and sound share "Master".

### Pitfall 4: Translation Keys Not Updating After Language Switch
**What goes wrong:** After `I18NManager.set_language()`, the TranslationServer locale changes, but UI text that was set with concrete strings doesn't update.
**Why it happens:** Labels whose `text` property was set to a concrete string stay at that string. Only `tr()` calls reflect the new locale.
**How to avoid:** D-24: Subscribe to `LanguageChangedEvent` and call `_refresh_text()` which re-applies `tr()` to all UI elements.
**Warning signs:** Changing language in settings doesn't change any text until game restart.

### Pitfall 5: ConfigFile Load Error Not Checked
**What goes wrong:** `ConfigFile.load()` returns an error code if the file doesn't exist or is corrupt. If not checked, subsequent `get_value()` calls may return unexpected values.
**Why it happens:** First launch has no settings file. Corrupted files produce parse errors.
**How to avoid:** D-19: Always check the return value of `load()`. On error, `push_warning()` and use defaults from the resource. Never crash or show error popups.
**Warning signs:** Settings appear as defaults when they were previously customized.

### Pitfall 6: Event Subscription With No class_name Falls Back to Script Path
**What goes wrong:** If an event script is modified to add `class_name` but the subscription uses `&"OldClassName"` or the script path, EventBus treats them as different event types.
**Why it happens:** `Event.get_event_type()` returns `class_name` if set, otherwise falls back to `script.resource_path`. If only the subscriber or only the publisher updates, they disagree on the event type string.
**How to avoid:** Update BOTH the event script (add `class_name`) AND all subscriptions (change to `&"ClassName"`) in the same pass. Verify by tracing `get_event_type()` output.
**Warning signs:** Events appear to "not arrive" at subscribers after refactoring.

## Code Examples

### Event with class_name (all 7 existing events need this)
```gdscript
# Source: [VERIFIED: event.gd:20-22] — get_event_type() resolution chain
# Current code has no class_name. Add one line.

extends Event
class_name GameWonEvent  # <-- NEW

var winner: int

func _init(p_winner: int) -> void:
    winner = p_winner
```

### StringName Subscription Pattern
```gdscript
# Source: [VERIFIED: event_bus.gd:6] — subscribe() accepts StringName parameter
EventBus.subscribe(&"CellPlacedEvent", _on_cell_placed)
EventBus.subscribe(&"GameStartedEvent", _on_game_started)
EventBus.subscribe(&"GameWonEvent", _on_game_won)
EventBus.subscribe(&"GameDrawEvent", _on_game_draw)
EventBus.subscribe(&"TurnChangedEvent", _on_turn_changed)
EventBus.subscribe(&"ScoreChangedEvent", _on_score_changed)
EventBus.subscribe(&"CursorMovedEvent", _on_cursor_moved)
EventBus.subscribe(&"LanguageChangedEvent", _on_language_changed)
```

### Direct Event Publishing (replacing _event_types dictionary)
```gdscript
# Source: [VERIFIED: game_manager.gd:38-46] — current _event_types cache to replace

# Instead of:
# EventBus.publish(_event_types["cell_placed"].new(cell_index, current_player))
# Use:
EventBus.publish(CellPlacedEvent.new(cell_index, current_player))
```

### SoundManager Bus Routing
```gdscript
# Source: [VERIFIED: sound_manager.gd:99-104,202-203]
# Called in AudioController._ready() after creating buses:

# Route all sound effects (SFX + UI) to SFX bus
SoundManager.set_default_sound_bus("SFX")
SoundManager.set_default_ui_sound_bus("SFX")

# Route music to Music bus
SoundManager.set_default_music_bus("Music")
```

### Dynamic Bus Creation Fallback (FND-03 / D-14)
```gdscript
# Source: [VERIFIED: WebSearch — AudioServer.add_bus() API pattern]

func _ensure_audio_buses() -> void:
    var required_buses := ["SFX", "Music"]  # D-05: 2 buses under Master
    
    for bus_name in required_buses:
        if AudioServer.get_bus_index(bus_name) == -1:
            AudioServer.add_bus()  # appends at end
            var idx := AudioServer.bus_count - 1
            AudioServer.set_bus_name(idx, bus_name)
            AudioServer.set_bus_send(idx, "Master")
            push_warning("AudioController: created missing bus '%s' at runtime" % bus_name)
        else:
            print("AudioController: bus '%s' found" % bus_name)
```

### ConfigFile Save/Load with Error Handling
```gdscript
# Source: [VERIFIED: WebSearch — Godot 4 ConfigFile best practices]

const SETTINGS_PATH := "user://settings.cfg"

func _load_config() -> void:
    var err := _config.load(SETTINGS_PATH)
    if err != OK:
        push_warning("SettingsManager: no settings file found (%d), using defaults" % err)
        # _cache already has defaults from default_settings.tres
    else:
        _populate_cache_from_config()

func _save_config() -> void:
    var err := _config.save(SETTINGS_PATH)
    if err != OK:
        push_error("SettingsManager: failed to save settings: ", err)
```

### JSON Translation File Structure
```json
// res://translations/zh_CN.json
{
  "main_menu": {
    "title": "井字棋",
    "pvp": "双人对战",
    "pvai_x": "人机对战 - 先手",
    "pvai_o": "人机对战 - 后手",
    "score": "X胜: {0}  |  O胜: {1}  |  平局: {2}"
  },
  "hud": {
    "mode_pvp": "双人对战",
    "mode_pvai": "人机对战",
    "turn": "轮到: {0}",
    "back": "返回主菜单"
  },
  "game_over": {
    "win": "{0} 获胜!",
    "draw": "平局!",
    "rematch": "再来一局",
    "back": "返回主菜单"
  },
  "settings": {
    "title": "设置",
    "sfx_volume": "音效音量",
    "music_volume": "音乐音量",
    "difficulty": "难度",
    "language": "语言",
    "easy": "简单",
    "medium": "中等",
    "hard": "困难"
  }
}
```

### LanguageChangedEvent UI Refresh Subscription
```gdscript
# In Main._ready():
EventBus.subscribe(&"LanguageChangedEvent", _on_language_changed)

func _on_language_changed(_event: Event) -> void:
    _refresh_text()

func _refresh_text() -> void:
    # Update all dynamic text
    turn_label.text = tr("hud.turn").format([GameManager.get_current_player_text()])
    score_label.text = tr("main_menu.score").format([GameManager.player1_score, GameManager.player2_score, GameManager.draw_score])
    
    # Phase 1 will add more refresh calls here
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Event subscriptions by script path string | Event subscriptions by StringName class_name | Phase 0 | Eliminates broken subscriptions when scripts are renamed. Requires adding `class_name` to all event scripts. |
| GameManager caches event types in dictionary | GameManager publishes events directly | Phase 0 | Removes 14 lines of boilerplate, one-time `load()` per event, no manual sync needed. |
| SoundManager double-registered (project.godot + plugin) | SoundManager registered only via plugin | Phase 0 | Eliminates autoload warnings. Single source of registration truth. |
| No central AudioController | AudioController listens to EventBus, calls SoundManager | Phase 0 | Clean separation: GameManager never touches audio. |
| No settings persistence | SettingsManager with ConfigFile | Phase 0 | Volume, difficulty, language survive restarts. |
| Hardcoded Chinese strings | tr() with bilingual JSON translations | Phase 0 | Real-time language switching supported. |

**Deprecated/outdated:**
- `_event_types` dictionary pattern in GameManager — replaced by direct Event instantiation. Remove `_cache_event_types()` and the `_event_types` member variable.
- Script path subscription strings — replaced by StringName literals matching event class_name.
- SoundManager in project.godot [autoload] — redundant with plugin-based registration.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `Event.get_event_type()` will resolve to `class_name` string for all 7 events after adding `class_name` | Architecture Patterns | Verified via reading event.gd:20-22. LOW risk. |
| A2 | `AudioServer.add_bus()` with no argument appends at end (index = `bus_count - 1`) | Code Examples | Verified via WebSearch. Godot 4.6 parameter default is `at_position: int = -1`. LOW risk. |
| A3 | SoundManager's `_show_shared_bus_warning()` fires when `music.bus == sound_effects.bus` | Standard Stack | Verified via reading sound_manager.gd:212-213. HIGH confidence. |
| A4 | 16 hardcoded Chinese strings need tr() replacement | Architecture Patterns | Counted directly from main.tscn and main.gd. HIGH confidence. |
| A5 | `I18NManager.load_translation()` exists and works as described | Standard Stack | Verified via reading i18n_manager.gd. HIGH confidence. |

## Open Questions (RESOLVED)

1. **Specific kenney sound file selection for each event**
   - What we know: D-10 specifies semantic categories (drop, confirmation, error, bong, click, tick).
   - What's unclear: Which specific `_00X.wav` file for each category (e.g., `drop_001.wav` vs `drop_003.wav`).
   - Recommendation: Pick during implementation and test. The CATEGORY-TO-EVENT mapping is locked; the FILENAME is discretion.

   RESOLVED: drop_001.wav (place_mark), confirmation_001.wav (win), error_001.wav (lose), bong_001.wav (draw), click_001.wav (click), tick_001.wav (hover) -- selected per 00-02 Task 2 action.

2. **SoundRegistry resource structure**
   - What we know: Follows RegistryBase + ResourceLocation pattern under `tic_tac_toe:` namespace.
   - What's unclear: Whether SoundRegistry is a script (.gd) or a resource (.tres), and the exact key path scheme.
   - Recommendation: Implement SoundRegistry as a script extending RegistryBase. Register as type with RegistryManager via `RegistryManager.register_registry("sound", SoundRegistry.new())`. Use key paths like `tic_tac_toe:sounds/game/place_mark`.

   RESOLVED: SoundRegistry as script (resources/sound/sound_registry.gd) extending RegistryBase with class_name SoundRegistry, registered via RegistryManager.register_registry("sound", ...). Key paths follow tic_tac_toe:sounds/game/* and tic_tac_toe:sounds/ui/* -- per 00-02 Task 2 action.

3. **Theme resource exact configuration**
   - What we know: MiSans-Semibold.ttf applied via global Theme at `res://resources/theme/default_theme.tres`.
   - What's unclear: Font size defaults, control padding, color scheme defaults.
   - Recommendation: Create minimal Theme resource with MiSans-Semibold set as default font. Default font size can be 16-20. Phase 1 will refine.

   RESOLVED: Minimal Theme resource at resources/theme/default_theme.tres with default_font = MiSans-Semibold, default_font_size = 20. No colors, styleboxes, or Control node overrides -- per 00-02 Task 1 action.

4. **Settings resource file format**
   - What we know: `res://resources/default_settings.tres` with all defaults.
   - What's unclear: Whether this is a proper Godot Resource (.tres) or a simple dictionary.
   - Recommendation: Use a simple GDScript Resource (extends Resource) with exported properties for each setting. This gives editor-friendly editing and type safety.

   RESOLVED: Removed from plan -- @export defaults on SettingsManager (extends Node) provide fallback values directly. Standalone .tres resource is skipped to avoid Resource-vs-Node script type mismatch.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Godot Engine 4.6 | All systems | ✓ | 4.6 (project.godot:19) | — |
| mc_game_framework (EventBus, ResourceLocation, RegistryBase) | Event system, SoundRegistry | ✓ | 0.0 | — |
| SoundManager (2.6.1) | Audio playback | ✓ | 2.6.1 | — |
| I18NManager | Localization | ✓ | 0.0 | — |
| GUIDE | Input (existing, not modified in Phase 0) | ✓ | 0.13.0 | — |
| ConfigFile | Settings persistence | ✓ | Built-in Godot 4.6 | — |
| Kenney interface sounds (99+ WAV) | Sound effects | ✓ | CC0 | — |
| MiSans-Semibold.ttf | CJK font rendering | ✓ | 8MB .ttf | — |
| off_to_osaka.mp3 | Background music | ✓ | single track | — |
| GUT (9.6.0) | Testing framework | ✓ | 9.6.0 | Not used in Phase 0 (CQ scope deferred) |

**Missing dependencies with no fallback:** None.

## Validation Architecture

Skipped — `workflow.nyquist_validation` is explicitly set to `false` in `.planning/config.json`.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V5 Input Validation | yes | ConfigFile values validated at read time. Type checks before setting AudioServer bus volumes. |
| V6 Cryptography | no | No cryptographic operations in this phase. Settings files are user-local, no sensitive data. |

### Known Threat Patterns

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Corrupted ConfigFile causing crash | Tampering | `ConfigFile.load()` error code check + `push_warning()` + silent fallback to defaults (D-19). No crash. |
| Invalid volume values (NaN, negative) | Tampering | `set_sound_volume()`/`set_music_volume()` receive `volume_between_0_and_1` — clamp at 0.0-1.0 before passing. |
| Missing translation file loading | Denial of Service | `load_translation()` returns `false` on failure (already implemented). `tr()` falls back to key string if no translation found (Godot default). |

## Sources

### Primary (HIGH confidence)
- [VERIFIED: Codebase reading] — Addons/sound_manager/sound_manager.gd — API for playback, volume, bus routing, crossfade
- [VERIFIED: Codebase reading] — addons/mc_game_framework/event/event.gd — get_event_type() resolution chain (class_name priority)
- [VERIFIED: Codebase reading] — addons/mc_game_framework/autoload/event_bus.gd — subscribe()/publish() signatures
- [VERIFIED: Codebase reading] — addons/mc_game_framework/autoload/i18n_manager.gd — load_translation(), set_language(), _flatten_dict()
- [VERIFIED: Codebase reading] — addons/mc_game_framework/utils/resource_location.gd — from_string()/parse()/validate()
- [VERIFIED: Codebase reading] — addons/mc_game_framework/registry/registry_base.gd — register()/get_entry()/has_entry()
- [VERIFIED: Codebase reading] — addons/mc_game_framework/autoload/registry_manager.gd — register_registry()/get_registry()
- [VERIFIED: Codebase reading] — addons/sound_manager/plugin.gd — add_autoload_singleton("SoundManager", ...) causing duplicate
- [VERIFIED: Codebase reading] — project.godot [autoload] — SoundManager uid-based entry (line 30), duplicate with plugin
- [VERIFIED: Codebase reading] — project.godot [autoload] — existing autoload chain (GameManager, RegistryManager, EventBus, I18NManager, UIManager, SoundManager, GUIDE)
- [VERIFIED: Codebase reading] — main.tscn — 11 hardcoded Chinese strings across labels/buttons
- [VERIFIED: Codebase reading] — main.gd — 5 hardcoded Chinese strings in EventBus handlers
- [VERIFIED: Codebase reading] — addons/kenney_interface_sounds/ — 99+ WAV files, 20 categories

### Secondary (MEDIUM confidence)
- [CITED: WebSearch — AudioServer.add_bus() API pattern] — `add_bus(at_position: int = -1)`, `set_bus_name(idx, name)`, `set_bus_send(idx, "Master")`, `get_bus_index(name)`, `set_bus_volume_db(idx, db)`, `get_bus_count()`
- [CITED: WebSearch — Godot 4 ConfigFile best practices] — `load()/save()` return error codes; always supply defaults on `get_value()`; save strategically, not per-change; `user://` path for runtime writes
- [CITED: WebSearch — Godot 4 Translation class] — `Translation.add_message(key, value)`, `TranslationServer.add_translation()`, `tr()` for runtime lookup, `NOTIFICATION_TRANSLATION_CHANGED`
- [CITED: WebSearch — Godot 4 Theme] — `gui/theme/custom` project setting; Theme resource with default font override

### Tertiary (LOW confidence)
None — all technical claims verified via codebase reading or official API patterns.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all libraries verified in codebase
- Architecture: HIGH — patterns verified against existing framework code
- Pitfalls: HIGH — based on code reading (double registration, bus routing, event type resolution)
- Environment: HIGH — all dependencies confirmed present on disk

**Research date:** 2026-06-17
**Valid until:** 2026-07-17 (stable project — no fast-moving dependencies)
