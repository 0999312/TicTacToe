# Roadmap: Jing Zi Qi (Tic-Tac-Toe) Polish Phase

## Overview

This is a brownfield polish phase for an already-functional Tic-Tac-Toe game built on Godot 4.6 addons. The core game loop (PvP, basic PvAI, win detection, grid interaction) works. Three phases deliver the full polish:

- **Phase 0 (Foundation, Sound & Localization):** Stable event system, audio architecture, settings persistence, sound effects, music, and bilingual support. Everything infrastructure in one pass so downstream phases never need to touch audio, settings, or localization.
- **Phase 1 (UI & Animations):** Proper menu/HUD/game-over panels with UIManager stack navigation, piece placement animations, win-line effects, scene transitions, and button micro-interactions. The visual layer is completed as a single cohesive effort.
- **Phase 2 (AI):** Minimax with alpha-beta pruning, three difficulty tiers with differentiated thinking delays. Standalone final step since AI depends only on Phase 0 infrastructure (settings for difficulty persistence) and is fully parallelizable with Phase 1.

## Phases

- [x] **Phase 0: Foundation, Sound & Localization** (3/3 plans complete) - Stable infrastructure, audio feedback, and bilingual support (completed 2026-06-17)
- [x] **Phase 1: UI & Animations** - Polished navigation flow and visual animations (completed 2026-06-17)
- [x] **Phase 2: AI** - Minimax upgrade with three difficulty tiers (completed 2026-06-17)

## Phase Details

### Phase 0: Foundation, Sound & Localization

**Goal**: All infrastructure layers are stable and complete -- event system, audio, settings persistence, and bilingual support
**Depends on**: Nothing (brownfield, existing codebase)
**Requirements**: FND-01, FND-02, FND-03, FND-04, CQ-01, CQ-04, SND-01, SND-02, SND-03, SND-04, L10N-01, L10N-02, L10N-03, L10N-04
**Success Criteria** (what must be TRUE):

  1. EventBus subscriptions use StringName constants -- no broken subscriptions when scripts are renamed
  2. SoundManager registers exactly once with no duplicate warnings in the output log; AudioBusLayout exists with two buses (SFX, Music) properly configured
  3. Player-chosen settings (volume, difficulty, language) persist between game sessions via ConfigFile
  4. Player hears distinct sound effects when placing marks, winning, losing, and drawing; buttons produce click and hover sounds; background music plays on the main menu and during gameplay with crossfade transitions
  5. All game text displays in Chinese or English, switchable in real-time from the settings panel

**Plans**: 3 plans
**Mode**: mvp
**Plans:**

3/3 plans complete

- [ ] `00-02-PLAN.md` — Audio system (AudioController, SoundRegistry, SFX/Music buses, kenney sounds, music crossfade) + MiSans-Semibold theme resource
- [ ] `00-03-PLAN.md` — Bilingual localization (zh_CN/en_US JSON translation files, tr() adoption in all UI text, LanguageChangedEvent subscription, locale restore)

### Phase 1: UI & Animations

**Goal**: The visual and interaction layer delivers polished menus, HUD, game flow, and animations
**Depends on**: Phase 0
**Requirements**: UI-01, UI-02, UI-03, UI-04, UI-05, ANM-01, ANM-02, ANM-03, ANM-04, CQ-02, CQ-03
**Success Criteria** (what must be TRUE):

  1. Main menu offers clear entry points for PvP, PvAI, settings, and quit
  2. HUD displays current player turn indicator and running score (X wins, O wins, draws)
  3. Game over panel shows the result with Play Again and Back to Menu options; all UI panels use UIManager stack-based navigation with no direct visibility operations
  4. X and O pieces scale from 0 to 1 with a bounce effect when placed; winning line draws with a smooth Tween animation across the three winning cells
  5. Scene transitions fade in and out between menu and gameplay via CanvasLayer; buttons respond with scale and color changes on mouse hover

**Plans**: 2 plans
**Mode**: mvp
**UI hint**: yes
Plans:

- [ ] `01-01-PLAN.md` — Core game loop with UIManager: Board extraction, MainMenu/HUD/GameOver UIPanel scenes, full UIManager migration, CQ-02/CQ-03, RematchEvent, ja_JP translation
- [ ] `01-02-PLAN.md` — Full polish: All animations (place mark bounce, win line, button micro, scene transitions), PauseMenu with Esc, Settings panel with 3 tabs, second music track with crossfade

### Phase 2: AI

**Goal**: Smart opponent with three-tier difficulty stands as the polished final challenge
**Depends on**: Phase 0
**Requirements**: AI-01, AI-02, AI-03, AI-04
**Success Criteria** (what must be TRUE):

  1. AI uses Minimax with alpha-beta pruning for optimal move selection
  2. Player can select Easy / Medium / Hard from the settings panel and observe distinctly different play quality
  3. AI shows thinking delays appropriate to difficulty level (Easy 0.5-1.0s, Medium 0.3-0.6s, Hard 0.2-0.4s) -- not instant placement
  4. AI difficulty selection persists across sessions via ConfigFile (settings from Phase 0)

**Plans**: 1 plan
**Mode**: mvpPlans:

- [ ] `02-01-PLAN.md` — Full AI upgrade: alpha-beta minimax, three-tier difficulty (Easy/Medium/Hard), randomized thinking delays, AiThinkingEvent, HUD thinking indicator, bilingual support

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 0. Foundation, Sound & Localization | 3/3 | Complete    | 2026-06-17 |
| 1. UI & Animations | 2/2 | Complete    | 2026-06-17 |
| 2. AI | 1/1 | Complete   | 2026-06-17 |
