# Stack Research

**Domain:** Godot 4.6 Tic-Tac-Toe game polish (audio, UI, animation, AI, localization, code quality)
**Researched:** 2026-06-17
**Confidence:** HIGH

## Recommended Stack

### Core Technologies

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| Godot Engine | 4.6 | Game engine + rendering | Already the project runtime. Forward Plus renderer supports 2D canvas rendering. 720x720 viewport with `canvas_items` stretch mode is correct and unchanged. |
| GDScript | 2.0 (Godot 4.x) | All game logic | Already the project language. Constraint: no C# new code. GDScript 2.0 has typed arrays, lambdas, `@onready` vars, and `await` which the polish work will leverage. |
| SoundManager (nathanhoad) | 2.6.1 | Audio playback with channel pooling | Already registered as autoload singleton. 4 channels (SFX, UI SFX, ambient, music) with auto-pooling, built-in fade/crossfade, and volume control via AudioServer bus. A community standard for Godot audio. |
| mc_game_framework UIManager | 0.0 | Stack-based UI panel management | Already registered. Provides CanvasLayer-based panel stacks per UILayer (SCENE/NORMAL/POPUP/TOAST/SYSTEM), lifecycle callbacks, background dimmer, Toast system, popup queue, and LRU caching. Replaces direct visibility toggling in `main.gd`. |
| mc_game_framework I18NManager | 0.0 | JSON-based translation loading + language switching | Already registered. Loads flattened JSON into TranslationServer, supports runtime locale switching, publishes `LanguageChangedEvent` for reactive UI updates. Eliminates manual `tr()` management. |
| GUIDE (G.U.I.D.E) | 0.13.0 | Context-based input system | Already fully integrated. All game input routes through GUIDE action mappings. No changes needed to input handling layer — only UI buttons will use Godot's built-in `pressed` signals since they are not gameplay actions. |
| GUT | 9.6.0 | Unit testing framework | Already installed. Provides assert library, test runner, doubles/mocking for GDScript. Required for code quality improvements (error handling, refactoring). |

### Supporting Libraries / Addon Capabilities

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| SoundManager `play_sound()` | 2.6.1 | One-shot SFX on sound_effects channel | In-game sounds (piece placement, win jingle, draw sound). Uses pool size 8, PROCESS_MODE_PAUSABLE — pauses when game scene pauses. |
| SoundManager `play_ui_sound()` | 2.6.1 | One-shot SFX on ui_sound_effects channel | UI interactions (button hover, button click, panel open/close). Pool size 8, PROCESS_MODE_ALWAYS — plays even when game is paused. |
| SoundManager `play_music()` | 2.6.1 | Background music with crossfade | Menu music, gameplay music. Crossfade_duration parameter enables smooth transitions (0.5-1.0s recommended). Pool size 2, PROCESS_MODE_ALWAYS. |
| SoundManager `set_sound_volume()` / `set_music_volume()` | 2.6.1 | Independent volume control | Settings panel sliders. Accepts 0.0-1.0 float, maps to AudioServer bus volume in dB. |
| UIManager `open_panel()` | 0.0 | Push panel onto stack | Opening main menu, settings, game-over screen. Uses ResourceLocation (namespace:path) for panel identity. Returns UIPanel instance. |
| UIManager `back()` | 0.0 | Pop top panel from stack | Back button / ESC key behavior. Restores previous panel via `_on_resume()` lifecycle. |
| UIManager `add_overlay()` | 0.0 | Persistent non-stack UI | HUD elements (score display, turn indicator) that should persist across panel changes. |
| UIManager `show_toast()` | 0.0 | Auto-dismiss notification | Brief messages (e.g., "Language switched to English"). Auto-dismisses after configurable duration. |
| I18NManager `load_translation()` | 0.0 | Load JSON translation file | Loading `en.json` and `zh.json` at startup. Flattens nested JSON into TranslationServer messages. |
| I18NManager `set_language()` | 0.0 | Switch runtime language | Settings panel language toggle. Calls `TranslationServer.set_locale()` + publishes LanguageChangedEvent for reactive UI updates. |
| I18NManager `get_text()` | 0.0 | Fetch translated string with formatting | Alternative to `tr()` that supports `{0}`, `{1}` placeholder substitution via String.format(). |
| Godot Tween (`create_tween()`) | 4.6 | Lightweight code-driven value interpolation | All runtime animations: piece placement animation, win-line highlight fade-in, scene transition fades, button hover scale, popup slide-in. |
| Godot AnimationPlayer | 4.6 | Pre-authored multi-track animation | Only if complex authored sequences are needed (not needed for this project — Tween covers all cases). |
| Godot ResourceLocation (mc_game_framework) | 0.0 | Namespace:path panel/resource identity | Replacing hardcoded script paths in EventBus with `tictactoe:events/cell_placed` style identifiers. |
| Godot UIRegistry (mc_game_framework) | 0.0 | Panel scene registration | Register all UI panel scenes with ResourceLocation IDs so UIManager can instantiate them by name. |

