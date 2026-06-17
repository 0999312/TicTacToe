# Requirements: Jing Zi Qi

**Defined:** 2026-06-17
**Core Value:** Yi pan ling ren yu yue de jing zi qi -- from opening the game to deciding the winner, every step has clear visual and audio feedback.

## v1 Requirements

Requirements for the polish milestone. Each maps to roadmap phases.

### Foundation

- [x] **FND-01**: EventBus script path use StringName constants to replace hardcoded strings
- [x] **FND-02**: Remove SoundManager double registration, verify singleton correctness
- [x] **FND-03**: Create AudioBusLayout (SFX / Music / UI three buses)
- [x] **FND-04**: Add `push_error`/`push_warning` error handling to project code

### UI

- [x] **UI-01**: Main menu interface -- title, PvP/PvAI buttons, settings button, quit button
- [x] **UI-02**: In-game HUD -- current player indicator (X/O), score display (X wins/O wins/draws)
- [x] **UI-03**: Game over panel -- result display (winner/draw), play again, back to menu buttons
- [x] **UI-04**: Settings panel -- SFX/music volume sliders, AI difficulty selection, language switch
- [x] **UI-05**: All UI panels use UIManager stack management to replace `_show_only()` direct manipulation

### Sound

- [x] **SND-01**: Game SFX playback -- place mark sound, win sound, lose sound, draw sound
- [x] **SND-02**: Button interaction sounds -- click sound, hover sound (use kenney_interface_sounds)
- [x] **SND-03**: Background music -- menu music, in-game music, with crossfade switching
- [x] **SND-04**: Independent SFX and music volume control via settings panel sliders

### AI

- [ ] **AI-01**: Minimax algorithm implementation (with alpha-beta pruning)
- [ ] **AI-02**: Three difficulty tiers -- Easy (random), Medium (depth-limited + random injection), Hard (full search)
- [ ] **AI-03**: Differentiated thinking delay -- Easy (0.5-1.0s), Medium (0.3-0.6s), Hard (0.2-0.4s)
- [ ] **AI-04**: Settings panel AI difficulty selector

### Animation

- [x] **ANM-01**: Win line animation -- Tween draws a highlight line across the winning row/column/diagonal
- [x] **ANM-02**: Place mark animation -- X/O piece scale bounces from 0 to 1
- [x] **ANM-03**: Scene transition -- menu <-> game fade in/out effect (CanvasLayer + ColorRect)
- [x] **ANM-04**: Button micro-interaction -- subtle scale/color change on hover

### Localization

- [x] **L10N-01**: Chinese and English translation files (JSON format, ASCII-only key ID)
- [x] **L10N-02**: CJK font fallback support (Noto Sans SC or equivalent)
- [x] **L10N-03**: In-game language switch (settings panel), takes effect in real-time
- [x] **L10N-04**: All UI text uses `tr()` function for automatic translation

### Code Quality

- [x] **CQ-01**: Eliminate EventBus hardcoded script path strings, use StringName constants
- [x] **CQ-02**: Add parameter validation and `push_warning` to all GameManager public methods
- [x] **CQ-03**: Extract duplicate code to shared helper functions
- [x] **CQ-04**: Settings persistence -- ConfigFile save/load for volume, difficulty, language

## v2 Requirements

Deferred to future release.

- **ONL-01**: Online multiplayer (ENet/WebSocket)
- **UNDO-01**: Undo move (PvP only)
- **TUTO-01**: Tutorial
- **THEME-01**: Customizable board theme

## Out of Scope

| Feature | Reason |
|---------|--------|
| AI personality differentiation (strategy style) | Difficulty tiers only, no strategy style variance |
| Export and build configuration | Not part of this milestone |
| Large test suite | Not part of this milestone, GUT framework available for later |
| Undo/redo | Keep v1 simple, consider for v2 |
| Online multiplayer | Pure local game, 10x scope expansion |
| Achievements/badge system | Depends on external platform, beyond project scope |
| 6x6/4x4 board mode | Keep standard 3x3 tic-tac-toe |
| Custom board theme/skin | Single refined theme is sufficient |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| FND-01 | Phase 0 | Complete (00-01) |
| FND-02 | Phase 0 | Complete |
| FND-03 | Phase 0 | Complete |
| FND-04 | Phase 0 | Complete (00-01) |
| CQ-01 | Phase 0 | Complete (00-01) |
| CQ-04 | Phase 0 | Complete (00-01) |
| SND-01 | Phase 0 | Complete |
| SND-02 | Phase 0 | Complete |
| SND-03 | Phase 0 | Complete |
| SND-04 | Phase 0 | Complete |
| L10N-01 | Phase 0 | Complete |
| L10N-02 | Phase 0 | Complete |
| L10N-03 | Phase 0 | Complete |
| L10N-04 | Phase 0 | Complete |
| UI-01 | Phase 1 | Complete |
| UI-02 | Phase 1 | Complete |
| UI-03 | Phase 1 | Complete |
| UI-04 | Phase 1 | Complete |
| UI-05 | Phase 1 | Complete |
| ANM-01 | Phase 1 | Complete |
| ANM-02 | Phase 1 | Complete |
| ANM-03 | Phase 1 | Complete |
| ANM-04 | Phase 1 | Complete |
| CQ-02 | Phase 1 | Complete |
| CQ-03 | Phase 1 | Complete |
| AI-01 | Phase 2 | Pending |
| AI-02 | Phase 2 | Pending |
| AI-03 | Phase 2 | Pending |
| AI-04 | Phase 2 | Pending |

**Coverage:**

- v1 requirements: 29 total
- Mapped to phases: 29
- Unmapped: 0

---

*Requirements defined: 2026-06-17*
*Last updated: 2026-06-17 -- traceability updated with revised 3-phase roadmap*
