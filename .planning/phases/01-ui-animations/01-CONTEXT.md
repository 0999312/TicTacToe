# Phase 1: UI & Animations - Context

**Gathered:** 2026-06-17
**Status:** Ready for planning

<domain>
## Phase Boundary

The visual and interaction layer delivers polished menus, HUD, game flow, and animations. All UI panels migrate from direct `_show_only()` visibility toggling to UIManager stack-based navigation. Board becomes an independent scene. Four game panels (MainMenu, HUD, GameOver, PauseMenu) plus Settings panel. Animations cover piece placement, win line drawing, scene transitions, and button micro-interactions. Japanese (ja_JP) localization is added alongside existing zh_CN/en_US. A second music track is introduced for gameplay with crossfade switching.

</domain>

<decisions>
## Implementation Decisions

### UIManager Migration
- **D-01:** Each panel is an independent `.tscn` scene inheriting `UIPanel` base class. Managed via `UIManager.open_panel()` / `close_panel()`.
- **D-02:** One-time full replacement — all `_show_only()` calls deleted, all panels migrated simultaneously.
- **D-03:** Panel layer strategy: HUD on NORMAL layer (always visible during gameplay), GameOver as POPUP overlay on top of HUD. MainMenu, PauseMenu, Settings on NORMAL layer, mutually exclusive.
- **D-04:** Board (Node2D + 9 Cell + Line2D) becomes an independent scene. `main.tscn` becomes a root container only.
- **D-05:** Panel-to-system communication via EventBus + GameManager. Panels publish typed events; GameManager subscribes and responds. Panels never call GameManager directly.
- **D-06:** Each UIPanel creates its own GUIDEMappingContext in `_on_open()` and destroys it in `_on_close()`. Gameplay GUIDE context managed by the Board scene independently.
- **D-07:** UIRegistry uses explicit registration — `main.gd _ready()` calls `UIManager.register_panel()` for each panel scene path.

### Panel Inventory (new panels)
- **D-08:** New PauseMenu panel — opened via Esc during gameplay. Three buttons: Resume (close panel), Settings (push Settings panel), Back to Main Menu (pop to MainMenu). Game screen dims behind the pause overlay (POPUP layer).
- **D-09:** Settings accessible from both MainMenu (settings button) and PauseMenu (settings button). Back button uses UIManager stack pop — returns to whichever panel opened it.

### Animation Style & Rhythm
- **D-10:** Overall style: light and lively. Bounce easing, durations 0.2-0.4s. Not exaggerated but noticeably playful — fits a casual board game.
- **D-11:** Win line animation: draw a colored line across the three winning cells via Tween, plus highlight the three winning cells with a brief flash/pulse. Dual-layer feedback.
- **D-12:** Scene transitions: full-screen black ColorRect on top CanvasLayer, Tween modulate.a 0↔1. Fade out → load → fade in. Duration ~0.3s.
- **D-13:** Button micro-interactions: hover → scale 1.05 + modulate brighten; press → scale 0.95. Tween 0.1s transition. Both scale and color change.

### Place Mark Animation
- **D-14:** X/O pieces scale from 0→1.2→1.0 with elastic/bounce easing (~0.25s duration). Implemented on Cell's Sprite2D via Tween.

### Settings Panel Layout & Interaction
- **D-15:** Tab-based layout: Audio tab, Game tab, Language tab. TabBar at top for switching.
- **D-16:** Volume controls: HSlider (0-100) with real-time preview. Dragging immediately calls `SoundManager.set_sound_volume()` / `set_music_volume()`. Percentage label displayed next to slider. Persisted on panel close.
- **D-17:** AI difficulty: three independent side-by-side buttons (Easy / Medium / Hard). Selected button highlighted. Matches button micro-interaction style.
- **D-18:** Language: OptionButton dropdown with three entries (中文, English, 日本語). Extensible for future languages.
- **D-19:** Settings apply instantly on change, persist to ConfigFile on panel close (leveraging existing SettingsManager save-on-exit strategy from Phase 0).

### Localization Extension
- **D-20:** ja_JP Japanese support added in this phase. New `ja_JP.json` translation file with same ASCII key structure as zh_CN/en_US. Added to I18NManager load list at startup. Dropdown menu supports all three languages.

### Game Music
- **D-21:** Second music track: `music/breaktime.mp3` (already exists in project). Menu scenes = `off_to_osaka.mp3`, gameplay = `breaktime.mp3`.
- **D-22:** Crossfade duration: 1.0-1.5s between menu and gameplay music.
- **D-23:** Pause behavior: when PauseMenu opens, music volume reduces to 50% of current setting. If current music volume is already very low (below audible threshold), no reduction. Restore full volume on resume.

### Main Menu Layout
- **D-24:** Centered vertical layout. Large title "井字棋" + subtitle "Tic-Tac-Toe" in MiSans-Semibold at top. Four buttons vertically stacked: [双人对战] [人机对战] [设置] [退出游戏]. Version number ("v0.1.0") in small text at bottom.
- **D-25:** Score display: not on main menu. Scores shown in HUD (three columns: X wins | O wins | Draws) and on Game Over panel.

### Code Quality
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

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project Planning
- `.planning/ROADMAP.md` — Phase 1 scope, success criteria, requirements mapping
- `.planning/REQUIREMENTS.md` — UI-01 through UI-05, ANM-01 through ANM-04, CQ-02, CQ-03
- `.planning/PROJECT.md` — Constraints, key decisions, existing architecture