### Development Tools

| Tool | Purpose | Notes |
|------|---------|-------|
| GUT v9.6.0 | Unit testing game logic | Create `tests/` directory, write `.gutconfig.json` or `.gutconfig` to configure. Focus on `game_manager.gd` logic (Minimax, win detection, state transitions). |
| Godot Editor | Scene editing, animation preview | All UI panels are authored as `.tscn` files extending `UIPanel`. Animation preview with Tween is code-only (no visual editor needed). |
| JSON editor | Translation file authoring | Translation files are plain JSON. No PO/CSV toolchain needed since I18NManager loads JSON natively. |

## Installation

No package manager. All dependencies are vendored under `addons/` and already installed.

```bash
# Verify addon structure exists:
ls addons/sound_manager/       # Should show sound_manager.gd etc.
ls addons/mc_game_framework/   # Should show autoload/ ui/ event/ etc.
ls addons/kenney_interface_sounds/  # Should show 99+ WAV files
ls addons/gut/                 # Should show GUT plugin
ls addons/guide/               # Should show GUIDE plugin
```

No new addons to install. The constraint states: "use existing addons, do not introduce new plugins."

## Alternatives Considered

| Category | Recommended | Alternative | Why Not |
|----------|-------------|-------------|---------|
| Audio approach | SoundManager v2.6.1 (existing addon) | Manual AudioStreamPlayer2D pooling | SoundManager already provides pooling, fade/crossfade, channel management, and volume control. Writing equivalent code would duplicate existing functionality and violate the "use existing addons" constraint. |
| UI approach | UIManager (existing addon) | Manual Control visibility toggling | Current `_show_only()` pattern in `main.gd` tightly couples scene structure to navigation logic. UIManager provides proper stack semantics, lifecycle hooks, CanvasLayer isolation, and is already registered but unused. |
| Localization approach | I18NManager (existing addon) | Manual TranslationServer API + CSV files | I18NManager is already loaded, provides JSON support (simpler than CSV for small projects), and auto-publishes LanguageChangedEvent for reactive UI. Using raw TranslationServer would lose the reactive event pattern. |
| Animation for placement | Tween (Godot built-in) | AnimationPlayer | Piece placement animation has dynamic target positions (unknown at edit time). Tween supports runtime-determined end values naturally. AnimationPlayer would require pre-authored tracks for every cell — impractical for a 3x3 grid. |
| Animation for win-line | Tween (Godot built-in) | AnimationPlayer | The winning cells are determined at runtime. Tween lets you animate only the winning 3 cells with a simple loop. AnimationPlayer requires pre-authoring all 8 win-line combinations. |
| Animation for UI transitions | Tween (Godot built-in) | AnimationPlayer | Scene fades and panel slides are simple one-off property interpolations. Tween's fire-and-forget model is lighter. AnimationPlayer is overkill. |
| AI difficulty | Depth-limited Minimax (enhance existing) | Pure random + optimal (binary) | Three difficulty levels: Easy (random with block), Medium (depth-limited to 2), Hard (full Minimax). This gives a smooth progression curve. Pure random is too easy; optimal-only is too hard. |
| Event type identification | ResourceLocation (namespace:path) | Script resource paths | Current `"res://scripts/events/cell_placed_event.gd"` strings are brittle and break when files move. ResourceLocation (`tictactoe:events/cell_placed`) is clean, validated, and the mc_game_framework ecosystem uses this pattern. |

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| Reusing Tween objects | Godot 4 docs warn: reusing a single Tween instance causes undefined behavior. Each animation must create a fresh `create_tween()`. | `var t = create_tween()` per animation sequence. Kill previous with `if t and t.is_valid(): t.kill()`. |
| `_process()` Tween creation | Creating Tweens every frame in `_process()` is a documented anti-pattern. | Create Tweens only on demand (button press, game event). For continuous following use `lerp()` or `move_toward()`. |
| AnimationPlayer for runtime-determined values | Final values unknown at edit time (winning cells, piece positions from clicks) cannot use pre-authored animation tracks. | Tween can interpolate to any runtime value. For 3-cell win-line highlight, use a loop calling `tween_property()` per cell. |
| Raw `tr()` without reactive pattern | `tr()` returns current translation at call time but does not auto-update. UI labels would show old strings after language switch. | Use I18NManager's LanguageChangedEvent to trigger label text refreshes. Or use `I18NManager.get_text()` in event handlers. |
| Manual AudioStreamPlayer2D instantiation | Creating/destroying players per sound duplicates SoundManager's pool-based approach already in the project. | SoundManager manages a pool of 8 AudioStreamPlayers per channel, auto-reclaims finished ones. Use `SoundManager.play_sound()` / `play_ui_sound()`. |
| Direct Control visibility manipulation | Current `_show_only()` bypasses UIManager's lifecycle (`_on_open`, `_on_pause`, `_on_resume`, `_on_close`) and CanvasLayer isolation. | Move each UI section to its own UIPanel scene. Use `UIManager.open_panel()` / `back()` for navigation. HUD elements use `add_overlay()`. |
| Hardcoded event script paths | `EventBus.subscribe("res://scripts/events/...gd", callback)` breaks when files are moved or renamed. | Add `class_name` to event scripts, then use `StringName("CellPlacedEvent")` as event type. Or use ResourceLocation. |
| Testing without GUT | `print()` debugging for game logic is slow and unreliable. GUT is installed but unused. | Write GUT tests for: Minimax AI, win detection, state transitions, board validation. Use `assert_eq`, `assert_true`, `assert_has_signal`. |

