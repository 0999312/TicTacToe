# Project Research Summary

**Project:** Tic-Tac-Toe (Jing Zi Qi) Polish Phase
**Domain:** Godot 4.6 2D board game polish (audio, UI, animation, AI, localization, code quality)
**Researched:** 2026-06-17
**Confidence:** HIGH

## Executive Summary

This is a polish-and-completion phase for an already-functional Godot 4.6 Tic-Tac-Toe game built on existing addons (mc_game_framework, SoundManager, GUIDE, GUT). The core game loop -- local PvP, basic PvAI, win/draw detection, visual grid -- is complete. The polish phase adds audio feedback, proper UI panels with stack-based navigation, visual animations, three-tier AI difficulty, bilingual Chinese/English localization, settings persistence, and code quality improvements (error handling, EventBus cleanup).

The recommended approach is a dependency-driven build order with a mandatory Foundation phase first. All six new systems (AudioController, SettingsManager, UIManager activation, I18NManager activation, Minimax AI tiers, Animation) must wait for the Foundation fixes: hardcoded EventBus script paths must be replaced with constants, the SoundManager double-registration must be removed, and the existing _show_only() visibility management must be migrated to UIManager. Without this foundation, every new feature built on top will inherit fragile patterns that fail silently when files move or panels stack incorrectly.

The key risk is silent failures from the EventBus current string-path subscription pattern and zero error handling across the codebase. Mitigation: fix EventBus subscriptions at the very start (Phase 0) and enforce a per-function error-handling standard for all new code. A secondary risk is Tween lifecycle mismanagement across many animation call sites. Audio bus architecture must be set up before any SoundManager calls are written.

## Key Findings

### Recommended Stack

All dependencies are vendored under addons/. No new plugins are needed. The key constraint is use existing addons.

**Core technologies:**
- Godot 4.6 with GDScript 2.0: Already the project runtime. 720x720 viewport, canvas_items stretch. No C# new code.
- SoundManager v2.6.1: Audio playback with channel pooling (4 channels). Already registered but unused.
- UIManager (mc_game_framework): Stack-based UI panel management with lifecycle hooks. Bypassed by _show_only().
- I18NManager (mc_game_framework): JSON translation loading, runtime language switching, reactive UI.
- GUIDE v0.13.0: Context-based input system. Already integrated.
- GUT v9.6.0: Unit testing. Installed but unused.
- Godot Tween (built-in): All runtime animations. Chosen over AnimationPlayer.

**Key stack decisions:**
- JSON over CSV for translations (avoids CSV import bugs)
- Tween over AnimationPlayer (runtime values, avoids RESET bug)
- Minimax depth-limited for difficulty tiers, not multi-threaded
- Event subscriptions via class_name constants, not script-path strings


### Expected Features

**Must have (table stakes):**
- Game SFX (piece placement, win, lose, draw) -- highest-impact polish item
- Button click/hover sounds -- audio feedback on UI
- HUD (current player indicator + score) -- essential
- Game over panel (result + play again + back to menu) -- game flow
- Main menu screen (title, mode select, start button) -- navigation
- Settings panel (volume, AI difficulty, language) -- v1 polish
- Minimax AI with 3 difficulty tiers -- replayability

**Should have (competitive advantage):**
- Win line animation (Tween stroke across winning cells)
- Place mark animation (piece scale 0 to 1 with bounce)
- Scene transitions (fade in/out via CanvasLayer)
- Button hover animation (scale on mouse enter/exit)
- Background music with crossfade
- Independent volume sliders (SFX vs Music)
- In-game language switch (Chinese/English)
- Settings persistence (ConfigFile)

**Defer (v2+):**
- Move undo (PvP only)
- Cell hover highlight animation

### Architecture Approach

The architecture is EventBus-driven with GameManager as single source of truth (SSOT). Six new systems integrate without modifying GameManager core: AudioController (EventBus to SoundManager bridge), SettingsManager (configuration hub), UIManager activation (stack-based panel lifecycle), I18NManager activation (JSON translations, LanguageChangedEvent), Minimax AI enhancement (difficulty enum + depth-limited search), Animation (view-layer Tween reactions).

**Major components:**
1. GameManager (autoload) -- SSOT for board, turn, scores, AI. Publishes 7 events.
2. SettingsManager (NEW autoload) -- Config hub. Reads/writes user://settings.cfg.
3. AudioController (NEW autoload) -- EventBus subscriber, calls SoundManager.
4. UIManager (existing, activate) -- Stack-based panel lifecycle.
5. Board (NEW script) -- Win line animation, cell lookup.
6. TransitionLayer (NEW node) -- CanvasLayer (layer 128) + ColorRect for fades.
7. Main (existing, refactored) -- Reduced scope: GUIDE setup only.

**Key rules:** GameManager stays SSOT. No direct calls between new systems. Events extended with fields, not replaced.

### Critical Pitfalls

1. **SoundManager Without Audio Bus Architecture** -- All sounds on Master bus prevents volume control. Prevention: Create AudioBusLayout BEFORE any SoundManager calls.
2. **Tween Lifecycle Management** -- Tween.kill() does not null reference. await on killed tween hangs. Prevention: Standardized _kill_tween() helper.
3. **EventBus Hardcoded Paths + No Error Handling** -- subscribe("res://...gd") silently breaks. Prevention: Replace with preload() constants in Phase 0.
4. **Fade Transition Flicker** -- root.modulate.a does not affect CanvasLayer UI. Prevention: Dedicated CanvasLayer at layer 128.
5. **Non-ASCII Translation Keys on Android** -- Chinese in CSV key column returns empty. Prevention: ASCII-only key IDs.

