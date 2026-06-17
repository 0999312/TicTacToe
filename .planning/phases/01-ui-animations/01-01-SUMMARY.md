---
phase: 01-ui-animations
plan: 01
type: execute
subsystem: UI
wave: 1
tags: [ui, panels, event-bus, animation, i18n, board]
requires: ["Phase 00 (foundation-sound-localization)"]
provides: ["UIManager-migration", "board-extraction"]
affects: [main.gd, main.tscn, game_manager.gd]
tech-stack:
  added: [UIPanel, UIRegistry, UIManager]
  patterns: [panel-lifecycle, eventbus-panel-communication]
key-files:
  created:
    - scenes/board.tscn
    - scripts/board.gd
    - scenes/panels/main_menu.tscn
    - scenes/panels/hud.tscn
    - scenes/panels/game_over.tscn
    - scripts/panels/main_menu.gd
    - scripts/panels/hud.gd
    - scripts/panels/game_over.gd
    - scripts/events/rematch_event.gd
    - scripts/events/game_start_request_event.gd
    - scripts/utils/ui_helpers.gd
    - translations/ja_JP.json
  modified:
    - scripts/main.gd
    - scenes/main.tscn
    - autoload/game_manager.gd
    - translations/zh_CN.json
    - translations/en_US.json
decisions:
  - "GameWonEvent/GameDrawEvent subscription moved from GameOver panel to main.gd: UIManager panel is not alive until opened, so _on_init subscribers would never receive events"
  - "Panel text refresh on language change deferred — panels refresh via _on_open instead of LanguageChangedEvent subscription"
  - "Board._exit_tree unsubscribes events and disables GUIDE context for clean lifecycle"
metrics:
  duration: "~3 minutes"
  completed_date: "2026-06-17"
---

# Phase 01 Plan 01: Core Game Loop with UIManager Migration

Migrated the existing _show_only()-based UI to UIManager stack-based panel management. Extracted Board as an independent scene. Created MainMenu, HUD, and GameOver as UIPanel scenes. Wired the complete game loop (menu -> game -> game over -> menu) using EventBus for panel-to-system communication. Added CQ-02 push_warning validation, CQ-03 shared button animation helper, RematchEvent for Play Again flow, and Japanese translation file.

## Tasks

### Task 1: Board scene extraction, RematchEvent, CQ-02/CQ-03 helpers, Japanese translation

**Commit:** `3e2485f`

**Created:**
- `scripts/events/rematch_event.gd` — RematchEvent class for Play Again flow
- `scripts/utils/ui_helpers.gd` — UIHelpers.static setup_button_animation with hover/press scale+color tweens
- `scenes/board.tscn` — Independent Board scene with 4 Line2D grid lines and 9 Cell instances
- `scripts/board.gd` — Board controller with GUIDE gameplay context (moved from main.gd), subscribes to GameStartedEvent/GameWonEvent/GameDrawEvent
- `translations/ja_JP.json` — Full Japanese translation with all Phase 1 keys
- `scenes/cell.tscn` — Cell scene (needed by board.tscn as external resource dependency)

**Modified:**
- `autoload/game_manager.gd` — Added CQ-02 push_warning calls in place_mark, move_cursor, start_game; added RematchEvent subscription in _ready() with _on_rematch handler calling reset_board()
- `translations/zh_CN.json` — Added Phase 1 keys (settings, pause, common, score_recap)
- `translations/en_US.json` — Added Phase 1 keys (settings, pause, common, score_recap)

### Task 2: MainMenu, HUD, GameOver UIPanel scenes + UIManager registration + game flow wiring

**Commit:** `fff514a`

**Created:**
- `scripts/events/game_start_request_event.gd` — GameStartRequestEvent with mode and player_side fields
- `scenes/panels/main_menu.tscn` + `scripts/panels/main_menu.gd` — MainMenu UIPanel with title, subtitle, PvP/PvAI/Settings/Quit buttons, version label
- `scenes/panels/hud.tscn` + `scripts/panels/hud.gd` — HUD UIPanel with mode label, turn indicator, X/O/draw scores
- `scenes/panels/game_over.tscn` + `scripts/panels/game_over.gd` — GameOver UIPanel with result label, score recap, Play Again and Back to Menu buttons

**Modified:**
- `scenes/main.tscn` — Stripped to root container with only CanvasLayer + TransitionOverlay ColorRect
- `scripts/main.gd` — Complete rewrite: UIRegistry registration, UIManager.open_panel on startup, event subscriptions for GameStartRequestEvent/GameWonEvent/GameDrawEvent/LanguageChangedEvent, translation loading for zh_CN/en_US/ja_JP, _fade_out/_fade_in scaffold

## Deviations from Plan

### Architecture Fix: GameWonEvent/GameDrawEvent subscriber location

**Found during:** Task 2 development

**Issue:** The plan placed GameWonEvent/GameDrawEvent subscriptions inside GameOver panel's _on_init(). However, UIManager only calls _on_init() when the panel is first opened. Since the GameOver panel is not open during gameplay, its _on_init() never runs, and the subscriptions are never registered. The event fires without any handler to open the GameOver panel.

**Fix:** Moved GameWonEvent/GameDrawEvent subscriptions from game_over.gd to main.gd (which is always alive). Main.gd receives these events and opens the GameOver panel via UIManager.open_panel with appropriate data. The GameOver panel receives result data through _on_open(data) and handles user interaction.

**Files modified:**
- `scripts/main.gd` — Added GameWonEvent and GameDrawEvent subscriptions with _on_game_won/_on_game_draw handlers
- `scripts/panels/game_over.gd` — Removed event subscriptions, panel now receives data via _on_open(data) instead

### Rule 2: Missing cell.tscn

**Found during:** Task 1 board scene creation

**Issue:** The board.tscn references cell.tscn as an external resource (same pattern as main.tscn). The worktree did not contain cell.tscn (it was an untracked file in the main repo). Created cell.tscn to satisfy the dependency.

**Fix:** Created `scenes/cell.tscn` with identical structure to the main repo's version.

## Stubs

- Settings button in MainMenu is a no-op (pass). The Settings panel will be implemented in Plan 01-02.
- LanguageChangedEvent handling in panels is deferred — panels refresh text on _on_open only. Real-time language switching will be added in a later plan.
- _fade_out/_fade_in functions in main.gd are scaffolded but unused. Transition animations will be wired in Plan 01-02.

## Threat Flags

None. All UI code operates client-side within Godot engine. No new trust boundaries or network endpoints introduced.

## Self-Check: PASSED

- All 2 tasks completed and committed
- 18 files created/modified across both tasks
- All verification checks pass
- SUMMARY.md created in plan directory
