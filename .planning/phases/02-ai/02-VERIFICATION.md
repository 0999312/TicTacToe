---
phase: 02-ai
verified: 2026-06-17T13:30:00Z
status: gaps_found
score: 6/6 must-haves verified (1 with significant note)
overrides_applied: 0
gaps:
  - truth: "AI uses random_chance for Easy difficulty imperfect play"
    status: failed
    reason: "In _minimax(), the 'depth >= max_depth' check (line 259) executes BEFORE the 'random_chance' check (line 262). On Easy (max_depth=1), every call with depth=1 immediately returns _evaluate() via the depth cutoff, so random_chance=0.8 is NEVER evaluated. Easy plays deterministic depth-1 heuristic instead of 80% random play. This was documented in the code review as CR-01 and remains unfixed."
    artifacts:
      - path: "autoload/game_manager.gd"
        issue: "_minimax() depth check at line 259 short-circuits before random_chance check at line 262"
    missing:
      - "Move random_chance check before the depth check in _minimax(), or apply random move injection at the _find_best_move() level"
  - truth: "WR-02: Event property access uses .get() instead of typed property access (hud.gd lines 61, 67-69, 76, 82)"
    status: warning
    reason: "All event handlers in hud.gd use event.get('property') instead of direct typed property access. This can mask typos or API mismatches. Not a functional blocker but a code quality concern."
    artifacts:
      - path: "scripts/panels/hud.gd"
        issue: "_on_ai_thinking uses event.get('thinking') instead of event.thinking"
  - truth: "WR-03: _on_destroy does not chain to parent class"
    status: warning
    reason: "hud.gd overrides _on_destroy() without calling super()._on_destroy(). If UIPanel has cleanup logic in the parent class, it will not execute."
    artifacts:
      - path: "scripts/panels/hud.gd"
        issue: "Missing super()._on_destroy() call"
---

# Phase 2: AI -- Verification Report

**Phase Goal:** Smart opponent with three-tier difficulty stands as the polished final challenge
**Verified:** 2026-06-17T13:30:00Z
**Status:** gaps_found
**Re-verification:** No -- initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Player can select Easy/Medium/Hard difficulty and observe distinctly different AI play quality | VERIFIED (with gap) | Settings panel has difficulty buttons (settings.gd lines 41-43); AI uses different parameters per tier: Easy depth=1, Medium depth=4+0.15 random, Hard depth=9 perfect. Tiers ARE observably distinct. **However:** Easy random_chance=0.8 is NEVER applied (see CR-01 below). Easy plays deterministic depth-1 heuristic instead of 80% random. |
| 2 | AI uses Minimax with alpha-beta pruning for optimal move selection | VERIFIED | game_manager.gd _minimax() at line 253 implements full alpha-beta pruning with min/max branches, alpha-beta comparisons, and return-on-cutoff pattern at lines 274 and 287. |
| 3 | AI shows thinking delays appropriate to difficulty level (Easy 0.5-1.0s, Medium 0.3-0.6s, Hard 0.2-0.4s) | VERIFIED | _get_ai_delay() at lines 179-188 implements exact ranges: EASY randf_range(0.5, 1.0), MEDIUM randf_range(0.3, 0.6), HARD randf_range(0.2, 0.4). Randomization is uniform within each range. |
| 4 | HUD displays "AI thinking..." / "AI 思考中..." during AI's turn | VERIFIED | ThinkingLabel in hud.tscn (line 54-60) with gold/amber modulate, text="hud.ai_thinking", visible=false default; zh_CN.json has "ai_thinking": "AI 思考中..."; en_US.json has "ai_thinking": "AI thinking..."; hud.gd subscribes to AiThinkingEvent and toggles visibility (line 81-83). call_deferred timer start (line 176) prevents race condition where 0.2s Hard delay hides indicator. |
| 5 | AI difficulty selection persists across sessions via ConfigFile | VERIFIED | SettingsManager uses ConfigFile at user://settings.cfg (settings_manager.gd line 8), saves on panel close (settings.gd line 87), loads on startup. Difficulty stored as "gameplay/difficulty" key; default is 1 (Medium) from settings_manager.gd line 5. Phase 0 infrastructure handles this. |
| 6 | Hard difficulty AI is undefeatable (perfect play) | VERIFIED | Hard uses max_depth=9, random_chance=0.0 (lines 212-214). Full alpha-beta minimax search on 3x3 board where full search is tractable (max ~549,945 nodes, pruning reduces to ~2,435). Test test_ai_hard_perfect verifies blocking behavior. |

