# Phase 0: Foundation, Sound & Localization - Context

**Gathered:** 2026-06-17
**Status:** Ready for planning

## Phase Boundary

Establish all infrastructure layers in one pass — stable event system, audio architecture with full game sound, settings persistence, and bilingual (zh_CN / en_US) support. Downstream phases (UI, AI) depend on this foundation but never need to touch audio, settings, or localization again.

</domain>

## Implementation Decisions

### Event System Refactoring
- **D-01:** Add `class_name` to all 7 existing event scripts + new Phase 0 events. `get_event_type()` auto-resolves to class name — no more hardcoded paths.
- **D-02:** Remove `_event_types` dictionary and `_cache_event_types()` from GameManager. Publish events directly: `EventBus.publish(CellPlacedEvent.new(...))`.
- **D-03:** All subscriptions use StringName literals: `EventBus.subscribe(&"CellPlacedEvent", callback)`.
- **D-04:** New Phase 0 event: `SettingChangedEvent` — per-key granularity (`key: String, value: Variant`). Published by SettingsManager on every setting change.

### Audio Architecture
- **D-05:** AudioBusLayout has 2 custom buses under Master: **SFX** and **Music**. No separate UI bus — UI sounds route through SFX.
- **D-06:** New `AudioController` autoload (registered in project.godot after SettingsManager). Listens to EventBus game events and calls SoundManager. GameManager never touches audio.
- **D-07:** Sound-to-event mapping uses mc_game_framework's **ResourceLocation** + **RegistryManager** pattern. New `SoundRegistry` extends `RegistryBase`. All audio resources registered under single namespace `tic_tac_toe:`.
- **D-08:** AudioController preloads all sound resources in `_ready()` from SoundRegistry into a memory cache. No lazy loading.
- **D-09:** SoundManager channels routed to custom buses via `set_default_sound_bus("SFX")` and `set_default_music_bus("Music")` in AudioController._ready().
- **D-10:** Kenney sounds mapped semantically per game event (e.g., place mark → drop, win → confirmation, lose → error, draw → bong, button click → click, button hover → tick). Specific files chosen during implementation.
- **D-11:** Background music uses existing `music/off_to_osaka.mp3` only. Menu ↔ gameplay crossfade via `SoundManager.play_music(crossfade_duration)`. Second music track deferred to Phase 1.
- **D-12:** Volume recovery: AudioController reads saved values from SettingsManager on startup, applies via `SoundManager.set_sound_volume()` / `set_music_volume()`. Default SFX=0.8, Music=0.8.
- **D-13:** FND-02: Remove duplicate SoundManager registration from `project.godot` `[autoload]`. Keep only plugin-based registration (`addons/sound_manager/plugin.gd`).
- **D-14:** FND-03: AudioController._ready() detects SFX/Music buses at runtime, creates if missing. Editor manual setup as primary; runtime detection as fallback.

### Settings Persistence
- **D-15:** New `SettingsManager` autoload — centralized ConfigFile persistence layer. Memory-cached `get(key)` / `set(key, value)` API. `set()` publishes `SettingChangedEvent`.
- **D-16:** ConfigFile at `user://settings.cfg`. Sections: `[audio]` (sfx_volume, music_volume), `[gameplay]` (difficulty), `[language]` (locale).
- **D-17:** Save strategy: persist to disk when exiting settings screen or exiting game (NOT on every individual change). Memory is the live state.
- **D-18:** Default settings from a Resource file (`res://resources/default_settings.tres`). Hardcoded fallbacks: sfx_volume=0.8, music_volume=0.8, difficulty=1 (Medium), locale="zh_CN".
- **D-19:** Corrupt/missing config: silent fallback to defaults + `push_warning()`. Game continues normally.
- **D-20:** Autoload order in project.godot: SettingsManager → AudioController. SettingsManager must initialize before AudioController reads volume values.

### Localization
- **D-21:** Translation keys structured by UI panel in nested JSON: `main_menu.title`, `hud.turn_label`, `game_over.win_text`. I18NManager flattens nested dict to dotted keys automatically.
- **D-22:** Source language: zh_CN (Chinese), ASCII-only keys, Chinese values. English in separate en_US.json with same key structure.
- **D-23:** CJK font: **MiSans-Semibold** (already in `fonts/MiSans-Semibold.ttf`). Applied via global Theme resource (`res://resources/theme/default_theme.tres`) set in `project.godot` `gui/theme/custom`.
- **D-24:** All UI text uses `tr("key.path")` via Godot's TranslationServer. The existing `LanguageChangedEvent` (from mc_game_framework, already published by I18NManager.set_language()) drives real-time UI refresh — components subscribe and call `_refresh_text()`.
- **D-25:** All 13+ existing hardcoded Chinese strings replaced with `tr()` calls in a single pass. Corresponding JSON entries created simultaneously.
- **D-26:** Translation files loaded at startup via `I18NManager.load_translation()`. SettingsManager restores last-used locale from ConfigFile, then I18NManager.set_language() applies it.

