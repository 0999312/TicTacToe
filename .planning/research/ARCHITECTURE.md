# Architecture Research

**Domain:** Godot 4.6 EventBus-driven Tic-Tac-Toe — New Feature Integration
**Researched:** 2026-06-17
**Confidence:** HIGH (all APIs verified by reading source code of every integration target)

## Standard Architecture

### System Overview

The existing architecture is EventBus-driven with GameManager as SSOT. Six new systems integrate into this: AudioController, SettingsManager, UIManager activation, Minimax AI enhancement, I18NManager activation, and Animation. The updated architecture preserves all existing patterns while adding three new autoloads and extending existing ones.

```
┌────────────────────────────────────────────────────────────────────────────┐
│                         Autoload Singletons (Global)                       │
│                                                                            │
│  ┌──────────────┐  ┌────────────┐  ┌──────────────┐  ┌────────────────┐   │
│  │  GameManager │  │ EventBus   │  │SettingsManager│  │ AudioController│   │
│  │  (SSOT)      │  │ (pub/sub)  │  │ (config)     │  │ (audio logic)  │   │
│  └──────┬───────┘  └─────┬──────┘  └──────┬───────┘  └───────┬────────┘   │
│         │                 │                │                   │           │
│  ┌──────┴───────┐  ┌─────┴──────┐  ┌──────┴───────┐           │           │
│  │ SoundManager │  │ UIManager  │  │ I18NManager  │           │           │
│  │ (audio api)  │  │ (panel stk)│  │ (translations)│          │           │
│  └──────┬───────┘  └─────┬──────┘  └──────┬───────┘           │           │
│         │                 │                │                   │           │
│  ┌──────┴───────┐  ┌─────┴──────┐         │                   │           │
│  │ RegistryMgr  │  │ GUIDE      │         │                   │           │
│  │ (type reg)   │  │ (input)    │         │                   │           │
│  └──────────────┘  └────────────┘         │                   │           │
├──────────────────────┬────────────────────────────────────────────────────┤
│                      │     reads/writes directly                          │
│                      ▼             3 new autoload subscriptions to EventBus│
│                               ┌──────────┐                               │
│  ┌─────────────────────────┐  │EventBus  │  ┌─────────────────────────┐   │
│  │ AudioController ------subscribe--->X  │  │ SettingsManager         │   │
│  │  -> SoundManager.API   │  │          │  │  -> ConfigFile           │   │
│  └─────────────────────────┘  │          │  └────────────↑────────────┘   │
│                               │  publish │               │                │
│  ┌─────────────────────────┐  │    ↓     │  ┌────────────┴────────────┐   │
│  │ GameManager             │──X────────> │  │ UIManager              │   │
│  │  -> board, turn, AI     │             │  │  -> open_panel/back    │   │
│  └─────────────────────────┘             │  └────────────┬───────────┘   │
│                                           ┌──────────────┴──────────┐   │
│  ┌─────────────────────────┐              │ Main (orchestrator)     │   │
│  │ I18NManager             │              │  -> sets up GUIDE       │   │
│  │  -> TranslationServer   │              │  -> panel lifecycle     │   │
│  └─────────────────────────┘              └─────────────────────────┘   │
├──────────────────────────────────────────────────────────────────────────┤
│                              View Layer                                  │
│  ┌──────────────────────────────────────────────────────────────────────┐│
│  │  Board (Node2D)                                                      ││
│  │  ├── Line2D x4 (grid)                                                ││
│  │  ├── WinLine (Line2D, animated via Tween)    [NEW]                   ││
│  │  └── Cell0..8 (Area2D) with Tween animation  [EXTENDED]             ││
│  └──────────────────────────────────────────────────────────────────────┘│
│  ┌──────────────────────────────────────────────────────────────────────┐│
│  │  CanvasLayer                                                         ││
│  │  ├── MainMenu (UIPanel)       [REFACTORED: extends UIPanel]         ││
│  │  ├── HUD (UIPanel)            [REFACTORED: extends UIPanel]         ││
│  │  ├── GameOverPanel (UIPanel)  [REFACTORED: extends UIPanel]         ││
│  │  ├── SettingsPanel (UIPanel)  [NEW]                                  ││
│  │  └── TransitionLayer (ColorRect, animated) [NEW]                     ││
│  └──────────────────────────────────────────────────────────────────────┘│
└──────────────────────────────────────────────────────────────────────────┘
```

### Component Responsibilities