## Stack Patterns by Variant

**For Audio integration:**
- Map Kenney sounds to game events in a dedicated `SoundController.gd` (or `AudioController.gd`) autoload or scene singleton
- Pattern: subscribe to EventBus events → map to SoundManager calls
  - `cell_placed_event` → `SoundManager.play_sound(preload("res://addons/kenney_interface_sounds/click_002.wav"))`
  - `game_won_event` → `SoundManager.play_sound(preload("res://addons/kenney_interface_sounds/confirmation_001.wav"))`
  - `game_draw_event` → `SoundManager.play_sound(preload("res://addons/kenney_interface_sounds/toggle_003.wav"))`
  - `game_started_event` → `SoundManager.play_ui_sound(preload("res://addons/kenney_interface_sounds/select_001.wav"))`
  - Button hover → `SoundManager.play_ui_sound(preload("res://addons/kenney_interface_sounds/tick_001.wav"))`
  - Panel open → `SoundManager.play_ui_sound(preload("res://addons/kenney_interface_sounds/open_001.wav"))`
  - Menu music → `SoundManager.play_music(preload("res://assets/music/menu.ogg"), 1.0)`
- Use `ui_sound_effects` channel for all UI interactions (buttons, panels) — PROCESS_MODE_ALWAYS ensures they play during scene pauses
- Use `sound_effects` channel for in-game sounds (placement, win/draw) — PROCESS_MODE_PAUSABLE stops them when the game is not active
- Volume controls: settings panel sliders call `SoundManager.set_sound_volume(value)` and `SoundManager.set_music_volume(value)` directly

**For UIManager integration:**
- Create UIRegistry and register it globally once at project startup:
  ```gdscript
  var ui_reg := UIRegistry.new()
  ui_reg.register_panel(ResourceLocation.from_string("tictactoe:main_menu"), preload("res://scenes/ui/main_menu.tscn"))
  ui_reg.register_panel(ResourceLocation.from_string("tictactoe:settings"), preload("res://scenes/ui/settings.tscn"))
  ui_reg.register_panel(ResourceLocation.from_string("tictactoe:game_over"), preload("res://scenes/ui/game_over.tscn"))
  RegistryManager.register_registry("ui", ui_reg)
  ```
