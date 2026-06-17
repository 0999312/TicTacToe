# Phase 1: UI & Animations - Research

**Researched:** 2026-06-17
**Domain:** Godot 4.6 UI framework (UIManager/UIPanel), Tween animation system, stack-based panel navigation, GUIDE per-panel input contexts, scene transitions, music crossfade, localization extension
**Confidence:** HIGH

## Summary

Phase 1 completes the visual and interaction layer: migrating all UI from direct `_show_only()` visibility toggling to UIManager stack-based navigation, extracting Board as an independent scene, adding five UIPanel scenes (MainMenu, HUD, GameOver, PauseMenu, Settings), implementing four animation systems (place mark bounce, win line draw + pulse, scene fade transitions, button micro-interactions), crossfading between two music tracks, adding Japanese (ja_JP) localization, and applying CQ-02/CQ-03 code quality improvements.

The mc_game_framework UIManager has a well-documented API (`open_panel`, `back`, `close_panel`, `close_all`) with auto-created CanvasLayer per layer, built-in background dimmer for POPUP layer, and LRU caching. Each panel extends UIPanel with six lifecycle hooks. UIRegistry maps ResourceLocation identifiers to PackedScene files. SoundManager's `play_music()` accepts a `crossfade_duration` parameter directly -- no need to hand-roll crossfade logic. AudioController already handles music playback and needs only a second track registration and scene-aware switching logic.

**Primary recommendation:** Execute Panel-by-panel (5 panels in parallel after initial infrastructure), then animation layer, then music/l10n integration. The UIManager API is mature and directly handles stack management, dimming, and caching -- do NOT override or extend it unless absolutely necessary.

## User Constraints (from CONTEXT.md)

### Locked Decisions

#### UIManager Migration
- **D-01:** Each panel is an independent `.tscn` scene inheriting `UIPanel` base class. Managed via `UIManager.open_panel()` / `close_panel()`.
- **D-02:** One-time full replacement -- all `_show_only()` calls deleted, all panels migrated simultaneously.
- **D-03:** Panel layer strategy: HUD on NORMAL layer (always visible during gameplay), GameOver as POPUP overlay on top of HUD. MainMenu, PauseMenu, Settings on NORMAL layer, mutually exclusive.
- **D-04:** Board (Node2D + 9 Cell + Line2D) becomes an independent scene. `main.tscn` becomes a root container only.
- **D-05:** Panel-to-system communication via EventBus + GameManager. Panels publish typed events; GameManager subscribes and responds. Panels never call GameManager directly.
- **D-06:** Each UIPanel creates its own GUIDEMappingContext in `_on_open()` and destroys it in `_on_close()`. Gameplay GUIDE context managed by the Board scene independently.
- **D-07:** UIRegistry uses explicit registration -- `main.gd _ready()` calls `UIManager.register_panel()` for each panel scene path.

#### Panel Inventory (new panels)
- **D-08:** New PauseMenu panel -- opened via Esc during gameplay. Three buttons: Resume (close panel), Settings (push Settings panel), Back to Main Menu (pop to MainMenu). Game screen dims behind the pause overlay (POPUP layer).
- **D-09:** Settings accessible from both MainMenu (settings button) and PauseMenu (settings button). Back button uses UIManager stack pop -- returns to whichever panel opened it.

#### Animation Style & Rhythm
- **D-10:** Overall style: light and lively. Bounce easing, durations 0.2-0.4s. Not exaggerated but noticeably playful -- fits a casual board game.
- **D-11:** Win line animation: draw a colored line across the three winning cells via Tween, plus highlight the three winning cells with a brief flash/pulse. Dual-layer feedback.
- **D-12:** Scene transitions: full-screen black ColorRect on top CanvasLayer, Tween modulate.a 0<->1. Fade out -> load -> fade in. Duration ~0.3s.
- **D-13:** Button micro-interactions: hover -> scale 1.05 + modulate brighten; press -> scale 0.95. Tween 0.1s transition. Both scale and color change.

#### Place Mark Animation
- **D-14:** X/O pieces scale from 0->1.2->1.0 with elastic/bounce easing (~0.25s duration). Implemented on Cell's Sprite2D via Tween.

#### Settings Panel Layout & Interaction
- **D-15:** Tab-based layout: Audio tab, Game tab, Language tab. TabBar at top for switching.
- **D-16:** Volume controls: HSlider (0-100) with real-time preview. Dragging immediately calls `SoundManager.set_sound_volume()` / `set_music_volume()`. Percentage label displayed next to slider. Persisted on panel close.
- **D-17:** AI difficulty: three independent side-by-side buttons (Easy / Medium / Hard). Selected button highlighted. Matches button micro-interaction style.
- **D-18:** Language: OptionButton dropdown with three entries (Chinese, English, Japanese). Extensible for future languages.
- **D-19:** Settings apply instantly on change, persist to ConfigFile on panel close (leveraging existing SettingsManager save-on-exit strategy from Phase 0).

#### Localization Extension
- **D-20:** ja_JP Japanese support added in this phase. New `ja_JP.json` translation file with same ASCII key structure as zh_CN/en_US. Added to I18NManager load list at startup. Dropdown menu supports all three languages.

#### Game Music
- **D-21:** Second music track: `music/breaktime.mp3` (already exists in project). Menu scenes = `off_to_osaka.mp3`, gameplay = `breaktime.mp3`.
- **D-22:** Crossfade duration: 1.0-1.5s between menu and gameplay music.
- **D-23:** Pause behavior: when PauseMenu opens, music volume reduces to 50% of current setting. If current music volume is already very low (below audible threshold), no reduction. Restore full volume on resume.

#### Main Menu Layout
- **D-24:** Centered vertical layout. Large title "Tic-Tac-Toe" + subtitle in MiSans-Semibold at top. Four buttons vertically stacked: [PvP] [PvAI] [Settings] [Quit]. Version number ("v0.1.0") in small text at bottom.
- **D-25:** Score display: not on main menu. Scores shown in HUD (three columns: X wins | O wins | Draws) and on Game Over panel.