| Component | Type | Responsibility | Integration |
|-----------|------|----------------|-------------|
| **GameManager** | Autoload (existing, extend) | Game state SSOT: board, turn, scores, Minimax AI with difficulty levels. Publishes 7+ events. | Add `AI_DIFFICULTY` enum and `set_ai_difficulty()`. Called by SettingsManager for difficulty. |
| **EventBus** | Autoload (existing, unchanged) | Publish/subscribe for cross-system events | Unchanged. All new systems subscribe to existing events. |
| **SoundManager** | Autoload (existing, activate) | Audio playback API: SFX, UI sounds, music with crossfade, volume control | Called by AudioController. Called by SettingsManager for volume. |
| **UIManager** | Autoload (existing, activate) | Stack-based panel lifecycle: open/close/pause/resume with layers | Takes over from `_show_only()`. Panels refactored to extend UIPanel and registered in UIRegistry. |
| **I18NManager** | Autoload (existing, activate) | JSON translation loading, language switching via `set_language()` | Called by SettingsManager for language. Panels call `I18NManager.get_text()` for all strings. |
| **RegistryManager** | Autoload (existing) | Type registry for UIPanels, components | Registers "ui" UIRegistry for UIManager panel instantiation. |
| **GUIDE** | Autoload (existing, unchanged) | Input framework: action mapping, multi-device | Unchanged. |
| **SettingsManager** | **NEW** autoload | Read/write `user://settings.cfg`. Exposes volume, difficulty, language. Calls SoundManager/GameManager/I18NManager directly on change. | `res://autoload/settings_manager.gd`, registered in project.godot. |
| **AudioController** | **NEW** autoload (or main.gd extension) | Subscribes to EventBus events, calls SoundManager API for SFX and BGM playback. | `res://autoload/audio_controller.gd` (preferred) or integrated into main.gd. |
| **Main** | Scene script (existing, refactor) | Scene orchestrator: GUIDE input setup, panel lifecycle via UIManager, residual EventBus subscriptions. | Reduced scope: no longer manages panel visibility directly, no longer handles audio. |
| **Board** | View (existing container, **NEW** script) | Board rendering, win line animation via Tween | `res://scripts/board.gd`. Subscribes to GameWonEvent for win line animation. |
| **Cell** | View (existing, extend) | Cell rendering, piece placement animation | Extends `refresh()` with Tween (scale from 0 to 1 on sprite change). |
| **TransitionLayer** | View (NEW node in main.tscn) | Scene transition fade-in/fade-out | ColorRect with Tween. Triggered by GameStartedEvent, restart_requested, navigate_to_menu. |

### Integration Principles

All new systems follow three rules to avoid breaking the existing architecture:

1. **GameManager stays SSOT** — No new system writes to game state. AudioController reads events but never modifies board/turn/scores.
2. **No direct calls between new systems** — They communicate through existing EventBus events or through SettingsManager (which is the sole coordinator for configuration).
3. **Existing EventBus events are extended, not replaced** — Add fields to existing events (e.g., `GameStartedEvent` gains `difficulty`) rather than creating new events for the same lifecycle points.

## Recommended Project Structure (New/Changed Files)

```
fast_prototype_test/
├── autoload/
│   ├── game_manager.gd               # [EXTEND] Add AI_DIFFICULTY, set_ai_difficulty()
│   ├── settings_manager.gd           # [NEW] ConfigFile persistence
│   └── audio_controller.gd           # [NEW] EventBus -> SoundManager bridge
├── scripts/
│   ├── main.gd                        # [REFACTOR] Remove _show_only(), use UIManager
│   ├── board.gd                       # [NEW] Win line animation, Board script
│   ├── cell.gd                        # [EXTEND] Placement animation in refresh()
│   └── events/
│       ├── ... (7 existing, unchanged)
│       └── settings_changed_event.gd  # [NEW] For SettingsManager broadcasts
├── resources/
│   ├── actions/                       # (unchanged)
│   └── translations/
│       ├── zh.json                    # [NEW] Chinese translations
│       └── en.json                    # [NEW] English translations
├── scenes/
│   ├── main.tscn                      # [EXTEND] Add TransitionLayer, SettingsPanel
│   ├── panels/
│   │   ├── main_menu.tscn            # [NEW] Extracted from main.tscn (UIPanel)
│   │   ├── hud.tscn                  # [NEW] Extracted from main.tscn (UIPanel)
│   │   ├── game_over_panel.tscn      # [NEW] Extracted from main.tscn (UIPanel)
│   │   └── settings_panel.tscn       # [NEW] Settings UI (UIPanel)
│   └── cell.tscn                      # (unchanged)
├── music/
│   └── off_to_osaka.mp3              # (existing, now actually played)
├── assets/
│   └── sprites/                       # (unchanged)
└── project.godot                      # [EXTEND] Add autoload entries
```