### Claude's Discretion
- Specific kenney sound file selection within each semantic category (which drop_00X.wav for place mark, which confirmation_00X.wav for win, etc.). Pick during implementation and test.
- ResourceLocation path naming within `tic_tac_toe:` namespace. Follow pattern: `sounds/<category>/<filename>`.
- SoundRegistry internal structure — use familiar RegistryBase patterns from mc_game_framework.
- Theme resource font size and Control node base type defaults.

</decisions>

## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project Planning
- `.planning/ROADMAP.md` — Phase 0 scope, success criteria, dependencies
- `.planning/REQUIREMENTS.md` — 14 requirements (FND, SND, L10N, CQ) mapped to Phase 0
- `.planning/PROJECT.md` — Key decisions, constraints, existing context

### Codebase Maps
- `.planning/codebase/ARCHITECTURE.md` — Autoload layer, data flow, event system, anti-patterns to fix
- `.planning/codebase/INTEGRATIONS.md` — SoundManager channels, I18NManager API, kenney_interface_sounds catalog, addon registration patterns
- `.planning/codebase/CONVENTIONS.md` — Naming, typing, event class patterns, subscription patterns

### Framework (read before implementing)
- `addons/mc_game_framework/event/event.gd` — `get_event_type()` resolution (class_name priority)
- `addons/mc_game_framework/autoload/i18n_manager.gd` — `load_translation()`, `set_language()`, `_flatten_dict()`
- `addons/mc_game_framework/event/language_changed_event.gd` — Already has class_name LanguageChangedEvent, carries `lang_code: String`
- `addons/mc_game_framework/utils/resource_location.gd` — `namespace:path` format, `from_string()` parser
- `addons/mc_game_framework/registry/registry_base.gd` — Base class for SoundRegistry
- `addons/sound_manager/sound_manager.gd` — `play_sound()`, `play_ui_sound()`, `play_music()`, `set_sound_volume()`, `set_music_volume()`, `set_default_sound_bus()`, `set_default_music_bus()`
- `addons/sound_manager/sound_effects.gd` — Sound effects channel (pool 8)
- `addons/sound_manager/music.gd` — Music channel with crossfade (pool 2)

### Assets
- `addons/kenney_interface_sounds/` — 99+ WAV across 20 categories (back, bong, click, close, confirmation, drop, error, glass, glitch, maximize, minimize, open, pluck, question, scratch, scroll, select, switch, tick, toggle)
- `music/off_to_osaka.mp3` — Single background music track
- `fonts/MiSans-Semibold.ttf` — CJK font for Chinese text

</canonical_refs>

## Existing Code Insights

### Reusable Assets
- **SoundManager autoload:** Already registered, 4 channels (sound_effects/ui_sound_effects/ambient_sounds/music), volume control API, crossfade support. Needs bus re-routing to SFX/Music.
- **I18NManager autoload:** Already registered, `load_translation()` + `set_language()` + `LanguageChangedEvent` publishing all implemented. Just needs JSON files and `tr()` adoption.
- **kenney_interface_sounds:** 99+ CC0 WAV files in 20 categories, zero code references yet. Ready for AudioController mapping.
- **RegistryManager:** Already registered. Supports type-based and tag-based registries. SoundRegistry can extend RegistryBase.
- **Event base class:** `RefCounted` event system with `get_event_type()` priority chain — `class_name` → `script.resource_path` → `"UnknownEvent"`.

### Established Patterns
- **Event-driven communication:** All cross-system notification via EventBus. AudioController follows this — listens for game events, plays sounds.
- **Autoload singleton architecture:** GameManager is the SSOT. New autoloads (AudioController, SettingsManager) follow the same pattern — global access, no scene dependency.
- **`_on_` handler naming:** EventBus handlers use `_on_` prefix. Maintain this convention in new handlers.
- **`_make_` factory naming:** Factory/helper methods use `_make_` prefix.

### Integration Points
- **Autoload chain:** `res://project.godot` `[autoload]` section. Add AudioController, SettingsManager. Order: SettingsManager before AudioController. Remove redundant SoundManager uid-based entry.
- **Main scene:** `main.gd` currently manages panels + GUIDE input + EventBus subscriptions. After Phase 0, it gains `tr()` calls and subscribes to `LanguageChangedEvent` for text refresh.
- **GameManager:** Publishes game events already consumed by Cell and Main. AudioController becomes the third subscriber (listens for game events → plays sounds). GameManager's `_event_types` cache is removed.
- **AudioBusLayout:** Must be created in editor (Audio panel: SFX bus, Music bus). AudioController._ready() verifies existence.

</code_context>

## Specific Ideas

- User specifically wants mc_game_framework's ResourceLocation + RegistryManager pattern for sound management — not hardcoded paths or custom dictionaries. Follow the framework's design philosophy.
- User prefers editor-friendly configuration (Resource files, Theme resources) over code-only configuration.
- User added MiSans-Semibold specifically — use .ttf variant (8MB), not .otf.

</specifics>

## Deferred Ideas

- Second music track for gameplay → Phase 1 (UI & Animations)
- RTL support for Arabic/Hebrew → out of scope (zh_CN + en_US only)
- AudioStreamRandomizer for sound variation within events → future enhancement

---

*Phase: 00-Foundation, Sound & Localization*
*Context gathered: 2026-06-17*