#### Code Quality
- **D-26:** CQ-02: Add `push_warning` for invalid parameter values in GameManager public methods. Follow existing guard-clause patterns.
- **D-27:** CQ-03: Extract duplicate code patterns discovered during implementation to shared helpers.

### Claude's Discretion
- Exact Tween easing curves within the "light and lively" constraint
- Button base/modulate color values for hover/press states
- TabBar visual style within the overall theme
- Settings panel spacing and label placements within the tab layout
- Pause menu background dim amount (suggest 50% black overlay)
- Minor layout details within the centered vertical main menu
- `breaktime.mp3` volume normalization relative to `off_to_osaka.mp3`

### Deferred Ideas (OUT OF SCOPE)
None -- discussion stayed within phase scope.

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| UI-01 | Main menu interface -- title, PvP/PvAI buttons, settings button, quit button | D-24 layout spec; UIManager panel registration pattern via UIRegistry; MainMenu panel extends UIPanel, opens via `UIManager.open_panel("tic_tac_toe:main_menu")` |
| UI-02 | In-game HUD -- current player indicator (X/O), score display (X wins/O wins/draws) | HUD panel on NORMAL layer; subscribes to TurnChangedEvent + ScoreChangedEvent; three-column layout via HBoxContainer |
| UI-03 | Game over panel -- result display (winner/draw), play again, back to menu buttons | GameOver panel on POPUP layer (auto-dimmer); subscribes to GameWonEvent/GameDrawEvent; publishes RematchEvent for "play again" |
| UI-04 | Settings panel -- SFX/music volume sliders, AI difficulty selection, language switch | TabContainer with 3 tabs; HSlider -> SettingsManager.set_value(); OptionButton -> I18NManager.set_language(); difficulty buttons publish SettingChangedEvent |
| UI-05 | All UI panels use UIManager stack management to replace `_show_only()` | UIManager.open_panel/back/close_all replace all visibility toggling; _show_only() deleted entirely |
| ANM-01 | Win line animation -- Tween draws a highlight line across the winning row/column/diagonal | Line2D.width Tween 0->6.0 (0.3s, Trans.SPRING) + winning cell highlight pulse (0.4s loop, Trans.SINE) |
| ANM-02 | Place mark animation -- X/O piece scale bounces from 0 to 1 | Cell Sprite2D.scale Tween 0->1.2->1.0 (0.25s, Trans.BOUNCE); triggered on CellPlacedEvent when cell_index matches |
| ANM-03 | Scene transition -- menu <-> game fade in/out effect | ColorRect on CanvasLayer with layer >= UILayer.SYSTEM; modulate.a Tween 0<->1 (0.3s, Trans.LINEAR) |
| ANM-04 | Button micro-interaction -- subtle scale/color change on hover | hover: scale 1.05 + modulate 1.15 (0.1s, Trans.SINE); press: scale 0.95 (0.1s); extracted to shared helper `_setup_button_animation()` |
| CQ-02 | Add parameter validation and `push_warning` to all GameManager public methods | `place_mark(cell_index)` warn if <0 or >8; `move_cursor(direction)` warn if zero; `start_game(mode, side)` warn if invalid enum |
| CQ-03 | Extract duplicate code to shared helper functions | Button animation helper in `scripts/utils/ui_helpers.gd` |

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Panel lifecycle management | UIManager (Autoload) | UIRegistry (Autoload) | UIManager owns stack push/pop/pause/resume; UIRegistry owns scene-to-ID mapping |
| Panel-to-system communication | EventBus (Autoload) | GameManager (Autoload) | D-05: panels publish events, GameManager subscribes; no direct calls from panels to GameManager |
| Per-panel input handling | GUIDE (Autoload) | Individual panel scripts | D-06: each panel creates/destroys its own GUIDEMappingContext; Board scene manages gameplay context |
| Game state authority | GameManager (Autoload) | -- | Remains SSOT; panels are view-only, never own state |
| Music crossfade | AudioController (Autoload) | SoundManager (Autoload) | AudioController registers tracks and triggers switches; SoundManager.play_music(crossfade_duration) handles fade internally |
| Place mark animation | Cell (Area2D view) | -- | Animation runs on Cell's Sprite2D via Tween; triggered by CellPlacedEvent |
| Win line animation | Board scene | -- | New Line2D child of Board; Tween width and color alpha; cell highlight pulse on winning cells |
| Scene transition | Main (root scene) | -- | ColorRect on highest CanvasLayer; fade in/out Tween controlled by Main script |
| Button micro-interactions | Individual panels | Shared helper | Each panel applies button animation via extracted `_setup_button_animation()` helper (CQ-03) |

## Standard Stack

All technology is Godot 4.6 built-in + existing project addons. No external packages are installed in this phase.

### Core