### Structure Rationale

- **`autoload/settings_manager.gd`:** Project-specific autoload (not addon) following the same pattern as GameManager. Keeps settings persistence separate from game logic. Registered in project.godot `[autoload]` section.
- **`autoload/audio_controller.gd`:** Project-specific autoload that bridges EventBus to SoundManager. A separate file rather than cluttering main.gd with audio handlers. Registered in project.godot.
- **`scripts/board.gd`:** Currently Board has no script — it is just a Node2D container. Adding a script encapsulates win-line animation and cell lookup, reducing main.gd's responsibilities.
- **`scenes/panels/`:** Each UI panel extracted to its own scene file so UIManager can instantiate them dynamically via UIRegistry. The `main.tscn` no longer embeds all panels directly.
- **`resources/translations/`:** JSON translation files loaded by I18NManager. Separate from code so translators can edit without touching scripts.

## Architectural Patterns

### Pattern 1: EventBus Bridge (AudioController)

**What:** A dedicated autoload that subscribes to EventBus events and translates them into SoundManager API calls. The bridge pattern isolates audio concerns from game logic.

**When to use:** When a cross-cutting concern (audio, analytics, logging) needs to react to events but should not be coupled to any specific game system.

**Trade-offs:**
- Pro: Audio logic is isolated and testable independently
- Pro: Adding/removing sounds does not touch game logic
- Con: One more autoload in the project
- Con: Cannot be used for events that need audio before the autoload is ready (not an issue here since Godot initializes autoloads before scenes)

**Example:**
```gdscript
# res://autoload/audio_controller.gd
func _ready() -> void:
    _preload_sounds()
    EventBus.subscribe("res://scripts/events/cell_placed_event.gd", _on_cell_placed)
    EventBus.subscribe("res://scripts/events/game_won_event.gd", _on_game_won)
    EventBus.subscribe("res://scripts/events/game_draw_event.gd", _on_game_draw)

func _on_cell_placed(event: Event) -> void:
    var player: int = event.get("player")
    SoundManager.play_sound(_place_sfx)

func _on_game_won(event: Event) -> void:
    SoundManager.play_sound(_win_jingle)
    SoundManager.stop_music(1.0)

func play_button_hover() -> void:
    SoundManager.play_ui_sound(_hover_sfx)

func play_button_click() -> void:
    SoundManager.play_ui_sound(_click_sfx)
```

### Pattern 2: Settings Manager as Configuration Hub

**What:** A single autoload that owns all persisted settings (volume, difficulty, language). It reads/writes `ConfigFile`, and when a value changes, it directly calls the relevant system API. UI panels do not touch config files or system APIs directly.

**When to use:** When settings are persisted and affect multiple systems (audio, game logic, localization).

**Trade-offs:**
- Pro: Single point of change for all settings — easy to add new settings
- Pro: UI panels are decoupled from system APIs (they only call SettingsManager)
- Con: Creates a dependency hub — SettingsManager knows about SoundManager, GameManager, I18NManager
- Con: SettingsManager becomes a god-object if not disciplined

**Example:**
```gdscript
# res://autoload/settings_manager.gd
var music_volume: float = 0.8:
    set(v):
        music_volume = v
        SoundManager.set_music_volume(v)
        _save()

var sfx_volume: float = 0.8:
    set(v):
        sfx_volume = v
        SoundManager.set_sound_volume(v)
        _save()

var ai_difficulty: int = 1:
    set(v):
        ai_difficulty = v
        GameManager.set_ai_difficulty(v)
        _save()

var language: String = "zh":
    set(v):
        language = v
        I18NManager.set_language(v)
        _save()

func _ready() -> void:
    _load()

func _load() -> void:
    var cfg := ConfigFile.new()
    if cfg.load("user://settings.cfg") == OK:
        music_volume = cfg.get_value("audio", "music_volume", 0.8)
        sfx_volume = cfg.get_value("audio", "sfx_volume", 0.8)
        ai_difficulty = cfg.get_value("game", "ai_difficulty", 1)
        language = cfg.get_value("i18n", "language", "zh")
    # Apply loaded values
    SoundManager.set_music_volume(music_volume)
    SoundManager.set_sound_volume(sfx_volume)
    GameManager.set_ai_difficulty(ai_difficulty)
    I18NManager.set_language(language)

func _save() -> void:
    var cfg := ConfigFile.new()
    cfg.set_value("audio", "music_volume", music_volume)
    cfg.set_value("audio", "sfx_volume", sfx_volume)
    cfg.set_value("game", "ai_difficulty", ai_difficulty)
    cfg.set_value("i18n", "language", language)
    cfg.save("user://settings.cfg")
```

