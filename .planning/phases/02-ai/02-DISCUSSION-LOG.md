# Phase 2: AI - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-17
**Phase:** 02-AI
**Areas discussed:** Alpha-beta pruning strategy, AI thinking delay & feedback

---

## Alpha-Beta Pruning Strategy

| Option | Description | Selected |
|--------|-------------|----------|
| Full replace | Rewrite `_minimax()` with alpha-beta pruning, remove old implementation | ✓ |
| Add alongside | Keep old `_minimax()`, add new `_minimax_ab()` | |

**User's choice:** Full replace — rewrite the existing function with alpha-beta, no backward compatibility needed.

---

| Option | Description | Selected |
|--------|-------------|----------|
| Perfect play | Hard difficulty searches full tree with alpha-beta, never loses | ✓ |
| Near-perfect with randomness | Hard plays optimally ~95% of the time, occasional random move | |

**User's choice:** Perfect play on Hard — the aspirational target for players. "Can you force a draw?"

---

| Option | Description | Selected |
|--------|-------------|----------|
| Parameterized | Single `_minimax(alpha, beta, depth, max_depth, random_chance)` serves all difficulties | ✓ |
| Separate strategies | `_minimax_hard()` / `_minimax_medium()` / `_random_easy()` three independent functions | |

**User's choice:** Parameterized — one function, difficulty expressed through parameters.

---

## AI Thinking Delay & Feedback

| Option | Description | Selected |
|--------|-------------|----------|
| Random in range | Each move's delay randomly chosen within difficulty range | ✓ |
| Fixed per difficulty | One fixed delay per difficulty level | |

**User's choice:** Random in range — avoids mechanical feel on repeated play.

---

| Option | Description | Selected |
|--------|-------------|----------|
| HUD indicator | Show "AI 思考中..." via tr() in HUD during delay | ✓ |
| Timer only | Just wait silently, no visual feedback | |

**User's choice:** HUD indicator — bilingual text showing AI thinking state.

---

| Option | Description | Selected |
|--------|-------------|----------|
| Keep Timer | Continue using existing ai_timer node | ✓ |
| await create_timer | Use Godot await coroutine instead of Timer | |

**User's choice:** Keep Timer — minimal change, already working.

---

| Option | Description | Selected |
|--------|-------------|----------|
| New event | `AiThinkingEvent(thinking: bool)` published on delay start/end | ✓ |
| Read GameManager state | HUD polls `is_ai_thinking` in _process | |

**User's choice:** New event — consistent with existing EventBus-driven architecture.

---

## Claude's Discretion

- Easy difficulty: exact behavior (pure random, weighted random, or depth-1 minimax)
- Medium difficulty: exact depth cap and random injection rate
- Delay randomization distribution within ranges
- HUD indicator exact wording, placement, and style
- `_evaluate()` heuristic for depth-limited search scoring

## Deferred Ideas

None — discussion stayed within phase scope.