| Component | Version | Purpose | Why Standard |
|-----------|---------|---------|--------------|
| UIManager (mc_game_framework) | 0.0 | Stack-based panel manager with layer system, caching, background dimmer | Already registered as autoload; provides open_panel/back/close_all API with lifecycle hooks |
| UIPanel (mc_game_framework) | 0.0 | Base class for all panel scenes; lifecycle: init/open/pause/resume/close/destroy | All 5 panels extend this; auto-assigns panel_id, ui_layer, cache_mode from UIRegistry |
| UIRegistry (mc_game_framework) | 0.0 | Maps ResourceLocation IDs to PackedScene files with layer/cache defaults | Registration via `register_panel(id, scene, layer, cache_mode)` in main.gd _ready |
| UILayer (mc_game_framework) | 0.0 | Layer constants: SCENE(0), NORMAL(100), POPUP(200), TOAST(300), SYSTEM(400) | HUD uses NORMAL, GameOver/PauseMenu use POPUP, MainMenu/Settings use NORMAL |
| ResourceLocation (mc_game_framework) | 0.0 | Namespaced ID format: `tic_tac_toe:main_menu` | All panel IDs and sound registry keys follow this format |
| Tween (Godot 4.6 built-in) | 4.6 | Property animation: create_tween(), set_parallel(), chaining, easing | Godot's standard animation API; used for all phase animations |
| ColorRect (Godot built-in) | 4.6 | Full-screen colored overlay for transitions and dimming | Scene transition fade + POPUP layer background dimmer (UIManager auto-creates) |
| TabContainer (Godot built-in) | 4.6 | Tabbed panel for Settings (Audio/Game/Language) | Godot's native tab container with TabBar |
| HSlider (Godot built-in) | 4.6 | Volume slider 0-100 with value label | Standard Godot range control |
| OptionButton (Godot built-in) | 4.6 | Language selection dropdown | Standard Godot dropdown |
| Line2D (Godot built-in) | 4.6 | Win line drawing with Tween width animation | Already used for grid lines; same node type for win line |
| StyleBoxFlat (Godot built-in) | 4.6 | Panel backgrounds, button bg, tab bar bg | Godot's flat stylebox; no textures needed |

### GUIDE Context Per Panel (New Pattern)

Each panel that needs input creates and destroys a GUIDEMappingContext in its lifecycle:

```
_on_open():
    _menu_context = GUIDEMappingContext.new()
    # ... add mappings ...
    GUIDE.enable_mapping_context(_menu_context, false, 0)

_on_close():
    GUIDE.disable_mapping_context(_menu_context)
```

Existing gameplay context (`main.gd:_setup_guide_input()`) moves to Board scene controller.

### Music Integration Pattern

AudioController registers `breaktime.mp3` as a second music track alongside existing `off_to_osaka.mp3`. Crossfade via `SoundManager.play_music(resource, crossfade_duration)` -- the music.gd player handles volume fade internally. Pause volume reduction via `SoundManager.set_music_volume(current * 0.5)` with a call_deferred restore.

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| UIManager stack | Manual visible toggling (`_show_only`) | Decision D-02: one-time full replacement; UIManager provides pause/resume lifecycle, auto-dimmer, caching |
| Tween | AnimationPlayer node | D-10: Tween is simpler for property animations; AnimationPlayer is overkill for 0.2-0.4s micro-animations |
| UIPanel extends Control | Extend Window | UIManager expects UIPanel base class; Window is not compatible with CanvasLayer panel stack |

## Package Legitimacy Audit

**Not applicable.** Phase 1 installs no external packages -- all technology is Godot 4.6 built-in + existing project addons (mc_game_framework, GUIDE, SoundManager) already confirmed in the codebase.

## Architecture Patterns

### System Architecture Diagram

```
                          ┌──────────────────────┐
                          │   UIManager (Auto)    │
                          │  Stack: NORMAL(100)   │
                          │  Stack: POPUP(200)    │
                          │  LRU Cache            │
                          └─────┬──────┬──────────┘
                                │      │
             ┌──────────────────┘      └──────────────┐
             ▼                                          ▼
    ┌─────────────────┐                     ┌───────────────────┐
    │   NORMAL Layer   │                     │   POPUP Layer     │
    │  (CanvasLayer)   │                     │  (CanvasLayer)    │
    ├─────────────────┤                     ├───────────────────┤
    │ MainMenu (CACHE)│                     │ GameOver (NONE)   │
    │ HUD (CACHE)     │                     │ PauseMenu (NONE)  │
    │ Settings (CACHE)│                     │ (auto-dimmer)     │
    └─────────────────┘                     └───────────────────┘
             │                                        │
             │ events                                 │ events
             ▼                                        ▼
    ┌────────────────────────────────────────────────────────┐
    │                   EventBus (Autoload)                    │
    │  GameStartedEvent | CellPlacedEvent | GameWonEvent     │
    │  TurnChangedEvent | RematchEvent | ScoreChangedEvent   │
    └─────────┬───────────────────────────────┬──────────────┘
              │                                │
              ▼                                ▼
    ┌──────────────────┐           ┌──────────────────────┐
    │  GameManager      │           │  AudioController     │
    │  (SSOT - reads    │           │  (music crossfade)   │
    │   events, updates  │           │  (pause volume)      │
    │   state, publishes │           │  (SFX trigger)       │
    │   response events) │           │                      │
    └──────────────────┘           └──────────────────────┘
              │
              ▼
    ┌──────────────────┐
    │   Board Scene     │
    │  (independent)    │
    ├──────────────────┤
    │ GUIDE gameplay    │
    │ context           │
    │ 9 Cell (Tween)    │
    │ Line2D (win)      │
    └──────────────────┘
              │
              ▼
    ┌──────────────────┐
    │  Cell (Area2D)    │
    │ Sprite2D (mark)   │
    │ Highlight (pulse) │
    │ Tween (place)     │
    └──────────────────┘

    Scene Transition:  ColorRect (CanvasLayer) → modulate.a Tween
```

### Recommended Project Structure (New/Modified Files)

```
scenes/
├── main.tscn                    # MODIFIED: root container only
├── board.tscn                   # NEW: extracted from main.tscn (Board node)
├── cell.tscn                    # UNCHANGED
├── panels/                      # NEW directory
│   ├── main_menu.tscn           # NEW: extends UIPanel
│   ├── hud.tscn                 # NEW: extends UIPanel
│   ├── game_over.tscn           # NEW: extends UIPanel
│   ├── pause_menu.tscn          # NEW: extends UIPanel
│   └── settings.tscn            # NEW: extends UIPanel
scripts/
├── main.gd                      # MODIFIED: panel registration, transition control
├── board.gd                     # NEW: GUIDE context, cell management, win line
├── cell.gd                      # MODIFIED: place mark + highlight pulse animation
├── panels/                      # NEW directory
│   ├── main_menu.gd             # NEW: panel controller
│   ├── hud.gd                   # NEW: panel controller
│   ├── game_over.gd             # NEW: panel controller
│   ├── pause_menu.gd            # NEW: panel controller
│   └── settings.gd              # NEW: panel controller
├── events/
│   ├── rematch_event.gd         # NEW: for Play Again
│   ... (existing events unchanged)
├── utils/
│   └── ui_helpers.gd            # NEW: button animation helper (CQ-03)
translations/
├── zh_CN.json                   # MODIFIED: add Phase 1 keys
├── en_US.json                   # MODIFIED: add Phase 1 keys
├── ja_JP.json                   # NEW: Japanese translation (all keys)
autoload/
├── audio_controller.gd          # MODIFIED: register breaktime.mp3, scene-aware switching
├── game_manager.gd              # MODIFIED: CQ-02 push_warning; subscribe to RematchEvent
```