### Pattern 3: UIManager Panel Lifecycle

**What:** Each UI panel (MainMenu, HUD, GameOverPanel, SettingsPanel) extends `UIPanel` and is registered in a `UIRegistry`. UIManager controls open/close/pause/resume via stack operations instead of `_show_only()`.

**When to use:** When there are multiple mutually-exclusive UI panels with lifecycle needs (open animation, pause on overlay, etc.).

**Trade-offs:**
- Pro: Panel lifecycle (on_open, on_close, on_pause, on_resume) provides hooks for i18n refresh, animation triggers, state reset
- Pro: Stack-based navigation prevents panel stacking bugs (e.g., opening a panel on top of another that should be hidden)
- Con: Requires refactoring existing panels — each must become a separate scene extending UIPanel
- Con: Adds ceremony — panel registration, ResourceLocation creation, scene extraction from main.tscn
- Con: For a 3-panel game, the overhead may exceed the benefit. Worth doing only if more panels are expected (SettingsPanel makes 4)

**Implementation approach for this project:**

Rather than extracting panels to separate scenes (which would break the existing `main.tscn` layout), use an **adapter pattern**: each panel remains in `main.tscn` but implements the `UIPanel` interface. UIManager's `add_overlay()` can mount them, or panels register themselves with UIManager.

A simpler pragmatic approach for a 4-panel game:

```gdscript
# In main.gd (or panel scripts):
func _ready() -> void:
    # Register panels with UIManager using their existing Control nodes
    main_menu_panel = _wrap_panel($CanvasLayer/MainMenu, "game:main_menu")
    hud_panel = _wrap_panel($CanvasLayer/HUD, "game:hud")
    game_over_panel = _wrap_panel($CanvasLayer/GameOverPanel, "game:game_over")
    settings_panel = _wrap_panel($CanvasLayer/SettingsPanel, "game:settings")
    
    # Register UIRegistry for panels
    var ui_reg := UIRegistry.new()
    ui_reg.register_panel(
        ResourceLocation.new("game", "main_menu"),
        preload("res://scenes/panels/main_menu.tscn")
    )
    # ... etc
    RegistryManager.register_registry("ui", ui_reg)

# Then replace _show_only():
func _show_panel(panel: UIPanel) -> void:
    # Close all current panels, open the target
    UIManager.close_all()
    UIManager.open_panel(panel.panel_id)
```

### Pattern 4: EventBus-triggered View Animations

**What:** View-layer nodes (Board, Cell, TransitionLayer) subscribe to EventBus events and run Tweens. No animation logic lives in GameManager or autoloads — animations are purely view-layer concerns.

**When to use:** When visual feedback should react to game events without coupling animation to game state.

**Trade-offs:**
- Pro: Adding/removing animations does not affect game logic
- Pro: Animations can be tested independently
- Con: EventBus events must carry enough data for the view to compute animation parameters (e.g., winning line coordinates)

**Example:**
```gdscript
# scripts/board.gd
func _ready() -> void:
    EventBus.subscribe("res://scripts/events/game_won_event.gd", _on_game_won)
    EventBus.subscribe("res://scripts/events/game_draw_event.gd", _on_game_draw)

func _on_game_won(event: Event) -> void:
    var winner: int = event.get("winner")
    var win_line: Array = _get_winning_line_indices()
    _animate_win_line(win_line)

func _animate_win_line(indices: Array) -> void:
    var start_pos: Vector2 = _get_cell_center(indices[0])
    var end_pos: Vector2 = _get_cell_center(indices[2])
    _win_line.clear_points()
    _win_line.add_point(start_pos)
    _win_line.add_point(start_pos)  # start collapsed
    var tween := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
    tween.tween_method(_update_win_line, 0.0, 1.0, 0.5)

func _update_win_line(t: float) -> void:
    var start := _win_line.get_point_position(0)
    var end := _win_line.get_point_position(1)
    _win_line.set_point_position(1, start.lerp(end, t))
```

## Data Flow

### Audio Response Flow

