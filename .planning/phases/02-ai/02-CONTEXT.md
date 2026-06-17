# Phase 2: AI - Context

**Gathered:** 2026-06-17
**Status:** Ready for planning

<domain>
## Phase Boundary

Upgrade the existing basic Minimax AI (`game_manager.gd:177-217`) to a polished three-tier AI system with alpha-beta pruning, differentiated difficulty behaviors, randomized thinking delays, and HUD feedback. Difficulty persists via SettingsManager (Phase 0 infrastructure), difficulty selector already exists in Settings panel (Phase 1 UI). This is the final phase — no downstream work depends on it.

</domain>

<decisions>
## Implementation Decisions

### Alpha-Beta Pruning Strategy
- **D-01:** Full replace — rewrite `_minimax()` with alpha-beta pruning. Old `_minimax()` removed entirely. No backward compatibility shim needed.
- **D-02:** Hard difficulty = perfect play. Full search with alpha-beta pruning, AI never loses. This is the selling point: "Can you force a draw against a perfect opponent?"
- **D-03:** Single parameterized function `_minimax(is_maximizing: bool, depth: int, alpha: int, beta: int, max_depth: int, random_chance: float) -> int`. Same function serves all three difficulties via parameter variation. `_find_best_move()` reads difficulty from SettingsManager and passes appropriate `max_depth` and `random_chance`.

### AI Thinking Delay & Feedback
- **D-04:** Random delay within difficulty range — each move's delay is randomly chosen within the range. Ranges from ROADMAP: Easy 0.5-1.0s, Medium 0.3-0.6s, Hard 0.2-0.4s. Randomization avoids mechanical feel on repeated play.
- **D-05:** HUD shows "AI 思考中..." (Chinese) / "AI thinking..." (English) during the AI delay. Uses `tr()` for bilingual support, subscribes to `LanguageChangedEvent` for real-time text refresh.
- **D-06:** Keep existing `ai_timer` Timer node for delay implementation. No migration to `await`. The Timer + signal pattern already works and is well-understood.
- **D-07:** New `AiThinkingEvent` — class_name `AiThinkingEvent` with field `thinking: bool`. Published by GameManager on delay start (`true`) and after `place_mark()` completes (`false`). HUD subscribes to toggle the thinking indicator. Follows Phase 0 event pattern (D-01 to D-04 from 00-CONTEXT.md).

### Claude's Discretion
- Easy difficulty exact behavior — pure random, weighted random (center/corner preference), or depth-1 minimax
- Medium difficulty exact parameters — depth cap (suggest 2-4) and random injection rate (suggest 10-20%)
- Exact randomization distribution for delays (uniform within range)
- HUD indicator exact placement, style, and animation (if any)
- `_evaluate()` heuristic for depth-limited search — board position scoring when search is truncated
- Whether to publish `AiThinkingEvent` before the delay starts or simultaneously with timer start

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project Planning
- `.planning/ROADMAP.md` — Phase 2 scope, success criteria (AI-01 to AI-04)
- `.planning/REQUIREMENTS.md` — AI-01 (Minimax + alpha-beta), AI-02 (three tiers), AI-03 (thinking delays), AI-04 (difficulty persistence)
- `.planning/PROJECT.md` — Constraints (GDScript only, EventBus SSOT, no new addons)

### Prior Phase Context
- `.planning/phases/00-foundation-sound-localization/00-CONTEXT.md` — D-15/D-16: SettingsManager API (`get_value`/`set_value`), ConfigFile `[gameplay].difficulty`, default=1 (Medium); D-04: Event system refactoring (class_name events, no hardcoded paths); D-06: AudioController already handles game event → sound mapping
- `.planning/phases/01-ui-animations/01-CONTEXT.md` — D-17: AI difficulty selector already built (three side-by-side buttons in Settings panel); D-19: Settings apply instantly, persist on panel close

### Codebase Maps
- `.planning/codebase/ARCHITECTURE.md` — GameManager SSOT, EventBus communication pattern, autoload chain
- `.planning/codebase/CONVENTIONS.md` — Naming (_on_ handlers, _make_ factories), typing conventions, event class patterns

### Source Code (read before implementing)
- `autoload/game_manager.gd` — Current AI in `_find_best_move()` (line 177-191) and `_minimax()` (line 194-217). Board state, turn logic, `_check_winner()`, `_is_board_full()`, `place_mark()` all live here.
- `autoload/settings_manager.gd` — `get_value(key: String)` / `set_value(key: String, value: Variant)` API
- `scripts/panels/hud.gd` — HUD panel for adding thinking indicator
- `scripts/events/` — Existing event class patterns for creating new `AiThinkingEvent`

### Settings
- `resources/default_settings.tres` — Default difficulty value
- `user://settings.cfg` — Runtime persistence, `[gameplay]` section, `difficulty` key

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **GameManager AI foundation:** `_minimax()` (line 194-217) and `_find_best_move()` (line 177-191) already implement Minimax without pruning. `ai_timer` node exists. `ai_player: int` tracks which side the AI plays. All in `game_manager.gd`.
- **SettingsManager:** `get_value("difficulty")` returns the persisted difficulty (0=Easy, 1=Medium, 2=Hard). Settings panel already writes this value. No new persistence code needed.
- **EventBus:** Phase 0 refactoring means new events use `class_name` and `EventBus.publish(EventClass.new(...))`. `AiThinkingEvent` follows this established pattern.
- **HUD:** Already subscribes to game events and uses `tr()`. Adding thinking indicator is extending existing subscription list.
- **Translation files:** `resources/translations/zh_CN.json` and `en_US.json` — add `ai_thinking` key for the indicator text.

### Established Patterns
- **Event-driven AI flow:** GameManager detects AI turn → schedules timer → places mark → publishes `CellPlacedEvent`. New flow: detect AI turn → publish `AiThinkingEvent(true)` → schedule randomized timer → place mark → publish `AiThinkingEvent(false)` + `CellPlacedEvent`.
- **Timer-based async:** AI delay uses Godot Timer node with `one_shot = true`. Connected to `_do_ai_move()` via signal.
- **`_on_` handler naming:** HUD handler for `AiThinkingEvent` follows `_on_ai_thinking()` convention.
- **SSOT pattern:** All game state stays in GameManager. HUD is view-only, reads nothing from GameManager during thinking — it just reacts to the event.

### Integration Points
- **GameManager._schedule_ai_move():** Current entry point for AI turn (line 167). Add delay randomization and `AiThinkingEvent` publish here.
- **GameManager._do_ai_move():** Current move executor (line 171). Add `AiThinkingEvent(false)` publish after `place_mark()`.
- **SettingsManager → GameManager:** `_find_best_move()` reads `SettingsManager.get_value("difficulty")` to determine `max_depth` and `random_chance` parameters.
- **HUD → AiThinkingEvent:** HUD subscribes in `_ready()` via `EventBus.subscribe(&"AiThinkingEvent", _on_ai_thinking)`. Shows/hides thinking indicator based on `thinking` field.
- **Translation files:** Add `hud.ai_thinking` key to both zh_CN.json and en_US.json.

</code_context>

<specifics>
## Specific Ideas

- User confirmed: alpha-beta pruning should fully replace the existing minimax — no backward compatibility, no dual implementations
- User confirmed: Hard AI should be undefeatable (perfect play). This is the aspirational target for players.
- User confirmed: HUD feedback during AI thinking is important enough to add a new event type rather than polling GameManager state
- Easy/Medium difficulty behavior left to Claude's discretion — user chose not to discuss these areas

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 02-AI*
*Context gathered: 2026-06-17*