### Pattern 1: Panel Registration and Opening (UIManager + UIRegistry)

**What:** Register panels with UIRegistry in `main.gd _ready()`, open with `UIManager.open_panel()`.

**When to use:** All panel initialization and navigation throughout Phase 1.

**Example:**
```gdscript
# In main.gd _ready()
var ui_reg := UIRegistry.new()
RegistryManager.register_registry("ui", ui_reg)

ui_reg.register_panel(
    ResourceLocation.from_string("tic_tac_toe:main_menu"),
    preload("res://scenes/panels/main_menu.tscn"),
    UILayer.NORMAL,
    UIPanel.CacheMode.CACHE
)
ui_reg.register_panel(
    ResourceLocation.from_string("tic_tac_toe:hud"),
    preload("res://scenes/panels/hud.tscn"),
    UILayer.NORMAL,
    UIPanel.CacheMode.CACHE
)
ui_reg.register_panel(
    ResourceLocation.from_string("tic_tac_toe:game_over"),
    preload("res://scenes/panels/game_over.tscn"),
    UILayer.POPUP,
    UIPanel.CacheMode.NONE
)
ui_reg.register_panel(
    ResourceLocation.from_string("tic_tac_toe:pause_menu"),
    preload("res://scenes/panels/pause_menu.tscn"),
    UILayer.POPUP,
    UIPanel.CacheMode.NONE
)
ui_reg.register_panel(
    ResourceLocation.from_string("tic_tac_toe:settings"),
    preload("res://scenes/panels/settings.tscn"),
    UILayer.NORMAL,
    UIPanel.CacheMode.CACHE
)
```

**Opening panels:**
```gdscript
# Open MainMenu on NORMAL layer
UIManager.open_panel(ResourceLocation.from_string("tic_tac_toe:main_menu"))

# Open GameOver on POPUP layer (auto-dimmers background)
UIManager.open_panel(ResourceLocation.from_string("tic_tac_toe:game_over"))

# Close all NORMAL panels and open MainMenu
UIManager.close_all(UILayer.NORMAL)
UIManager.open_panel(ResourceLocation.from_string("tic_tac_toe:main_menu"))

# Back button (pop stack)
UIManager.back(UILayer.NORMAL)
```

### Pattern 2: Panel Lifecycle (UIPanel subclass)

**What:** Each panel scene root extends UIPanel and overrides lifecycle methods.

**When to use:** Every new panel scene.

**Example:**
```gdscript
# scripts/panels/main_menu.gd
extends UIPanel

@onready var pvp_button: Button = $VBoxContainer/PvPButton
@onready var ai_button: Button = $VBoxContainer/AiButton
# ...

func _on_init() -> void:
    # One-time setup (called once after first instantiation)
    # Setup button animations via shared helper
    _setup_button_animation(pvp_button)
    _setup_button_animation(ai_button)

func _on_open(_data: Dictionary = {}) -> void:
    # Called every time this panel becomes visible
    _refresh_texts()

func _on_pause() -> void:
    # Called when another panel covers this one (e.g., Settings opened from MainMenu)
    pass

func _on_resume() -> void:
    # Called when covering panel is removed
    _refresh_texts()

func _on_close() -> void:
    # Called when panel is removed from stack
    pass

func _on_destroy() -> void:
    # Called before queue_free (only for CacheMode.NONE)
    pass

func _refresh_texts() -> void:
    pvp_button.text = tr("main_menu.pvp")
    ai_button.text = tr("main_menu.pvai_x")
```

### Pattern 3: Data Flow -- Panel Publishes Event, GameManager Responds (D-05)

**What:** Panels never call GameManager directly. They publish typed events; GameManager subscribes.

**When to use:** All panel-to-system communication.

**Example (Rematch flow):**
```gdscript
# scripts/events/rematch_event.gd (NEW)
extends Event
class_name RematchEvent
# No extra data needed

# scripts/panels/game_over.gd
func _on_rematch_pressed() -> void:
    EventBus.publish(RematchEvent.new())
    UIManager.back(UILayer.POPUP)  # Close GameOver panel

# autoload/game_manager.gd _ready()
EventBus.subscribe(&"RematchEvent", _on_rematch)

func _on_rematch(_event: Event) -> void:
    reset_board()
```

### Pattern 4: GUIDE Context Per Panel (D-06)

**What:** Each panel creates a GUIDEMappingContext in `_on_open()` and disables it in `_on_close()`.

**When to use:** Panels needing input (MainMenu buttons use Godot signals, but PauseMenu needs Esc key, Settings needs nothing special).

**Example:**
```gdscript
# scripts/panels/pause_menu.gd
extends UIPanel

var _pause_context: GUIDEMappingContext

func _on_open(_data: Dictionary = {}) -> void:
    _pause_context = GUIDEMappingContext.new()
    _pause_context.display_name = "pause_menu"
    # Bind Esc to resume
    var resume_action: GUIDEAction = load("res://resources/actions/place_mark.tres")
    var mapping := GUIDEActionMapping.new()
    mapping.action = resume_action
    mapping.input_mappings.append(_make_input_mapping(
        _make_key(KEY_ESCAPE), [], [GUIDETriggerPressed.new()]))
    _pause_context.mappings.append(mapping)
    GUIDE.enable_mapping_context(_pause_context, false, 0)
    resume_action.just_triggered.connect(_on_resume_game)

func _on_close() -> void:
    GUIDE.disable_mapping_context(_pause_context)

func _on_resume_game() -> void:
    UIManager.back(UILayer.POPUP)
```