- Each UI screen becomes a separate scene with root extending `UIPanel`
- Current `main.gd`'s UI visibility logic moves into UIPanel subclasses
- HUD elements (score, turn indicator) register as overlays via `UIManager.add_overlay()`
- Game over panel uses `open_panel()` with data dict containing result info
- Settings panel uses `open_panel()` on POPUP or NORMAL layer depending on design
- Back navigation: `UIManager.back()` on ESC or back button
- The `main.gd` scene root stays as the game board + input handler; it delegates UI management to UIManager

**For Animation patterns:**
- Piece placement: Tween piece sprite scale from 0 to 1 with `TRANS_BOUNCE` `EASE_OUT` over 0.3s
  ```gdscript
  var tween = create_tween()
  tween.tween_property(piece, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
  ```
- Win-line highlight: Tween modulate alpha of winning cells from 0 to 1 with `TRANS_SINE` `EASE_OUT`, staggered 0.1s apart
  ```gdscript
  for i in win_cells.size():
      tween.tween_property(cells[win_cells[i]], "modulate", highlight_color, 0.2).set_delay(i * 0.1)
  ```
- Scene transition: Tween modulate of transition ColorRect alpha 0→1→0
  ```gdscript
  # Fade out
  var tween = create_tween()
  tween.tween_property(transition_rect, "color:a", 1.0, 0.3)
  await tween.finished
  # Do scene work
  # Fade in
  tween = create_tween()
  tween.tween_property(transition_rect, "color:a", 0.0, 0.3)
  ```
- Button hover: Tween modulate or scale on mouse enter/exit
  ```gdscript
  func _on_mouse_entered():
      create_tween().tween_property(self, "scale", Vector2(1.1, 1.1), 0.1)
  func _on_mouse_exited():
      create_tween().tween_property(self, "scale", Vector2.ONE, 0.1)
  ```
- **CRITICAL**: Always kill previous Tweens targeting the same property:
  ```gdscript
  var _piece_tween: Tween
  func animate_piece(piece, to_scale):
      if _piece_tween and _piece_tween.is_valid(): _piece_tween.kill()
      _piece_tween = create_tween()
      _piece_tween.tween_property(piece, "scale", to_scale, 0.3)
  ```

**For AI difficulty levels:**
- **Easy**: 30% chance random move, 70% chance use Minimax depth-limited to 1 (only immediate wins/blocks)
- **Medium**: Minimax depth-limited to 2 (looks ahead 2 half-moves)
- **Hard**: Full Minimax with alpha-beta pruning (optimal play, 9! = 362,880 max positions, trivially fast for tic-tac-toe)
- Structure as an enum in GameManager:
  ```gdscript
  enum AIDifficulty { EASY, MEDIUM, HARD }
  ```
- `_find_best_move()` becomes:
  ```gdscript
  func _find_best_move() -> int:
      match ai_difficulty:
          AIDifficulty.EASY:
              if randf() < 0.3:
                  return _random_move()
              return _minimax_best(1)
          AIDifficulty.MEDIUM:
              return _minimax_best(2)
          AIDifficulty.HARD:
              return _minimax_best(999)  # effectively full search
  ```
- The existing alpha-beta pruning in `_minimax()` should be enhanced with explicit alpha/beta parameters (currently missing — the implementation only uses `is_maximizing` and `depth`, not actual alpha-beta bounds)

**For I18N integration:**
- Translation file structure:
  ```
  resources/
  └── translations/
      ├── en.json   # English
      └── zh.json   # Chinese
  ```
- JSON format (flat key-value, I18NManager flattens nested):
  ```json
  {
      "menu.title": "Tic-Tac-Toe",
      "menu.pvp": "Two Players",
      "menu.pvai": "vs Computer",
      "game.turn": "Turn: {0}",
      "game.score": "X: {0}  O: {1}  Draw: {2}",
      "result.win": "{0} Wins!",
      "result.draw": "Draw!",
      "settings.title": "Settings",
      "settings.sound": "Sound Volume",
      "settings.music": "Music Volume",
      "settings.language": "Language",
      "settings.ai_difficulty": "AI Difficulty",
      "settings.easy": "Easy",
      "settings.medium": "Medium",
      "settings.hard": "Hard",
      "button.rematch": "Rematch",
      "button.menu": "Main Menu"
  }
  ```