```
GameManager.place_mark() → EventBus.publish(CellPlacedEvent)
    ↓
AudioController._on_cell_placed()
    ↓
SoundManager.play_sound(place_sfx)
```

```
GameManager detects win → EventBus.publish(GameWonEvent)
    ↓
AudioController._on_game_won()
    ├── SoundManager.play_sound(win_jingle)
    └── SoundManager.stop_music(1.0)       # crossfade out
```

```
Main._on_back_to_menu_pressed() → UIManager.back()
    ↓
AudioController detects panel change (via UIManager events or direct)
    ├── SoundManager.stop_music()
    └── SoundManager.play_music(menu_bgm)
```

### Settings Persistence Flow

```
SettingsPanel (UIPanel)
    ↓ user adjusts slider/dropdown
SettingsManager.music_volume = 0.5       # setter fires
    ├── SoundManager.set_music_volume(0.5)
    └── ConfigFile.save("user://settings.cfg")
```

```
SettingsPanel
    ↓ user changes language dropdown
SettingsManager.language = "en"           # setter fires
    ├── I18NManager.set_language("en")
    │   └── EventBus.publish(LanguageChangedEvent)
    │       └── All open panels refresh text via _on_language_changed()
    └── ConfigFile.save("user://settings.cfg")
```

```
SettingsPanel
    ↓ user changes difficulty dropdown
SettingsManager.ai_difficulty = 2         # setter fires
    ├── GameManager.set_ai_difficulty(2)
    └── ConfigFile.save("user://settings.cfg")
```

### UIManager Panel Stack Flow (replacing _show_only())

```
_before:                            _after:
main.gd._show_only(hud)             UIManager.close_all()
                                    UIManager.open_panel("game:hud")
                                    # Pauses MainMenu, resumes HUD
                                    # MainMenu._on_pause() called
                                    # HUD._on_resume() called

_before:                            _after:
main.gd._show_only(game_over_panel) UIManager.close_all()
                                    UIManager.open_panel("game:game_over")
                                    # HUD._on_pause()
                                    # GameOverPanel._on_open({"result": ...})
```

```
GameOverPanel
    ↓ user presses "Rematch"
UIManager.close_all()
UIManager.open_panel("game:hud")
GameManager.reset_board()
```

```
SettingsPanel
    ↓ user presses "Back"
UIManager.back()
    ↓ restores previous panel (MainMenu or HUD)
```

### Localization Refresh Flow

```
I18NManager.set_language("en")
    ↓
EventBus.publish(LanguageChangedEvent.new("en"))
    ↓ (broadcast to all open panels)
MainMenu._on_language_changed()       → updates button labels
HUD._on_language_changed()            → updates "Turn:" label
GameOverPanel._on_language_changed()  → updates result text
SettingsPanel._on_language_changed()  → updates setting labels
```

### Animation Trigger Flow

```
Event destination           Event source            Animation
─────────────────────────────────────────────────────────────
Cell._on_cell_placed()  ←  CellPlacedEvent         Piece scale 0→1 (0.2s)
Board._on_game_won()    ←  GameWonEvent             Win line draw (0.5s)
TransitionLayer         ←  _start_game()            Fade out menu, fade in game (0.3s)
Button.on_hover         ←  GUIDE button signal      Scale 1→1.05 (0.1s)
Button.on_click         ←  GUIDE button signal      Scale bounce (0.15s)
```

## Integration Points

### EventBus Subscription Matrix

| Event | Publisher | Current Subscribers | New Subscribers | Purpose |
|-------|-----------|--------------------|-----------------|---------|
| `CellPlacedEvent` | GameManager | Cell, Main | AudioController | Play place SFX |
| `TurnChangedEvent` | GameManager | Main | HUD (via UIPanel lifecycle) | Update turn label |
| `GameWonEvent` | GameManager | Main | AudioController, Board | Play win SFX, animate win line |
| `GameDrawEvent` | GameManager | Main | AudioController | Play draw SFX |
| `GameStartedEvent` | GameManager | Main | AudioController, TransitionLayer | Play start SFX, start BGM, fade in |
| `ScoreChangedEvent` | GameManager | Main | HUD (via UIPanel lifecycle) | Update score display |
| `CursorMovedEvent` | GameManager | Cell | (none) | Highlight cell |
| `LanguageChangedEvent` | I18NManager | (none, framework class) | All panels | Refresh translated strings |
| `SettingsChangedEvent` | SettingsManager (optional) | (none) | Panels (if needed) | React to settings changes in real-time |

### Existing Event Field Extensions