### Pattern 5: Place Mark Animation via Tween

**What:** On CellPlacedEvent, Cell tweens its Sprite2D.scale from 0 to 1.2 to 1.0 with bounce easing.

**When to use:** Placement animation on cells.

**Example:**
```gdscript
# scripts/cell.gd (modified)
var _tween: Tween

func _on_cell_placed(event: Event) -> void:
    if "cell_index" in event:
        var cell_idx: int = event.get("cell_index")
        if cell_idx == cell_index:
            refresh()
            _play_place_animation()

func _play_place_animation() -> void:
    if _tween:
        _tween.kill()
    _tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BOUNCE)
    sprite.scale = Vector2(0, 0)
    _tween.tween_property(sprite, "scale", Vector2(1.2, 1.2), 0.15)
    _tween.tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.1)
```

### Pattern 6: Win Line + Cell Highlight Animation

**What:** On GameWonEvent, Board draws a Line2D across winning cells with Tween width animation, then pulses winning cells' highlight sprites.

**When to use:** Win/draw visual feedback.

**Example:**
```gdscript
# scripts/board.gd
func _on_game_won(event: Event) -> void:
    var winner: int = event.get("winner")
    var win_line := _get_win_line_indices(GameManager.WIN_LINES)
    if win_line:
        _animate_win_line(win_line)
        _animate_winning_cells(win_line)

func _animate_win_line(win_line_indices: Array) -> void:
    var line := Line2D.new()
    line.default_color = Color(0.91, 0.72, 0.29, 1)  # accent
    line.width = 0
    # Calculate line points from cell positions...
    add_child(line)
    var tween: Tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SPRING)
    tween.tween_property(line, "width", 6.0, 0.3)
    # Also tween alpha from 0 to 1
    line.default_color.a = 0
    var alpha_tween: Tween = create_tween()
    alpha_tween.tween_property(line, "default_color:a", 1.0, 0.3)
```

### Pattern 7: Button Micro-interaction Helper (CQ-03)

**What:** Shared helper for hover scale+modulate and press scale animations.

**When to use:** All buttons across all panels.

**Example:**
```gdscript
# scripts/utils/ui_helpers.gd
static func setup_button_animation(button: Button) -> void:
    button.mouse_entered.connect(_on_button_hover.bind(button))
    button.mouse_exited.connect(_on_button_hover_end.bind(button))
    button.button_down.connect(_on_button_press.bind(button))
    button.button_up.connect(_on_button_release.bind(button))

static func _on_button_hover(btn: Button) -> void:
    var t := btn.create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
    t.set_parallel(true)
    t.tween_property(btn, "scale", Vector2(1.05, 1.05), 0.1)
    t.tween_property(btn, "modulate", Color(1.15, 1.15, 1.15, 1), 0.1)

static func _on_button_hover_end(btn: Button) -> void:
    var t := btn.create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
    t.set_parallel(true)
    t.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.1)
    t.tween_property(btn, "modulate", Color(1.0, 1.0, 1.0, 1), 0.1)

static func _on_button_press(btn: Button) -> void:
    var t := btn.create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
    t.tween_property(btn, "scale", Vector2(0.95, 0.95), 0.1)

static func _on_button_release(btn: Button) -> void:
    var t := btn.create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
    t.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.1)
```

### Pattern 8: Scene Transition (Fade)

**What:** Full-screen ColorRect on the system-level CanvasLayer; Tween modulate.a 0<->1.

**When to use:** Menu <-> Gameplay transitions.

**Example:**
```gdscript
# In main.gd (or a dedicated transition controller)
@onready var transition_overlay: ColorRect = $CanvasLayer/TransitionOverlay

func _fade_to_scene(callback: Callable) -> void:
    transition_overlay.visible = true
    transition_overlay.modulate.a = 0
    var tween: Tween = create_tween()
    tween.tween_property(transition_overlay, "modulate:a", 1.0, 0.3)
    tween.tween_callback(callback)
    # After scene change, call _fade_in()

func _fade_in() -> void:
    var tween: Tween = create_tween()
    tween.tween_property(transition_overlay, "modulate:a", 0.0, 0.3)
    tween.tween_callback(func(): transition_overlay.visible = false)
```

### Pattern 9: Pause Music Volume (D-23)

**What:** On PauseMenu open, reduce music volume to 50% if current > 0.1. Restore on resume.

**When to use:** Pause lifecycle.

**Example:**
```gdscript
# scripts/panels/pause_menu.gd
var _prev_music_volume: float = 0.0

func _on_open(_data: Dictionary = {}) -> void:
    _prev_music_volume = SoundManager.get_music_volume()
    if _prev_music_volume > 0.1:
        SoundManager.set_music_volume(_prev_music_volume * 0.5)

func _on_close() -> void:
    if _prev_music_volume > 0.1:
        SoundManager.set_music_volume(_prev_music_volume)
```

### Anti-Patterns to Avoid