- Load at startup in an autoload `I18NSetup.gd`:
  ```gdscript
  func _ready():
      I18NManager.load_translation("en", "res://resources/translations/en.json")
      I18NManager.load_translation("zh", "res://resources/translations/zh.json")
      # Detect system locale with fallback
      var sys_locale = OS.get_locale()
      I18NManager.set_language("zh" if sys_locale.begins_with("zh") else "en")
  ```
- UI labels subscribe to EventBus for reactive updates:
  ```gdscript
  EventBus.subscribe(…language_changed…, _refresh_text)
  func _on_open(data):
      _refresh_text()
  func _refresh_text():
      text = tr("MENU_TITLE")
  ```

**For EventBus cleanup (hardcoded path fix):**
- Two options, both better than current script-path strings:
  1. **Add `class_name` to event scripts**: Add `class_name CellPlacedEvent` to each event script, then subscribe via `EventBus.subscribe(&"CellPlacedEvent", callback)`. This is clean but requires class_name uniqueness across the project.
  2. **Use StringName constants**: Define a constants file:
     ```gdscript
     # autoload/event_types.gd
     const CELL_PLACED := &"tictactoy:events/cell_placed"
     const GAME_WON := &"tictactoy:events/game_won"
     ```
     Then `EventBus.subscribe(EventTypes.CELL_PLACED, callback)`.
  
  Option 1 (class_name) is recommended because it requires no constants file and leverages Godot's built-in type system. The event scripts already extend `Event` — just add `class_name`.

- **Pitfall avoidance**: After adding `class_name`, verify that `Event.get_event_type()` returns the class name string, not the script path. The current implementation in `event.gd` line 19-22 checks `get_global_name()` first, so class_name takes priority.

## Version Compatibility

| Package A | Compatible With | Notes |
|-----------|-----------------|-------|
| Godot 4.6 | SoundManager 2.6.1 | Verified. SoundManager uses `Engine.register_singleton()` (Godot 4 API), `AudioServer` bus queries, `Tween` (modern binding). No deprecated API usage detected. |
| Godot 4.6 | mc_game_framework 0.0 | Verified. Uses `CanvasLayer`, `Control`, `RefCounted`, `TranslationServer`, `ResourceLocation`. No API issues with 4.6. |
| Godot 4.6 | GUIDE 0.13.0 | Already integrated and working. No version concerns. |
| Godot 4.6 | GUT 9.6.0 | Already installed. GUT 9.x is Godot 4 compatible. |
| Godot 4.6 | kenney_interface_sounds (WAV) | WAV format is natively supported by Godot 4.6 AudioStream. No import issues. |
| SoundManager 2.6.1 `set_sound_volume()` | AudioServer bus config | SoundManager sets volume on the shared bus `Sounds/SFX`. If `set_sound_volume()` and `set_music_volume()` target different buses that share the same parent bus with volume adjustments, there can be unexpected interactions. The built-in `_show_shared_bus_warning()` in SoundManager will warn if music and SFX share the same bus. **Recommendation**: Ensure project.godot Audio bus layout has separate buses for "Sounds" and "Music" with independent volume controls. |
| SoundManager `fade_volume()` | Godot 4 Tween API | SoundManager's internal `fade_volume()` uses `get_tree().create_tween().bind_node(self)`. This is a Godot 4 compatible pattern. No issues. |
| UIManager > UIRegistry > RegistryManager | mc_game_framework autoload chain | UIManager requires UIRegistry to be registered via `RegistryManager.register_registry("ui", ui_reg)`. If this setup is missing, `open_panel()` will push an error. Must be done once at startup. |

## Design Decisions with Rationale

### Why SoundManager's `play_ui_sound()` for buttons instead of `play_sound()`

SoundManager provides two SFX channels: `sound_effects` and `ui_sound_effects`. The key difference is process mode:

- `sound_effects` uses `PROCESS_MODE_PAUSABLE` — paused when SceneTree is paused
- `ui_sound_effects` uses `PROCESS_MODE_ALWAYS` — plays even when paused

Button clicks, panel opens, and other UI sounds should be audible even during transitions or brief pauses. Game events (piece placement, win) should follow game pause state. Use `play_ui_sound()` for UI, `play_sound()` for gameplay.