**Score:** 6/6 truths verified (1 with noted gap)

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `autoload/game_manager.gd` | AI engine with alpha-beta pruning, difficulty param, thinking delays, AiThinkingEvent publishing | VERIFIED | 316 lines. Full alpha-beta minimax with parameterized difficulty, call_deferred timer start, stale timer guards. |
| `scripts/events/ai_thinking_event.gd` | AiThinkingEvent class with thinking: bool field | VERIFIED | 8 lines. Extends Event, class_name AiThinkingEvent, thinking: bool, _init(p_thinking: bool). Follows Phase 0 event convention. |
| `scripts/panels/hud.gd` | HUD thinking indicator subscriber and handler | VERIFIED | 84 lines. @onready thinking_label, AiThinkingEvent subscribe/unsubscribe, _on_ai_thinking handler toggles visible. |
| `scenes/panels/hud.tscn` | ThinkingLabel node in HUD scene | VERIFIED | Label at VBoxContainer/HBoxContainer/CenterVBox/ThinkingLabel, gold modulate Color(0.91, 0.72, 0.29, 1), text="hud.ai_thinking", visible=false. |
| `translations/zh_CN.json` | Chinese AI thinking label translation | VERIFIED | "ai_thinking": "AI 思考中..." under "hud" section. |
| `translations/en_US.json` | English AI thinking label translation | VERIFIED | "ai_thinking": "AI thinking..." under "hud" section. |
| `test/test_game_manager.gd` | Updated and new AI tests for parameterized minimax | VERIFIED | 118 lines. 6 AI tests: test_ai_first_move_center, test_ai_blocks_win, test_ai_takes_win, test_ai_hard_perfect, test_ai_easy_random, test_ai_medium_blocks. **Note:** test_ai_easy_random passes for wrong reason (heuristic happens to be suboptimal, not because of random_chance). |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| _schedule_ai_move | AiThinkingEvent | EventBus.publish(AiThinkingEvent.new(true)) | WIRED | Line 173: `EventBus.publish(AiThinkingEvent.new(true))` before timer start |
| _do_ai_move | AiThinkingEvent | EventBus.publish(AiThinkingEvent.new(false)) | WIRED | Line 221: `EventBus.publish(AiThinkingEvent.new(false))` after place_mark() |
| _find_best_move | SettingsManager | Difficulty parameters passed from _do_ai_move | PARTIAL | Difficulty is read from SettingsManager in _do_ai_move (line 202) and passed as parameters to _find_best_move, rather than _find_best_move calling SettingsManager directly. Functionally equivalent and architecturally cleaner. |
| _on_ai_thinking | thinking_label | visibility toggle | WIRED | Line 83: `thinking_label.visible = is_thinking` |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|--------------|--------|-------------------|--------|
| hud.gd thinking_label | thinking_label.visible | AiThinkingEvent.thinking | YES -- published by GameManager in real AI turn cycle | FLOWING |
| game_manager.gd AI parameters | difficulty | SettingsManager.get_value("gameplay/difficulty") | YES -- persisted via ConfigFile, set by settings panel UI | FLOWING |

### Behavioral Spot-Checks

Step 7b: SKIPPED (no runnable entry points -- Godot headless test runner requires engine environment not available in this shell).

### Probe Execution

No probes defined for this phase. PLAN.md and SUMMARY.md declare no probe scripts. SKIPPED.

### Requirements Coverage

The REQUIREMENTS.md traceability table still shows AI-01 through AI-04 as "Pending" status. This is a documentation tracking gap in REQUIREMENTS.md, not a code gap -- all 4 requirements are satisfied in the implementation.

| Requirement | Source Plan | Description | Status | Evidence |
|------------|------------|-------------|--------|----------|
| AI-01 | 02-01-PLAN | Minimax algorithm with alpha-beta pruning | SATISFIED | _minimax() at game_manager.gd:253 with alpha/beta params, return-on-cutoff, min/max branches |
| AI-02 | 02-01-PLAN | Three difficulty tiers -- Easy (random), Medium (depth-limited + random), Hard (full search) | SATISFIED (with gap) | Three tiers implemented with different max_depth/random_chance. **Gap:** Easy random_chance never applied (CR-01). |
| AI-03 | 02-01-PLAN | Differentiated thinking delay + HUD indicator | SATISFIED | _get_ai_delay() with difficulty ranges, AiThinkingEvent, ThinkingLabel in HUD |
| AI-04 | 02-01-PLAN | Settings panel AI difficulty selector | SATISFIED | settings.gd has difficulty buttons (Easy/Medium/Hard) that set SettingsManager value, persisted via ConfigFile |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| autoload/game_manager.gd | 259-262 | depth check before random_chance check | HIGH | EASY random_chance=0.8 never evaluated. Easy plays deterministic depth-1 heuristic instead of 80% random. See CR-01. |
| scripts/panels/hud.gd | 82 | event.get("thinking") instead of event.thinking | LOW | Uses dynamic .get() instead of typed property access. Masks typos, loses compile-time safety. |
| scripts/panels/hud.gd | 26 | Missing super()._on_destroy() call | LOW | If UIPanel has cleanup logic in parent class, it won't execute for HUD instances. |

### Human Verification Required

None. All checks are programmatically verifiable.

### Gaps Summary

**Gap 1 (CR-01 -- Bug):** The `random_chance` parameter has NO EFFECT on EASY difficulty because the `depth >= max_depth` check in `_minimax()` (line 259) executes BEFORE the `random_chance` check (line 262). On Easy with `max_depth=1`, every minimax call enters with `depth=1`, immediately triggering the depth cutoff at line 259 and returning `_evaluate()` at line 260, never reaching line 262.

**Consequence:** Easy plays deterministic depth-1 heuristic instead of the intended "80% random, 20% depth-1 smart" behavior. This means:
- Easy always makes the same choices for a given board state (no variability between games)
- The `test_ai_easy_random` test passes for the wrong reason (the heuristic happens to produce suboptimal choices for the test board state, not because of random_chance)
- The `random_chance=0.8` parameter is effectively dead code for Easy

**Fix (as documented in code review CR-01):** Move the random_chance check before the depth check in `_minimax()`, or apply random move injection at the `_find_best_move()` level. Either approach ensures randomness is applied before the depth cutoff short-circuits.

**Gap 2 (WR-02 -- Code Quality):** Event property access in `hud.gd` uses `event.get("property")` instead of direct typed property access (`event.property`). For the AiThinkingEvent handler specifically, line 82 uses `event.get("thinking")` instead of `event.thinking`. This is consistent with existing codebase patterns but loses compile-time validation.

**Gap 3 (WR-03 -- Code Quality):** `hud.gd._on_destroy()` overrides the parent class method without calling `super()._on_destroy()`. If UIPanel's `_on_destroy()` performs essential cleanup, it will not execute.

---

_Verified: 2026-06-17T13:30:00Z_
_Verifier: Claude (gsd-verifier)_