- **Calling GameManager directly from panels:** D-05 explicitly forbids this. Panels publish events; GameManager responds.
- **Managing GUIDE context in main.gd for panels:** D-06 moves per-panel input to each panel's lifecycle. Gameplay context goes to Board scene.
- **Duplicating button animation code:** Must use the shared `ui_helpers.gd` helper (CQ-03).
- **Modifying UIManager or UIPanel:** These are project-owned but are framework infrastructure. Do not modify them -- extend UIPanel via subclassing only.
- **Creating new GUIDEAction resources for panel-specific inputs:** Reuse existing actions (place_mark.tres for Esc/Pause) where possible.
- **Using AnimationPlayer for micro-animations:** Tween is lighter and better for property-based animations under 0.5s.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Panel stack management | Manual visibility toggling (`_show_only`) | UIManager.open_panel/back/close_all | Built-in pause/resume lifecycle, LRU caching, auto-dimmer for POPUP, loop protection |
| Background dimmer | Custom ColorRect overlay per panel | UIManager auto-creates dimmer for each layer | Already implemented -- ColorRect with PRESET_FULL_RECT, mouse_filter STOP, placed below stack |
| Music crossfade | Manual volume ramp via AudioStreamPlayer | SoundManager.play_music(resource, crossfade_duration) | music.gd has built-in fade_volume via Tween; handles fade out old + fade in new |
| Button animation system | Custom input event handling per button | Godot Button signals (mouse_entered/exited, button_down/up) + Tween | Simple, standard, well-documented; extract to shared helper |
| Animation timing/chaining | Manual _process delta accumulation | Tween chaining (tween_property + tween_callback + set_parallel) | Godot 4.6 Tween handles all timing, easing, parallel execution |

**Key insight:** The mc_game_framework UIManager covers 80% of the panel management complexity (stack, lifecycle, caching, dimming). SoundManager's music player handles 100% of crossfade complexity. Do not re-implement any of this infrastructure.

## Common Pitfalls

### Pitfall 1: Panel Registration Order and UIRegistry Timing
**What goes wrong:** `UIManager.open_panel()` fails silently because UIRegistry is not registered yet.
**Why it happens:** UIManager calls `_get_ui_registry()` which checks `RegistryManager.has_registry("ui")`. If `RegistryManager.register_registry("ui", UIRegistry.new())` has not been called, UIManager returns null with error.
**How to avoid:** Register UIRegistry in `main.gd _ready()` before any `open_panel()` call. The initial MainMenu open should be in `_ready()` after registration.
**Warning signs:** Error output "UIRegistry 未注册" in the debug console.

### Pitfall 2: ResourceLocation Format Errors
**What goes wrong:** `ResourceLocation.from_string()` returns null, causing panel open to fail.
**Why it happens:** ResourceLocation requires exactly one colon separator: `namespace:path`. Missing colon, extra colons, or empty namespace/path cause errors.
**How to avoid:** Always use format `tic_tac_toe:main_menu` (lowercase, single colon). Verify string before passing to `from_string()`.
**Warning signs:** Error output "Invalid ResourceLocation format" or null return values.

### Pitfall 3: Tween Lifecycle Overlap
**What goes wrong:** Multiple tweens running on the same property simultaneously cause visual glitches.
**Why it happens:** If a new animation starts before the previous one finishes (e.g., rapid cell placement during AI thinking), both tweens fight for the same property.
**How to avoid:** Always kill previous tween before starting new one: `if _tween: _tween.kill(); _tween = create_tween()`.
**Warning signs:** Sprite flickering, properties jumping to unexpected values.

### Pitfall 4: Panel Lifecycle Duplicates (EventBus Subscriptions)
**What goes wrong:** Panel subscribes to EventBus in `_on_open()` but never unsubscribes, causing duplicate handlers when the panel is reopened.
**Why it happens:** UIPanel with `CacheMode.CACHE` persists between opens; subscriptions from the first open remain active.
**How to avoid:** Subscribe in `_on_init()` (once) or use `CONNECT_ONE_SHOT`. Better: subscribe in `_on_init()` for permanent bindings, unsubscribe in `_on_destroy()`.

### Pitfall 5: Music Crossfade Bus Volume vs. Track Volume Confusion
**What goes wrong:** Setting music bus volume (via `SoundManager.set_music_volume()`) while a crossfade tween is running on individual AudioStreamPlayer volume_db causes conflicting volume changes.
**Why it happens:** `set_music_volume()` sets AudioServer bus volume, while crossfade tweens individual player `volume_db`. Both affect perceived loudness.
**How to avoid:** Use bus volume for user-visible settings, track-level volume only for crossfade transitions. Do not set bus volume during crossfade. D-22 specifies crossfade 1.0-1.5s on `play_music()` which operates on track-level.

### Pitfall 6: CanvasLayer Layer Order for Transitions
**What goes wrong:** Scene transition ColorRect renders behind panels, not covering them.
**Why it happens:** The transition ColorRect is on a CanvasLayer with lower layer value than the panel CanvasLayers.
**How to avoid:** Place the transition ColorRect on a CanvasLayer with `layer >= 400` (UILayer.SYSTEM). Verify it's a child of the root scene or a dedicated CanvasLayer with sufficient layer value.
**Warning signs:** Fade transition is visible behind panels.

### Pitfall 7: TabContainer Theme Overrides Not Applying
**What goes wrong:** TabBar tabs don't show the accent underline for selected tab despite setting border_width.bottom.
**Why it happens:** TabContainer's TabBar is an internal child; theme overrides on the TabContainer may not propagate to the TabBar correctly.
**How to avoid:** Apply theme overrides directly on the TabBar node (`$TabContainer/TabBar`) or set `theme_override_styles/tab_selected` on the TabContainer with a custom StyleBoxFlat.

### Pitfall 8: GUIDE Context Priority Conflicts
**What goes wrong:** Esc key opens PauseMenu but also triggers Board's place_mark action when PauseMenu is open.
**Why it happens:** GUIDE contexts have priorities. If the PauseMenu context has lower priority than the gameplay context, both receive input.
**How to avoid:** Disable the gameplay GUIDE context when PauseMenu opens. Board scene should disable/enable its context on GameStartedEvent and PauseMenu open/close events.

## Code Examples

Verified patterns from official sources (mc_game_framework source code, Godot 4.6 documentation):