### Prior Phase Context
- `.planning/phases/00-foundation-sound-localization/00-CONTEXT.md` — Phase 0 decisions: AudioController architecture (D-06), SoundRegistry pattern (D-07/D-08), SettingsManager API (D-15/D-16), Theme resource with MiSans-Semibold (D-23), tr() for all UI text (D-24), event system refactoring (D-01 to D-04)

### Codebase Maps
- `.planning/codebase/ARCHITECTURE.md` — Autoload chain, data flow, event system patterns
- `.planning/codebase/STRUCTURE.md` — Scene organization, directory layout, where to add new code
- `.planning/codebase/CONVENTIONS.md` — Naming, typing, event class patterns, subscription patterns

### Framework (read before implementing)
- `addons/mc_game_framework/autoload/ui_manager.gd` — `open_panel()`, `close_panel()`, panel stack management
- `addons/mc_game_framework/ui/ui_panel.gd` — UIPanel base class: `_on_open()`, `_on_close()`, `_on_pause()`, `_on_resume()`
- `addons/mc_game_framework/ui/ui_layer.gd` — Layer constants (SCENE, NORMAL, POPUP, TOAST, OVERLAY)
- `addons/mc_game_framework/registry/ui_registry.gd` — Panel registration via `register_panel()`
- `addons/mc_game_framework/autoload/i18n_manager.gd` — `load_translation()`, `set_language()`
- `addons/guide/guide.gd` — GUIDE singleton, context management
- `addons/sound_manager/sound_manager.gd` — `play_music()`, `set_music_volume()`, crossfade support

### Assets
- `music/off_to_osaka.mp3` — Menu background music
- `music/breaktime.mp3` — Gameplay background music (already imported)
- `fonts/MiSans-Semibold.ttf` — CJK font (already configured as Theme default in Phase 0)

### Translation Files
- `resources/translations/zh_CN.json` — Chinese translations (existing from Phase 0)
- `resources/translations/en_US.json` — English translations (existing from Phase 0)
- `resources/translations/ja_JP.json` — Japanese translations (NEW, to be created)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **UIManager autoload:** Already registered, stack-based panel management, layer system, panel lifecycle hooks. Never used by project code — Phase 1 is the first consumer.
- **UIPanel base class:** `addons/mc_game_framework/ui/ui_panel.gd` provides `_on_open(data)`, `_on_close()`, `_on_pause()`, `_on_resume()`. All new panels extend this.
- **UILayer constants:** SCENE=0, NORMAL=1, POPUP=2, TOAST=3, OVERLAY=4. Used in `open_panel(scene, data, layer)`.
- **AudioController:** Already handles music playback and crossfade. Adding second track means extending its track registry.
- **SettingsManager:** `get_value(key)` / `set_value(key, value)` API. Settings panel reads/writes via this. `SettingChangedEvent` published on changes.
- **I18NManager:** `set_language(locale)` publishes `LanguageChangedEvent`. All UI text uses `tr()`. Adding ja_JP is a JSON file + one `load_translation()` call.
- **SoundManager:** `set_sound_volume()`, `set_music_volume()`, `play_music()` with crossfade. All called by AudioController, not directly by UI.
- **EventBus:** Already refactored in Phase 0 — `class_name` events, `EventBus.publish(CellPlacedEvent.new(...))`, `EventBus.subscribe(&"EventName", callback)`.

### Established Patterns
- **Event-driven communication:** All cross-system interaction via EventBus. New panels publish events for mode selection, game start, etc. AudioController listens for game events.
- **Autoload singleton architecture:** UIManager, GameManager, EventBus, SettingsManager, AudioController, I18NManager, GUIDE. New code accesses them by name.
- **`_on_` handler naming:** EventBus handlers use `_on_` prefix.
- **`_make_` factory naming:** Factory/helper methods use `_make_` prefix.
- **GUIDE context pattern:** Current gameplay context in `main.gd:_setup_guide_input()`. Each panel follows this pattern for its own inputs.

### Integration Points
- **main.tscn → root container:** After migration, `main.tscn` only instantiates Board scene, registers panels with UIManager, and sets up the transition ColorRect. GUIDE input setup moves to Board scene.
- **GameManager:** Publishes game lifecycle events. Panels subscribe for state changes (turn, score, game over). GameManager remains SSOT — panels are views only.
- **AudioController:** Listens for game events + music transition triggers. Extended to handle two music tracks with scene-aware switching.
- **SettingsManager → Settings panel:** Panel reads initial values on open, writes on change (instant preview), persists on close.

### Current Anti-Patterns to Remove
- `main.gd:_show_only()` — replace with UIManager panel management
- Hardcoded UI visibility toggling — replace with stack-based navigation
- All-in-one main.tscn — split into independent scenes

</code_context>

<specifics>
## Specific Ideas

- User explicitly chose UIManager integration path — independent scenes per panel, not a gradual migration. This is a full architectural pivot for UI management.
- User wants PauseMenu as a new panel type (not originally in requirements). This emerged naturally from the Esc-during-gameplay flow discussion.
- User specifically requested ja_JP language support in this phase. The translation file needs to be created alongside the settings dropdown implementation.
- User already has `music/breaktime.mp3` in the project — it was placed there intentionally for Phase 1 use.
- Music volume reduction on pause is user-specified: "50% of current, but don't reduce if already very low" — needs a minimum threshold check in implementation.
- Settings use tabbed layout despite only having a few settings — user prefers the structured organization.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope. The ja_JP addition and PauseMenu panel emerged as natural extensions of the settings and UI flow discussions, not scope creep.
</deferred>

---

*Phase: 01-UI & Animations*
*Context gathered: 2026-06-17*