| Event | Current Fields | New Fields |
|-------|----------------|------------|
| `GameStartedEvent` | `mode: int` | `mode: int, difficulty: int` (added for AI tracking) |
| `GameWonEvent` | `winner: int` | `winner: int, win_line: Array[int]` (added for animation — three cell indices of winning combo) |

### Direct API Calls (non-EventBus)

| Caller | Callee | Method | Reason |
|--------|--------|--------|--------|
| SettingsManager | SoundManager | `set_music_volume()`, `set_sound_volume()` | Direct API, no event needed |
| SettingsManager | GameManager | `set_ai_difficulty()` | Direct setter on SSOT |
| SettingsManager | I18NManager | `set_language()` | Triggers LanguageChangedEvent internally |
| Main | UIManager | `open_panel()`, `close_all()`, `back()` | Panel lifecycle |
| Main | GameManager | `start_game()`, `place_mark()`, `reset_board()` | Existing pattern |
| AudioController | SoundManager | `play_sound()`, `play_music()`, `stop_music()` | Audio playback API |
| SettingsPanel | SettingsManager | Property setters | Configuration hub |

## New Event: SettingsChangedEvent

```gdscript
# res://scripts/events/settings_changed_event.gd
extends Event

# Optional: used only if panels need real-time reactivity to settings
# (e.g., volume slider preview, difficulty indicator update)
var settings: Dictionary  # { "music_volume": 0.5, "sfx_volume": 0.8, ... }

func _init(p_settings: Dictionary) -> void:
    settings = p_settings
```

**Note:** This event is optional. The architecture can work without it — SettingsManager's setters already call the relevant system APIs directly. The event is only needed if UI panels must react to settings changes in real-time (e.g., showing a difficulty badge that updates when a setting changes). If added, SettingsManager publishes it after saving.

## Build Order

The build order is driven by dependency chains. No phase should depend on a system that has not been built yet.

### Phase 1: Foundation (no dependencies on other new systems)

**SettingsManager** + integrations

```
Actions:
1. Create res://autoload/settings_manager.gd
2. Register in project.godot [autoload]
3. Implement ConfigFile load/save
4. Wire setters to SoundManager, GameManager, I18NManager stubs
5. Test: change settings, verify ConfigFile written and read correctly

Dependencies: None (SoundManager/GameManager/I18NManager already registered)
```

### Phase 2A: Audio (depends on SettingsManager)

**AudioController** + SoundManager activation

```
Actions:
1. Create res://autoload/audio_controller.gd
2. Preload kenney_interface_sounds WAV assets (or convert to OGG first)
3. Subscribe to CellPlacedEvent, GameWonEvent, GameDrawEvent, GameStartedEvent
4. Wire BGM playback for menu/game scenes
5. Wire volume control to SettingsManager setters
6. Test: play through game, verify sounds fire at correct points

Dependencies: SettingsManager (for volume persistence)
```

### Phase 2B: Localization (depends on SettingsManager)

**I18NManager activation** + translation files

```
Actions:
1. Create resources/translations/zh.json and en.json
2. Load translations in a script (main.gd or a new TranslationLoader)
3. Replace all hardcoded strings in all panels with I18NManager.get_text()
4. Wire language selection to SettingsManager.language setter
5. Add _on_language_changed() to each panel for live refresh
6. Test: switch language, verify all UI strings update

Dependencies: SettingsManager (for language persistence)
```

### Phase 3: AI Enhancement (depends on SettingsManager)

**Minimax AI with difficulty levels**

```
Actions:
1. Add AI_DIFFICULTY enum to GameManager (EASY=0, MEDIUM=1, HARD=2)
2. Add set_ai_difficulty(d: int) method
3. EASY: random + depth-limited Minimax (depth 2)
4. MEDIUM: full Minimax with occasional random (30% chance)
5. HARD: full optimal Minimax (current implementation)
6. Wire difficulty to GameStartedEvent (add difficulty field)
7. Test: all three difficulties produce expected behavior

Dependencies: SettingsManager (for difficulty persistence)
```

### Phase 4: UI Refactor (independent)

**UIManager adoption**

```
Actions:
1. Create UIRegistry, register all panel scenes
2. Refactor each panel to extend UIPanel (separate scene files)
3. Replace _show_only() with UIManager.open_panel()/close_all()
4. Add panel lifecycle hooks (_on_open, _on_close, _on_pause, _on_resume)
5. Create SettingsPanel as new UIPanel
6. Wire settings panel to SettingsManager
7. Test: navigation between all panels works correctly

Dependencies: Independent (but benefits from Phase 2B for i18n-ready panels)
```