### UIManager Panel Lifecycle (from mc_game_framework source)
```gdscript
# addons/mc_game_framework/autoload/ui_manager.gd:58-129
# open_panel(id: ResourceLocation, data: Dictionary = {}, layer_override: int = -1) -> UIPanel
# 1. Gets panel from cache or instantiates via UIRegistry
# 2. Pauses current stack top (calls _on_pause(), hides)
# 3. Pushes new panel, adds to scene tree
# 4. Shows background dimmer for NORMAL+
# 5. Calls _on_open(data), publishes UIOpenEvent
```

### UIPanel Base Class (from mc_game_framework source)
```gdscript
# addons/mc_game_framework/ui/ui_panel.gd:1-46
# class_name UIPanel extends Control
# Properties: panel_id (ResourceLocation), ui_layer (int), cache_mode (int)
# CacheMode: NONE=0, CACHE=1
# Lifecycle: _on_init() -> _on_open(data) -> _on_pause() -> _on_resume() -> _on_close() -> _on_destroy()
```

### SoundManager.play_music with Crossfade (from sound_manager source)
```gdscript
# addons/sound_manager/music.gd:7-27
func play(resource: AudioStream, position: float = 0.0, volume: float = 0.0,
          crossfade_duration: float = 0.0, override_bus: String = "") -> AudioStreamPlayer:
    stop(crossfade_duration * 2)  # Fade out existing tracks
    var player = prepare(resource, override_bus)
    fade_volume(player, -80.0, volume, crossfade_duration)  # Fade in new track
    player.call_deferred("play", position)
    return player

# Usage in AudioController:
SoundManager.play_music(music_stream, 1.5)  # 1.5s crossfade
```

### SoundManager Music Volume Control (from sound_manager source)
```gdscript
# addons/sound_manager/sound_manager.gd:141-148
func get_music_volume() -> float:
    return db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index(music.bus)))

func set_music_volume(volume_between_0_and_1: float) -> void:
    AudioServer.set_bus_volume_db(AudioServer.get_bus_index(music.bus), linear_to_db(volume_between_0_and_1))
```

### Event class and EventBus publish (from event.gd and game_manager.gd)
```gdscript
# Events use class_name for type resolution via Event.get_event_type()
# EventBus.subscribe(&"GameWonEvent", callback)
# EventBus.publish(GameWonEvent.new(winner))
```

### SettingsManager API (from autoload/settings_manager.gd)
```gdscript
# get_value(key: String, default: Variant = null) -> Variant
# set_value(key: String, value: Variant) -> void  # Publishes SettingChangedEvent
# Keys: "audio/sfx_volume", "audio/music_volume", "gameplay/difficulty", "language/locale"
# Save triggered on NOTIFICATION_WM_CLOSE_REQUEST
```