## Implications for Roadmap

### Phase 0: Foundation and Cleaning
**Rationale:** Every phase depends on stable EventBus, clean SoundManager, proper error handling.
**Delivers:** EventBus paths fixed. SoundManager double-registration removed. AudioBusLayout created. UIRegistry set up. .gitignore for .translation files.
**Pitfalls addressed:** P8 (EventBus paths), P9 (UIManager bypass), P15 (double-registration), P14 (CSV UIDs)
**Research flag:** Standard patterns. Skip research-phase.

### Phase 1: SettingsManager (Configuration Hub)
**Rationale:** Shared dependency for audio, localization, and AI phases.
**Delivers:** ConfigFile CRUD for volume, difficulty, language. Setters wired to SoundManager, GameManager, I18NManager.
**Research flag:** Standard ConfigFile pattern. Skip research-phase.

### Phase 2A: Audio System (Parallel with 2B, 2C)
**Rationale:** Depends on SettingsManager + Phase 0 AudioBusLayout.
**Delivers:** AudioController autoload. SFX (place, win, lose, draw, buttons). BGM with crossfade.
**Pitfalls addressed:** P1, P11, P17, P19
**Research flag:** SoundManager API well-documented. Skip research-phase.

### Phase 2B: Localization (Parallel with 2A, 2C)
**Rationale:** Depends on SettingsManager (language persistence).
**Delivers:** en.json and zh.json translations. I18NManager activation. CJK fallback font.
**Pitfalls addressed:** P7, P14
**Research flag:** Standard I18NManager usage. Skip research-phase.

### Phase 2C: AI Enhancement (Parallel with 2A, 2B)
**Rationale:** Depends on SettingsManager (difficulty). Modifies GameManager only.
**Delivers:** AI_DIFFICULTY enum (EASY, MEDIUM, HARD). Thinking delay tiers. Timing guardrail.
**Pitfalls addressed:** P6
**Research flag:** NEEDS research-phase. Current Minimax alpha-beta implementation needs source verification.

### Phase 3: UI Refactor (UIManager Activation)
**Rationale:** Independent chain. Best after Phase 2B for i18n-ready panels.
**Delivers:** All panels as UIPanel subclasses. Stack navigation. TransitionLayer. Input unification (GUIDE + mouse).
**Pitfalls addressed:** P3, P4, P5, P12, P13, P21
**Research flag:** MAY NEED research-phase for GUIDE + mouse interaction.

### Phase 4: Animation
**Rationale:** Depends on Phase 3 (transitions need panel lifecycle).
**Delivers:** Win line Tween. Cell placement animation. TransitionLayer fades. Button hover Tweens.
**Pitfalls addressed:** P2, P10, P20
**Research flag:** Standard Tween API. Skip research-phase.

### Phase 5: Testing and Polish
**Rationale:** All phases must exist before integration testing.
**Delivers:** GUT tests for Minimax, win detection, state transitions. Error handling pass. Full QA.
**Research flag:** Standard GUT patterns. Skip research-phase.

### Research Flags Summary
Needs research-phase: Phase 2C (AI Enhancement), Phase 3 (input unification)
Skip research-phase: Phase 0, 1, 2A, 2B, 4, 5

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | All APIs verified by reading source code of every integration target. |
| Features | HIGH | Prioritization grounded in existing codebase analysis and reference comparison. |
| Architecture | HIGH | Every integration path verified against actual addon source code. |
| Pitfalls | HIGH | All critical pitfalls grounded in confirmed Godot GitHub issues or project-specific code analysis. |

**Overall confidence:** HIGH

### Gaps to Address
- **Minimax alpha-beta signature:** Needs code-level verification. Phase 2C should start with code-read of game_manager.gd.
- **GUIDE + mouse click interaction:** Needs runtime spike test before committing to input unification.
- **SoundManager register_singleton() impact:** Verify removing redundancy does not break internal dependencies.
- **Godot 4.6 AnimationPlayer RESET bug:** Confirmed 4.0-4.2, unverified for 4.6. Mitigation (use Tween) already in place.

## Sources

### Primary (HIGH confidence)
- SoundManager source code (direct API verification)
- mc_game_framework source code (UIManager, I18NManager, EventBus, UIPanel)
- Existing game_manager.gd, main.gd, cell.gd (architecture code analysis)
- Project requirements (.planning/PROJECT.md)
- Codebase structure (.planning/codebase/STRUCTURE.md)

### Secondary (MEDIUM confidence)
- Godot 4 Tween documentation and community best practices
- Godot 4 localization best practices
- Minimax GDScript implementation patterns (verified against algorithm theory)
- Godot forum scene transition patterns

### Tertiary (LOW confidence)
- Godot 4.6 AnimationPlayer RESET bug status (unverified)
- GUIDE + Area2D mouse interaction (needs runtime testing)

---
*Research completed: 2026-06-17*
*Ready for roadmap: yes*