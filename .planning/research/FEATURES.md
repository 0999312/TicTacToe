# Feature Research

**Domain:** Tic-Tac-Toe (Jing Zi Qi) polished board game
**Researched:** 2026-06-17
**Confidence:** HIGH

## Feature Landscape

### Table Stakes (Users Expect These)

Features users assume exist for any "complete" board game. Missing these = product feels broken or cheap.

| Feature | Why Expected | Complexity | Godot-Specific Notes |
|---------|--------------|------------|----------------------|
| **Move execution sound** (place piece) | Every board game makes a sound when you put a piece down. Silent placement feels broken. | LOW | Single AudioStreamPlayer, one-shot playback via SoundManager. Kenney interface sounds already in project. |
| **Win/loss/draw result sound** | Players expect audio feedback at game outcome — a distinct sound for winning vs losing vs draw. | LOW | Three separate WAV assets triggered by GameWonEvent/GameDrawEvent. |
| **Button click feedback** (audible) | Buttons that make no sound feel dead. Users subconsciously expect interface sounds. | LOW | Use kenney_interface_sounds click variants. Connect to button `pressed` signal or via button theme. |
| **Current player indicator** (HUD) | Must know whose turn it is at a glance. | LOW | Label or icon in HUD panel, updated via TurnChangedEvent. The 720x720 viewport is small — keep text large. |
| **Score display** (HUD) | Board games track wins. A running score is baseline. | LOW | Three numbers (X wins, O wins, draws) in HUD, updated via ScoreChangedEvent. |
| **Game-over result screen** | After win/draw, must show outcome clearly and offer next actions. | LOW | GameOverPanel with result text + "Play Again" + "Back to Menu" buttons. |
| **Restart / Play Again** | Most-played action after a game ends. Without it, user must relaunch. | LOW | Resets board state (GameManager.reset()), keeps score. |
| **Visual grid** (9 cells with X/O sprites) | This is the core game representation. Already exists. | LOW (DONE) | Line2D grid lines + Sprite2D for X/O marks. Already implemented. |
| **Game over prevention** (clicks ignored after game ends) | Critical UX — cells should not respond after game ends. | LOW | GameManager validates `state != PLAYING` and returns false. Already implemented. |

### Differentiators (Competitive Advantage)

Features that elevate from "basic" to "polished."

| Feature | Value Proposition | Complexity | Godot-Specific Notes |
|---------|-------------------|------------|----------------------|
| **Win line animation** (Tween-drawn stroke across winning row/col/diag) | Most satisfying visual feedback in tic-tac-toe. Transforms a static outcome into an event. | LOW-MEDIUM | Use `Line2D` with Tween to animate `width` from 0 to target, or animate `points[1]` from start to end of winning line. ~20-40 lines. |
| **Scene transitions** (fade in/out between menu and game) | Eliminates hard cuts. Feels cohesive and professional. | LOW | CanvasLayer (layer 100) + ColorRect + Tween on modulate.a. Simple Scene Switcher pattern. ~30 lines. |
| **Button hover animation** (scale + color on mouse enter/exit) | Micro-interaction that signals interactivity. Users subconsciously scan for these cues. | LOW | Tween `scale` to 1.1 + modulate tint on `mouse_entered`/`mouse_exited`. Attach to all interactive UI buttons. |
| **Cell hover highlight** (highlight empty cell on mouse enter) | Shows "this cell is clickable." Reduces indecision on where to click. | LOW | Cell already has `_highlight` Area2D child. Toggle visibility on `mouse_entered`/`mouse_exited` for empty cells. |
| **Place mark animation** (X/O appears with scale-up tween from 0 to 1) | Makes piece placement feel active rather than a static swap. | LOW-MEDIUM | Tween Sprite2D `scale` from 0 to 1 with overshoot (TransType.EASE_OUT_BACK). Trigger on CellPlacedEvent. ~15 lines. |
| **Background music** (separate tracks for menu and gameplay) | Sets mood. A game without BGM feels empty even if SFX are fine. | LOW | SoundManager.play_music() with crossfade. Two tracks: menu_theme + game_theme. |
| **Independent volume sliders** (SFX vs Music) | Users have strong preferences about music vs effects volume. Combined slider frustrates everyone. | LOW | Two HSlider controls → SoundManager.set_sfx_volume(linear) / set_music_volume(linear). ConfigFile persistence. |
| **Three AI difficulty levels** (Easy / Medium / Hard) | Replayability. One AI mode is boring after 2 games. Differentiated difficulty keeps players engaged. | MEDIUM | Minimax with alpha-beta pruning. Easy = random moves. Medium = minimax depth-3 + 30% random. Hard = full minimax (unbeatable). |
| **In-game language switch** (Chinese/English) | This is a bilingual project (context). Runtime switch without restart shows polish. | MEDIUM | CSV translation file → TranslationServer.set_locale(). auto_translate_mode on all Control nodes. CJK font fallback needed. |
| **AI "thinking" delay** (brief pause before AI moves) | Without delay, AI moves instantly — feels robotic. A 0.3-0.8s delay with random variation signals "thinking." | LOW | Timer with random wait time (0.3-0.8s) before executing AI move. Already partially implemented (GameManager has AI Timer at 0.3s). |
| **Move undo** (optional, if grid-derived) | Lets players recover from misclicks in PvP mode. Not expected in tic-tac-toe but appreciated. | MEDIUM | GameManager maintains move history stack. Pop on undo request. Complicates AI state on PvAI mode (only PvP undo). |
| **Settings persistence** (ConfigFile save/load for volume, language, AI difficulty) | Settings that reset every launch frustrate users. Persistence is the final polish step. | LOW | Use Godot's ConfigFile class. Save to `user://settings.cfg`. Load on game start. |
| **Menu music fade transition** (crossfade menu→gameplay music on scene start) | Smooth audio transition rather than abrupt stop/start. | LOW | SoundManager supports crossfade duration parameter on play_music(). Already a feature of the installed SoundManager plugin. |