### Phase 5: Animation (depends on Phase 4 for scene transitions)

**All visual animations**

```
Actions:
1. Create board.gd script, attach to Board node in main.tscn
2. Implement win line Tween animation (subscribe to GameWonEvent)
3. Extend cell.gd refresh() with piece placement Tween
4. Create TransitionLayer (ColorRect) with fade animation
5. Add button hover/click Tweens to panel scripts
6. Wire TransitionLayer to GameStartedEvent and back-to-menu
7. Test: all animations play smoothly, no timing issues

Dependencies: Phase 4 (for transition layer integration with panel lifecycle)
```

### Dependency Graph

```
SettingsManager ──┬── AudioController
                  ├── I18NManager activation
                  └── AI Enhancement (Minimax)
                          
UIManager activation ── Animation system
(independent chain)
```

Phase 1 and Phase 4 are independent and can be done in parallel by different developers. Phase 2A, 2B, and 3 depend on Phase 1 and can be done in parallel. Phase 5 depends on Phase 4.

## Internal Boundaries

| Boundary | Communication Pattern | Notes |
|----------|----------------------|-------|
| GameManager ↔ AudioController | EventBus (indirect) | GameManager publishes events; AudioController subscribes. No direct calls. |
| SettingsManager ↔ SoundManager | Direct method call | SettingsManager calls SoundManager.set_music/sfx_volume() directly. No event needed. |
| SettingsManager ↔ GameManager | Direct method call | SettingsManager calls GameManager.set_ai_difficulty(). No event needed. |
| SettingsManager ↔ I18NManager | Direct method call | SettingsManager calls I18NManager.set_language(). I18NManager emits LanguageChangedEvent internally. |
| UI Panels ↔ I18NManager | Direct method call | Panels call I18NManager.get_text("key") for all display strings. No events needed for reads. |
| UI Panels ↔ SettingsManager | Direct property set/get | Panels read/write SettingsManager properties. No events needed. |
| UI Panels ↔ UIManager | Direct method call | Panels call UIManager.open_panel()/back(). UIManager manages lifecycle. |
| Main ↔ GameManager | Direct method call | Existing pattern (unchanged). Main calls GameManager.place_mark() etc. |
| Board/TransitionLayer ↔ EventBus | Subscribe | View-layer nodes subscribe to events for animation triggers. |
| AudioController ↔ EventBus | Subscribe | AudioController subscribes to game events. Not called by anything directly. |

## Scaling Considerations

For a local-only 2D board game on a fixed 720x720 viewport, scaling is not a concern. All considerations below are about **complexity scaling** (more features), not user scaling.

| Scale | Architecture Adjustments |
|-------|--------------------------|
| Current (4 panels, 1 board) | EventBus + autoloads + _show_only() is sufficient. UIManager adoption is optional. |
| +5 more panels (settings, credits, tutorial, leaderboard, profile) | UIManager + UIRegistry becomes essential. Manual visibility management becomes unmaintainable. |
| +online multiplayer | Requires network layer with RPC-based EventBus mirroring. Current architecture does not support this without major changes. Out of scope. |
| +procedural board sizes (4x4, 5x5) | GameManager.Minimax becomes performance-sensitive (state space grows exponentially). Need iterative deepening or alpha-beta pruning. Out of scope. |

### Complexity Scaling Priorities

1. **First bottleneck:** _show_only() if-else chain. Mitigation: UIManager adoption (Phase 4).
2. **Second bottleneck:** Hardcoded event path strings. Mitigation: Constants file for event paths.
3. **Third bottleneck:** All logic in main.gd. Mitigation: AudioController extraction, Board script creation, UIPanel lifecycle separation.

## Anti-Patterns

### Anti-Pattern 1: Calling SoundManager directly from GameManager

**What people do:** Adding `SoundManager.play_sound()` calls inside `GameManager.place_mark()` or `_check_winner()`.

**Why it's wrong:** Violates SSOT separation. GameManager should not know about audio. It creates a circular dependency (GameManager → SoundManager) that makes both harder to test and modify.

**Do this instead:** Keep GameManager clean of audio. Let AudioController subscribe to the events GameManager already publishes. Audio logic lives in one place.

### Anti-Pattern 2: God-class Settings coupling

**What people do:** Letting every UI panel read/write `ConfigFile` directly, spreading persistence logic across the codebase.