### I18NManager API (from mc_game_framework source)
```gdscript
# I18NManager.load_translation(lang_code, file_path) -> bool
# I18NManager.set_language(lang_code)  # Publishes LanguageChangedEvent
# I18NManager.get_current_language() -> String
# All text uses tr("key") or tr("key").format([args])
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `main.gd:_show_only()` visibility toggling | UIManager stack-based panel management | Phase 1 | Adds panel lifecycle (pause/resume), auto-dimming, LRU caching, stack navigation pattern |
| All panels in one main.tscn | Independent panel scenes extending UIPanel | Phase 1 | Each panel self-contained; new panels don't require modifying main.tscn |
| Board inline in main.tscn | Independent board.tscn scene | Phase 1 | Board reusable, removable without affecting UI layer; GUIDE context self-contained |
| One music track (off_to_osaka.mp3) | Two tracks with crossfade switching | Phase 1 | Scene-aware music (menu vs gameplay); crossfade via SoundManager built-in API |
| zh_CN + en_US localization | zh_CN + en_US + ja_JP | Phase 1 | Third language; extensible pattern for future locales |
| GameManager direct calls from UI | EventBus-mediated communication (D-05) | Phase 1 | Decouples UI from game logic; panels are pure views |
| Buttons without visual feedback | Hover scale+modulate + press scale (0.1s Tween) | Phase 1 | Tactile feedback consistent across all panels |

**Deprecated/outdated:**
- `_show_only()` and the entire manual visibility toggle pattern -- replace all with UIManager
- Main scene containing both UI and Board -- split into independent panels + board.tscn
- Single music track -- must support menu/gameplay switching
- Direct GameManager calls from UI code -- panels must use EventBus

## Assumptions Log

No claims tagged `[ASSUMED]` in this research -- all findings are verified against codebase source files (mc_game_framework, SoundManager, Godot built-in) or documented in the UI-SPEC and CONTEXT.md.

## Open Questions

1. **Transition ColorRect CanvasLayer layer value**
   - What we know: Must be above all UI layers. UILayer.SYSTEM = 400.
   - What's unclear: Whether to put it on the root node's own CanvasLayer (layer 0 by default) or a dedicated CanvasLayer with layer 400.
   - Recommendation: Use a dedicated CanvasLayer with `layer = 500` (above SYSTEM) to guarantee it renders on top of everything. Place it in `main.tscn` as a child of the root Node2D.

2. **GUIDE context priority for PauseMenu Esc key vs Board gameplay**
   - What we know: Board scene manages gameplay context. PauseMenu needs Esc.
   - What's unclear: Whether GUIDE context priorities can be used to block lowercase input, or if Board must explicitly disable its context when PauseMenu opens.
   - Recommendation: Board disables its gameplay context on PauseMenu open event and re-enables on close. Simplest reliable approach.

3. **Line2D for win line positioning**
   - What we know: Winning cells are at known grid positions (160, 360, 560 on both axes).
   - What's unclear: Whether to add the win line Line2D as a child of Board (world-space coordinates) or as a separate node.
   - Recommendation: Child of Board, same coordinate space as cells and grid lines. Calculate start/end points from cell positions. Line2D should NOT be in grid_lines group.

4. **RematchEvent subscription in GameManager**
   - What we know: D-05 says panels publish events, GameManager subscribes.
   - What's unclear: RematchEvent needs a new GameManager subscriber. Does GameManager need to unsubscribe on state change?
   - Recommendation: Subscribe in `_ready()`, unsubscribe in `_exit_tree()` (though GameManager is an autoload and never exits). Single subscription is fine.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Godot Engine | All code | (editor) | 4.6 | -- |
| mc_game_framework | UIManager, UIPanel, UIRegistry, I18NManager | (plugin) | 0.0 | -- |
| GUIDE | Per-panel input contexts, gameplay input | (plugin) | 0.13.0 | -- |
| SoundManager | Music crossfade, volume control | (plugin) | 2.6.1 | -- |
| GUT | Tests | (plugin) | 9.6.0 | Manual verification |
| MiSans-Semibold font | All UI text | (file) | -- | -- |
| off_to_osaka.mp3 | Menu music | (file) | -- | -- |
| breaktime.mp3 | Gameplay music | (file) | -- | -- |

**Missing dependencies with no fallback:** None.

**Missing dependencies with fallback:** None.

## Validation Architecture

Skipped per config.json: `workflow.nyquist_validation: false`.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | No | Local single-player game, no user accounts |
| V3 Session Management | No | No sessions; game state is in-memory SSOT |
| V4 Access Control | No | No multi-user or admin features |
| V5 Input Validation | Partial | GameManager guard clauses already validate cell_index (0-8), direction bounds, state checks. CQ-02 adds `push_warning` but does not change validation logic. No new user-facing text input in Phase 1. |
| V6 Cryptography | No | No data transmitted or stored with sensitivity requirements |
| V7 File Upload | No | No file upload functionality |
| V8 Anti-Automation | No | Local game, no automation concerns |

### Known Threat Patterns

No new threat patterns introduced in Phase 1. All animation and UI code runs client-side only with no network access. The most relevant risk is **user interface state confusion** (unintended panel navigation through rapid input), mitigated by UIManager's MAX_OPEN_DEPTH protection (8 nested open calls) and existing state guards in GameManager.

## Sources

### Primary (HIGH confidence)
- `addons/mc_game_framework/autoload/ui_manager.gd` -- UIManager API: open_panel, back, close_panel, close_all, dimmer management, LRU caching, registry lookup
- `addons/mc_game_framework/ui/ui_panel.gd` -- UIPanel base class: panel_id, ui_layer, cache_mode, all lifecycle hooks
- `addons/mc_game_framework/ui/ui_layer.gd` -- Layer constants: SCENE(0), NORMAL(100), POPUP(200), TOAST(300), SYSTEM(400)
- `addons/mc_game_framework/registry/ui_registry.gd` -- UIRegistry: register_panel, instantiate_panel registration pattern
- `addons/mc_game_framework/utils/resource_location.gd` -- ResourceLocation format: `namespace:path`, from_string() parser
- `addons/mc_game_framework/autoload/i18n_manager.gd` -- I18NManager: load_translation, set_language, get_current_language
- `addons/mc_game_framework/event/event.gd` -- Event base class: cancel, is_cancelled, get_event_type via class_name
- `addons/mc_game_framework/event/language_changed_event.gd` -- LanguageChangedEvent with lang_code field
- `addons/sound_manager/sound_manager.gd` -- SoundManager: play_music(crossfade_duration), set_music_volume, get_music_volume, all SFX APIs
- `addons/sound_manager/music.gd` -- Music player: play() with crossfade, stop(fade_out), fade_volume tween
- `addons/sound_manager/abstract_audio_player_pool.gd` -- Audio pool: fade_volume implementation with Tween
- `autoload/audio_controller.gd` -- Current music switching pattern via SoundRegistry + SoundManager
- `autoload/game_manager.gd` -- GameManager SSOT: all public methods, event publishing, CQ-02 injection points
- `autoload/settings_manager.gd` -- SettingsManager: get_value, set_value, save on close, ConfigFile persistence
- `scripts/main.gd` -- Current UI management pattern being replaced: _show_only, GUIDE setup, button callbacks, EventBus subscriptions
- `scripts/cell.gd` -- Cell structure: Sprite2D, highlight, current refresh/input pattern, animation injection points
- `scenes/main.tscn` -- Current scene hierarchy: panels inline, Board with 9 instanced cells
- `resources/theme/default_theme.tres` -- MiSans-Semibold default_font, default_font_size=20
- `.planning/phases/01-ui-animations/01-CONTEXT.md` -- All 27 locked decisions D-01 through D-27
- `.planning/phases/01-ui-animations/01-UI-SPEC.md` -- Full design tokens: spacing, typography, color, animation specs, panel registry, copywriting
- `.planning/REQUIREMENTS.md` -- UI-01 through UI-05, ANM-01 through ANM-04, CQ-02, CQ-03 requirement definitions
- `.planning/codebase/ARCHITECTURE.md` -- Autoload chain, data flow, event system, scene tree structure
- `.planning/codebase/STRUCTURE.md` -- Directory layout, naming conventions, file locations

### Secondary (MEDIUM confidence)
- Godot 4.6 documentation -- Tween API (create_tween, tween_property, set_ease, set_trans, set_parallel, chaining), Control layout (VBoxContainer, HBoxContainer, anchors), Theme override system
- Godot 4.6 documentation -- ColorRect, TabContainer, HSlider, OptionButton, Line2D, StyleBoxFlat, CanvasLayer layer ordering

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- All components verified against mc_game_framework source code, SoundManager source, and Godot 4.6 engine APIs
- Architecture: HIGH -- All patterns verified against existing codebase patterns (EventBus, GUIDE, autoload singletons) and UIManager API
- Pitfalls: HIGH -- All drawn from source code analysis (UIManager null returns on missing registry, ResourceLocation format constraints, Tween lifecycle best practices)

**Research date:** 2026-06-17
**Valid until:** 2026-07-17 (30 days -- Godot 4.6 stable, mc_game_framework and SoundManager stable)