### Anti-Features (Commonly Requested, Often Problematic)

Features that seem good but create problems for a small-scope tic-tac-toe game.

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| **Online multiplayer** | "Why can't I play with my friend remotely?" | Introduces networking stack, server/auth, latency handling, NAT traversal — 10x scope increase for marginal value in a casual board game. | Keep local PvP + PvAI. If remote play is needed later, use Godot's ENet/WebSocket, but not for v1. |
| **AI personality / emotional responses** | "The AI should trash talk or react emotionally." | Character AI is a rabbit hole. For tic-tac-toe, the AI state space is too small to create interesting personality through play style alone. | Three difficulty levels provide enough variety. Use animation/UI flair (e.g., thinking dots) instead. |
| **6x6 or 4x4 board modes** | "More variety, bigger challenge." | 3x3 tic-tac-toe is solved; the charm is simplicity. Larger grids lose the casual pickup-and-play feel and require different win conditions (4-in-a-row). | Stay with standard 3x3. Add Gomoku (5-in-a-row) as a separate game mode only if scope expands significantly. |
| **Scoreboard / win streak tracking** | "I want to track my record across sessions." | Persistent leaderboard adds save file management, data serialization, and UI for a trivial feature. Current session score tracking is sufficient. | In-session score only (P1 wins / P2 wins / draws). Session resets on back-to-menu. |
| **Customizable board themes / skins** | "I want different colors or themes." | Asset management overhead (multiple sprite sets, theme resources), UI for selection, persistence. Low value in a 720x720 game. | One clean visual theme. Polish that theme well rather than maintaining multiple. |
| **Sound effect customization** | "Let users pick their own click sound." | Asset picker UI, file management complexity, validation. The kenney_interface_sounds pack already has 100+ sounds — users don't need more choice. | Provide a good default set. Don't add sound selection UI. |
| **Tutorial / How to Play** | "New players might not know tic-tac-toe rules." | Tic-tac-toe is universally known. A tutorial screen wastes dev time and adds a UI step between launch and play. | If absolutely needed, a one-line tooltip "Get 3 in a row" is sufficient. |
| **Haptic feedback / controller vibration** | "More immersive on mobile." | Requires platform-specific APIs, testing on multiple devices. Low value for keyboard/mouse game. | Skip entirely. Not applicable to the current input model. |
| **Replay recording / playback** | "I want to watch the game again." | State serialization + playback system for a 9-move game. Massive complexity for a trivial feature. | Take a screenshot (Godot's `Image.get_data()`) if user wants to share. |
| **Achievements / badges** | "Steam achievements or Google Play Games." | Ties to external platforms. Requires platform accounts, achievement definition, API integration. Out of project scope. | Skip entirely. Out of scope per PROJECT.md. |

## Feature Dependencies

```
Main Menu UI
    ├──requires──> SceneManager (for menu→game→menu navigation)
    └──requires──> I18N registration (localized labels)

Game Settings Panel
    ├──requires──> Volume sliders
    │                 └──requires──> SoundManager + SFX/Music bus setup
    ├──requires──> AI difficulty selector
    │                 └──requires──> Minimax AI with 3 modes
    └──requires──> Language selector
                      └──requires──> CSV translation files + I18NManager

Sound System
    ├──requires──> SoundManager autoload (already registered)
    ├──requires──> Kenney audio resources (already in project)
    └──requires──> Audio bus setup (SFX, Music, UI buses)
                      └──requires──> AudioServer bus creation

Animated Win Line
    ├──requires──> Win detection (already implemented in GameManager)
    └──requires──> Line2D node with Tween reference

Cell Animations
    ├──requires──> CellPlacedEvent (already implemented)
    └──requires──> Sprite2D + Tween reference per cell

Scene Transitions
    ├──requires──> CanvasLayer overlay scene
    └──enhances──> All scene switches (menu↔game, menu↔settings)

AI Difficulty
    ├──requires──> Minimax algorithm core
    ├──requires──> Alpha-beta pruning (optimization)
    ├──enhances──> Medium mode (random chance mix)
    └──enhances──> Easy mode (random move selection)

EventBus Resource Path Refactor
    └──enhances──> All EventBus subscriptions (removes fragility)

Error Handling
    └──enhances──> All systems (adds push_error/push_warning guards)
```

### Dependency Notes

- **Settings Panel requires SoundManager setup:** Volume controls cannot work without AudioServer buses (Music/SFX) existing and SoundManager being wired to them. Must create buses in project settings before coding sliders.
- **AI Difficulty requires Minimax core:** All three levels derive from the same minimax engine. Easy = minimax disabled (random). Medium = minimax with depth limit + random injection. Hard = full minimax. You cannot implement difficulty without the base algorithm first.
- **Scene Transitions enhance all scene switches:** The fade overlay should be built once as an autoload or reusable node, then all navigation paths (menu->game, game->menu, menu->settings) use it. Add retroactively after one path is working.
- **Cell Animations depend on CellPlacedEvent:** The event already fires on placement. The animation layer simply subscribes and plays. No state changes needed — purely cosmetic.
- **EventBus Resource Path Refactor enhances everything:** Changing subscription from string paths to resource references or typed signals is a cross-cutting refactor. Best done early before too many subscribers exist.

## MVP Definition

### Launch With (v1) — Complete Polish

The core game is already functional. MVP for this milestone is "polish + completeness":

- [x] **Local PvP gameplay** — already implemented
- [x] **PvAI (basic AI)** — already implemented
- [x] **Win/draw detection** — already implemented
- [x] **Visual board with X/O sprites** — already implemented
- [x] **Cursor navigation (keyboard/controller)** — already implemented

- [ ] **Sound SFX** (place, win, lose, draw, button click) — highest-impact polish item
- [ ] **HUD** (current player indicator + score) — essential for playability
- [ ] **Game over panel** (result + play again + back to menu) — required for flow
- [ ] **Main Menu screen** (title, mode select, start button) — required for flow
- [ ] **Settings Panel** (volume controls, AI difficulty, language switch) — v1 polish

### Add After Validation (v1.x)

- [ ] **Minimax AI with 3 difficulty levels** — replaces basic AI, adds depth
- [ ] **Win line animation** — significant visual upgrade
- [ ] **Place mark animation** — micro-interaction polish
- [ ] **Scene transitions (fade in/out)** — eliminates hard cuts
- [ ] **Button hover feedback (scale/color)** — micro-interaction
- [ ] **Background music** (menu + gameplay) — atmosphere
- [ ] **Independent volume control** — user preference essential

### Future Consideration (v2+)

- [ ] **AI difficulty selector** (dropdown/buttons) — only needed when 3-tier AI exists
- [ ] **Move undo (PvP only)** — nice-to-have, not expected
- [ ] **Settings persistence** (ConfigFile save/load) — quality of life
- [ ] **EventBus resource path refactor** — maintenance quality, not user-facing
- [ ] **Error handling pass** (push_error/push_warning) — dev-facing quality
- [ ] **Cell hover highlight animation** — minor visual polish
- [ ] **Menu music crossfade** — audio polish refinement

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Current Status | Priority |
|---------|------------|---------------------|----------------|----------|
| Game SFX (place, win, lose, draw) | HIGH | LOW | SoundManager registered but unused | **P1** |
| Button click sounds | HIGH | LOW | Kenney assets in project, unused | **P1** |
| Main Menu screen | HIGH | MEDIUM | Does not exist (hardcoded) | **P1** |
| HUD (current player + score) | HIGH | LOW | Not implemented | **P1** |
| GameOverPanel (result + actions) | HIGH | LOW | Not implemented | **P1** |
| Settings panel (basic) | HIGH | MEDIUM | Does not exist | **P1** |
| Minimax 3-tier AI | HIGH | MEDIUM | Basic AI exists, needs replacement | **P1** |
| Win line animation | MEDIUM | LOW | Not implemented | **P2** |
| Place mark animation | MEDIUM | LOW | Not implemented | **P2** |
| Scene transitions | MEDIUM | LOW | Not implemented | **P2** |
| Button hover animation | MEDIUM | LOW | Not implemented | **P2** |
| Background music | MEDIUM | LOW | Not implemented | **P2** |
| Independent volume control | HIGH | LOW | Not implemented | **P2** |
| AI difficulty selector in settings | MEDIUM | LOW | Not implemented | **P2** |
| Language switch (Chinese/English) | HIGH | MEDIUM | I18NManager registered, no translation files | **P2** |
| Settings persistence | MEDIUM | LOW | Not implemented | **P3** |
| EventBus resource refactor | LOW (dev) | MEDIUM | Hardcoded paths exist | **P3** |
| Error handling pass | LOW (dev) | LOW | No push_error calls exist | **P3** |
| Cell hover highlight | LOW | LOW | Partially implemented | **P3** |
| Menu music crossfade | LOW | LOW | Not implemented | **P3** |
| Move undo (PvP) | LOW | MEDIUM | Not implemented | **P4** |

**Priority key:**
- P1: Must have for v1 polish milestone
- P2: Should have, completes the polished experience
- P3: Nice to have, quality-of-life or dev-facing
- P4: Future, defer unless time permits

## Sound Feature Breakdown

The SoundManager plugin is already registered but never called. The kenney_interface_sounds pack (100+ WAV files) is already in the project. This is all free polish.

### Required SFX

| Sound Event | Trigger | Suggested Asset | Notes |
|-------------|---------|-----------------|-------|
| Place mark | CellPlacedEvent | `click_01.wav` or `click_02.wav` | Short, satisfying click |
| Invalid move | CellPlacedEvent fails | `error_01.wav` | User clicks occupied cell |
| Win | GameWonEvent | `confirmation_01.wav` | Celebratory, distinct from place |
| Lose | GameWonEvent (AI wins) | `error_02.wav` | Different from win sound |
| Draw | GameDrawEvent | `blip_02.wav` | Neutral, soft sound |
| Button hover | mouse_entered | `hover_01.wav` | Subtle tick (optional, can be omitted) |
| Button click | pressed | `click_01.wav` | Same as place or slightly different |
| UI open/close | Panel open/close | `snap_01.wav` | For settings panel, game over |
| AI thinking (optional) | Timer start | none | Silence is fine; visual dots better |

### Background Music

| Context | Track | Behavior |
|---------|-------|----------|
| Main Menu | menu_theme (loop) | Play on menu open. Fade out on game start. |
| Gameplay | game_theme (loop) | Play on game start. Fade in after menu fade out. |
| Game Over | none (or short sting) | Silence or brief stinger. Do not loop BGM through result screen. |

### Audio Bus Architecture

The project needs 3 audio buses in the Audio tab:

```
Master
  ├── Music         (BGM tracks, volume controlled by music slider)
  ├── SFX           (place/win/lose/game sounds, volume controlled by sfx slider)
  └── UI            (button clicks, panel sounds — grouped with SFX or separate)
```

**Why 3 buses:** Allows players to mute BGM independently while keeping SFX audible. The UI bus is optional (can merge into SFX), but keeping them separate lets you mute game sounds while keeping UI click feedback.

## AI Difficulty Specification

### Easy Mode
- **Algorithm:** Random move selection from available empty cells
- **Behavior:** Often makes suboptimal choices. Humans can reliably beat it.
- **Implementation:** `empty_cells.pick_random()`
- **Thinking delay:** 0.5-1.0s random (longer "thinking" masks random behavior)

### Medium Mode
- **Algorithm:** Minimax with alpha-beta pruning, depth-limited to 3-4
- **Behavior:** Sees immediate threats (1-2 moves ahead), blocks obvious wins, sets up basic forks. Wins against careless players.
- **Implementation:** `minimax(board, depth=3, alpha, beta, maximizing)` + 20-30% random move injection
- **Random injection:** Roll `randf() < 0.3` before each move -- if true, pick random cell instead of optimal
- **Thinking delay:** 0.3-0.6s random

### Hard Mode
- **Algorithm:** Full minimax with alpha-beta pruning (complete search = 9! max)
- **Behavior:** Perfect play -- always wins if opponent errs, always draws if opponent plays perfectly
- **Implementation:** `minimax(board, depth=INF, alpha, beta, maximizing)` with full search
- **Tic-tac-toe state space:** Only 5478 valid game states. Full search completes in <1ms even in GDScript.
- **Thinking delay:** 0.2-0.4s (shorter delay signals competence, but not instant which feels robotic)

### Algorithm Notes
- Use **alpha-beta pruning** from the start. It dramatically reduces search space (from 9! to ~549 nodes on average for tic-tac-toe) at zero implementation cost beyond adding alpha/beta parameters.
- **Utility function:** +10 for AI win, -10 for human win, 0 for draw.
- **Board representation:** Array of ints (0=empty, 1=X, 2=O). Pass by reference, pass current player marker.
- **GDScript performance:** GDScript is slower than C# but tic-tac-toe state space is tiny. No performance concerns even without pruning.

## Multi-Language Specification

### Translation Setup
- **Format:** CSV with columns `keys, en, zh_CN`
- **Key naming convention:** `SCENE_COMPONENT_ACTION` (e.g., `MENU_START_GAME`, `HUD_CURRENT_TURN`, `RESULT_PLAYER_WINS`)
- **Storage:** `res://i18n/translations.csv`
- **Registration:** Godot auto-imports CSV → `.translation` files. Register in Project Settings → Localization.

### Required Translation Keys

| Key | English | Chinese (zh_CN) |
|-----|---------|----------------|
| `MENU_TITLE` | Tic-Tac-Toe | 井字棋 |
| `MENU_PVP` | Two Players | 双人对战 |
| `MENU_PVAI` | vs Computer | 人机对战 |
| `MENU_SETTINGS` | Settings | 设置 |
| `MENU_QUIT` | Quit | 退出 |
| `HUD_TURN` | Turn: {player} | 回合: {player} |
| `HUD_SCORE` | Score | 比分 |
| `RESULT_WIN` | {player} Wins! | {player} 获胜！ |
| `RESULT_DRAW` | Draw! | 平局！ |
| `RESULT_PLAY_AGAIN` | Play Again | 再来一局 |
| `RESULT_BACK_MENU` | Back to Menu | 返回菜单 |
| `SETTINGS_VOLUME_SFX` | Sound Effects | 音效 |
| `SETTINGS_VOLUME_MUSIC` | Music | 音乐 |
| `SETTINGS_DIFFICULTY` | AI Difficulty | AI 难度 |
| `SETTINGS_DIFFICULTY_EASY` | Easy | 简单 |
| `SETTINGS_DIFFICULTY_MEDIUM` | Medium | 中等 |
| `SETTINGS_DIFFICULTY_HARD` | Hard | 困难 |
| `SETTINGS_LANGUAGE` | Language | 语言 |
| `SETTINGS_LANG_EN` | English | English |
| `SETTINGS_LANG_ZH` | Chinese (中文) | 中文 |

### Font Requirements
- **Default font:** Must support Latin characters (for English)
- **Fallback font:** Must support CJK characters (for Chinese) — e.g., Noto Sans SC
- **Implementation:** Theme needs `font` + `fallback_fonts` array with a CJK-capable DynamicFont
- **Godot setting:** `ThemeDB.set_fallback_font()` for global fallback

### Runtime Switch
- I18NManager (from mc_game_framework) already handles `set_locale()` calls
- Ensure all Control nodes have `auto_translate_mode = AUTO` (default)
- For nodes where text is set in code (e.g., turn indicator), call `tr(key)` explicitly and update on `language_changed` signal

## Code Quality Features (Dev-Facing)

These are not user-visible but affect maintainability and reliability.

### Event Bus Subscription Refactor

**Current problem:** EventBus uses script path strings as event type identifiers:
```gdscript
EventBus.subscribe("res://scripts/events/cell_placed_event.gd", _on_cell_placed)
```

**Refactor options:**
1. **StringName constants** (low effort, partial fix)
   ```gdscript
   const CELL_PLACED = &"res://scripts/events/cell_placed_event.gd"
   EventBus.subscribe(CELL_PLACED, _on_cell_placed)
   ```
2. **Event class references** (medium effort, cleaner)
   ```gdscript
   EventBus.subscribe(CellPlacedEvent, _on_cell_placed)
   ```
   Requires EventBus to accept Resource/Class references as event type, not just strings.

3. **Typed signal bus** (higher effort, best)
   Migrate from string-keyed EventBus to a dedicated `GameEventBus` autoload with typed signals:
   ```gdscript
   signal cell_placed(cell_index: int, player: int)
   signal turn_changed(player: int)
   signal game_won(winner: int)
   ```
   This is the most maintainable but requires rewriting subscription patterns.

**Recommendation for scope:** Option 1 (StringName constants). Provides path-change safety for minimal effort. Option 3 if the team plans to expand the game significantly later.

### Error Handling Pattern

**Current state:** Zero `push_error`/`push_warning` calls in game scripts. Failures are silent.

**Add guards:**
- `GameManager.place_mark()`: `push_warning` if cell occupied or game not PLAYING
- `GameManager._find_best_move()`: `push_error` if no moves available on non-terminal board
- `Main._on_place_mark()`: `push_warning` if no cell hit by mouse
- All `preload()` calls: consider `load()` with null check instead
- Event parsing: validate event fields before use

**Pattern:**
```gdscript
func place_mark(cell_index: int) -> bool:
    if not _is_valid_cell(cell_index):
        push_warning("place_mark: invalid cell_index %d" % cell_index)
        return false
    if _board[cell_index] != CellState.EMPTY:
        push_warning("place_mark: cell %d already occupied" % cell_index)
        return false
    # ... normal flow
```

### Resource Path Hardcoding Audit

**Known hardcoded paths (** from ARCHITECTURE.md **):**
- `res://scripts/cell.gd:8-9` — X/O sprite textures
- `res://scripts/events/*.gd` — Event script paths in EventBus subscriptions
- `res://scenes/main.tscn` — Main scene path (implicit via project settings)
- `res://scripts/main.gd` — Various scene references

**Fix:** Use `@export` variables for scene/resource references. Assign in Inspector. Never use `preload("res://...")` for game-level assets.

## Sources

- **`tic-tac-godot`** by codystuart (Godot 4.4.1, GDScript) — Reference project with SoundManager, crossfade, win animation: https://github.com/codystuart/tic-tac-godot
- **Nathan Hoad SoundManager v2.6.2** — Installed plugin documentation: https://github.com/nathanhoad/godot_sound_manager
- **Kenney Interface Sounds** — CC0 UI sound pack (100+ WAVs) pre-installed: https://godotengine.org/asset-library/asset/794
- **Godot 4 Audio Bus documentation** — Volume control via AudioServer: https://docs.godotengine.org/en/4.0/tutorials/audio/audio_buses.html
- **Godot Tween class** — Animation system: https://docs.godotengine.org/en/4.0/classes/class_tween.html
- **Godot i18n / TranslationServer** — Multi-language support: https://docs.godotengine.org/en/4.0/tutorials/i18n/index.html
- **Godot GDScript EventBus patterns** — Subscription patterns: https://docs.godotengine.org/en/4.0/getting_started/scripting/gdscript/gdscript_basics.html#signals
- **StackOverflow: Godot 4 Minimax debugging** — Common implementation pitfalls: https://stackoverflow.com/questions/75778021/dumb-tictactoe-ai-godot-4-0
- **Godot UI architecture (Cursa)** — UI flow best practices: https://cursa.app/en/page/ui-hud-and-menus-with-control-nodes-in-godot-4
- **Godot scene transitions (CanvasLayer fade)** — Transition pattern: https://forum.godotengine.org/t/how-to-fade-in-out-canvaslayer-nodes/59542
- **Minimax alpha-beta pruning reference** — GeeksForGeeks (language-agnostic): https://www.geeksforgeeks.org/minimax-algorithm-in-game-theory/

---
*Feature research for: Tic-Tac-Toe polished board game (Godot 4.6)*
*Researched: 2026-06-17*