### Why Tween over AnimationPlayer for all animation in this project

This project needs exactly three types of animation:
1. **Piece placement**: scale from 0 to 1 — target value determined at runtime
2. **Win-line highlight**: modulate alpha for 3 cells — which cells are runtime-determined
3. **UI transitions**: fade in/out of ColorRect — start/end are runtime-determined

AnimationPlayer requires pre-authored keyframes. You cannot know at edit time which 3 cells will form the win line or where the player clicked to place a piece. Tween handles all of these with `<10 lines of code` each. AnimationPlayer would require 8 different win-line animations or complex `AnimationNodeBlendTree` setup — both are over-engineering for tic-tac-toe.

### Why JSON for translations instead of CSV/PO (despite Godot's native CSV support)

The I18NManager addon already supports JSON natively and is registered but unused. Using it means:
- No new addon dependencies
- Automatic TranslationServer registration
- Automatic LanguageChangedEvent publishing for reactive UI
- JSON handles nested key organization (menu.*, game.*, settings.*) which CSV cannot
- PO files require Gettext tooling — unnecessary for two languages and ~20 strings

If the project grows to 5+ languages or needs plural forms, migrating to PO format is straightforward since the TranslationServer API is the same underlying mechanism. But for the current scope, JSON via I18NManager is the pragmatic choice.

### Why the existing Minimax needs restructuring, not replacement

The existing `_minimax()` in `game_manager.gd` has the correct recursive structure and alpha-beta pruning concept, but:
1. It does not pass `alpha`/`beta` bounds explicitly (they default to -INF/INF, making pruning ineffective for early returns)
2. There is no depth limit parameter — critical for difficulty levels
3. It modifies the board in-place on the recursive stack, which works but requires extreme care

The recommendation is to refactor `_minimax()` to accept `alpha`, `beta`, and `max_depth` parameters, not to rewrite from scratch. The algorithm is correct; the parameterization is incomplete.

## Verification Checklist

Before considering the stack validated:
- [ ] SoundManager singleton accessible as `SoundManager` — verified by code inspection of `sound_manager.gd` line 41 (`Engine.register_singleton`)
- [ ] UIManager singleton accessible as `UIManager` — verified by code inspection of `mc_game_framework.gd` autoload registration
- [ ] I18NManager has `load_translation()`, `set_language()`, `get_text()` — verified by code inspection of `i18n_manager.gd`
- [ ] Event subtypes use `class_name` before trying StringName-based subscription — verified `event.gd` returns class_name first
- [ ] Kenney WAV files import correctly in Godot 4.6 — standard WAV import, no special handling needed
- [ ] Audio bus layout has separate "Sounds" and "Music" buses — must verify in `project.godot` audio section
- [ ] GUT 9.6.0 test runner can discover `tests/` directory — need to create `.gutconfig` file

## Sources

- SoundManager source code (`addons/sound_manager/sound_manager.gd`, `abstract_audio_player_pool.gd`, `sound_effects.gd`, `music.gd`, `ambient_sounds.gd`) — HIGH confidence (direct code analysis)
- mc_game_framework source code (`ui_manager.gd`, `i18n_manager.gd`, `event_bus.gd`, `event.gd`, `registry_manager.gd`, `ui_registry.gd`, `ui_panel.gd`, `ui_layer.gd`, `resource_location.gd`) — HIGH confidence (direct code analysis)
- Existing `game_manager.gd` Minimax implementation — HIGH confidence (direct code analysis)
- Existing `main.gd` GUIDE input setup — HIGH confidence (direct code analysis)
- Godot 4 Tween documentation (rokojori.com) — MEDIUM confidence (web source, verified against known API)
- Godot AnimationPlayer vs Tween community guidance (godotengine.org forum discussions) — MEDIUM confidence (multiple sources agree)
- Godot 4 localization best practices (godotawesome.com) — MEDIUM confidence (single web source)
- Stack Overflow Minimax GDScript fix pattern — MEDIUM confidence (single community source, verified against algorithm theory)
- Godot AI Kit GitHub repository (ryash072007) — LOW confidence (not yet verified against project's algorithm)

---
*Stack research for: Tic-Tac-Toe game polish (audio, UI, animation, AI, localization, code quality)*
*Researched: 2026-06-17*