**Why it's wrong:** If the config file format changes (e.g., moving from ConfigFile to JSON), every panel must be updated. Volume normalization logic (linear ↔ dB conversion) gets duplicated.

**Do this instead:** Route all settings through SettingsManager. UI panels call `SettingsManager.sfx_volume = 0.5`. SettingsManager handles persistence and applies changes to the appropriate systems.

### Anti-Pattern 3: Blocking the main thread with Minimax

**What people do:** Running Minimax synchronously on the first move, causing a visible frame drop when the board is empty (9 choose 1 = 9 evaluations) or in late game (worst case).

**Why it's wrong:** The current Minimax explores the full tree synchronously. For Tic-Tac-Toe (max 9! = 362,880 states), the worst-case is ~1ms which is acceptable. However, if difficulty levels add depth without pruning, the thread could block noticeably.

**Do this instead:** The current Timer-based approach (0.3s delay before AI move) is correct. Keep it. For EASY difficulty, use random + depth limit. For MEDIUM, use full Minimax with random mix. For HARD, use full Minimax. Never add sleeps or blocking awaits.

### Anti-Pattern 4: Adding animations to GameManager's flow

**What people do:** Adding `await` or Tween delays inside `GameManager.place_mark()` to sequence the AI response after an animation completes.

**Why it's wrong:** GameManager becomes timing-dependent on view-layer animation duration. Changing animation speed would require changing game logic.

**Do this instead:** Let the view layer manage animation timing independently. If you need to delay the AI response until after an animation, do it in the scene script (main.gd or cell.gd), not in GameManager. The current Timer-based AI delay is independent of animation timing.

### Anti-Pattern 5: Refactoring all panels before UIManager works

**What people do:** Trying to extract all panels to separate scenes and refactor them to extend UIPanel in a single massive change.

**Why it's wrong:** High risk of breaking existing functionality. The panels are currently embedded in main.tscn with direct node references via `@onready var`. Extracting them breaks all those references.

**Do this instead:** Incremental approach:
1. First, adapt panels to register with UIManager without extracting scenes (use `add_overlay()` or a wrapper).
2. Route `_show_only()` through UIManager API while keeping panels in main.tscn.
3. Only extract to separate scenes when the panel lifecycle is working correctly.

### Anti-Pattern 6: Polluting existing events with unrelated fields

**What people do:** Adding `sfx_to_play`, `volume_level`, or other non-game-state fields to event classes like `CellPlacedEvent` or `GameWonEvent`.

**Why it's wrong:** Event classes should represent game state changes, not carry rendering/audio instructions. It couples event publishers to specific subscriber implementations.

**Do this instead:** Keep events focused on game state. Let subscribers (AudioController, Animation) decide what to play based on the event data. If you need audio-specific instructions, add a separate event or use AudioController's internal mapping.

## Sources

- Existing codebase: `res://autoload/game_manager.gd`, `res://scripts/main.gd`, `res://scripts/cell.gd` — verified the current EventBus-driven architecture, `_show_only()`, direct calls pattern
- SoundManager API: `res://addons/sound_manager/sound_manager.gd` — verified `play_sound()`, `play_music()`, `stop_music()`, volume getters/setters, `play_ui_sound()`
- UIManager API: `res://addons/mc_game_framework/autoload/ui_manager.gd` — verified `open_panel()`, `back()`, `close_all()`, `add_overlay()`, panel lifecycle methods
- I18NManager API: `res://addons/mc_game_framework/autoload/i18n_manager.gd` — verified `load_translation()`, `set_language()`, `get_text()`, LanguageChangedEvent publishing
- UIPanel base: `res://addons/mc_game_framework/ui/ui_panel.gd` — verified lifecycle callbacks (`_on_init`, `_on_open`, `_on_pause`, `_on_resume`, `_on_close`, `_on_destroy`)
- UIRegistry: `res://addons/mc_game_framework/registry/ui_registry.gd` — verified `register_panel()`, `instantiate_panel()` using PackedScene and ResourceLocation
- EventBus: `res://addons/mc_game_framework/autoload/event_bus.gd` — verified subscribe/publish pattern
- Project requirements: `.planning/PROJECT.md` — verified feature list, constraints, existing issues
- Current architecture baseline: `.planning/codebase/ARCHITECTURE.md` — verified existing component boundaries and data flows
- Codebase structure: `.planning/codebase/STRUCTURE.md` — verified directory layout and file locations

---
*Architecture research for: 井字棋游戏完善 (Tic-Tac-Toe polish)*
*Researched: 2026-06-17*
