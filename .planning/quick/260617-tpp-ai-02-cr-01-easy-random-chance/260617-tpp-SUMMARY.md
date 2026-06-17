---
quick_id: 260617-tpp
slug: ai-02-cr-01-easy-random-chance
description: "修复 AI-02 CR-01：Easy 难度 random_chance 从未生效"
date: 2026-06-17
status: complete
commit: d789170
files_modified:
  - autoload/game_manager.gd
  - test/test_game_manager.gd
  - scripts/panels/hud.gd
  - scripts/panels/game_over.gd
  - scripts/panels/main_menu.gd
  - scripts/panels/pause_menu.gd
  - project.godot
  - .planning/phases/02-ai/02-VERIFICATION.md
  - .planning/v1.0-MILESTONE-AUDIT.md
---

# Quick Task 260617-tpp: Summary

**Status:** complete

## What Changed

3 gaps from 02-VERIFICATION.md closed in one commit:

1. **CR-01 (BUG):** Reordered the `random_chance` check before `depth >= max_depth` cutoff in `_minimax()`. Easy difficulty (max_depth=1) now evaluates `random_chance=0.8` first, so 80% of minimax calls return early with random evaluation. Previously, the depth cutoff always fired first, making random_chance dead code.

2. **WR-02 (Code Quality):** All 4 event handlers in `hud.gd` now use typed property access (`event.player`, `event.p1_score`, `event.draw_score`, `event.mode`, `event.thinking`) instead of dynamic `.get("property")`.

3. **WR-03 (Code Quality):** All 4 UIPanel subclasses (`hud.gd`, `game_over.gd`, `main_menu.gd`, `pause_menu.gd`) now call `super._on_destroy()` at the start of `_on_destroy()`.

Additionally:
- `test_ai_easy_random` updated to validate move diversity across 100 trials (instead of checking suboptimality count)
- AudioController re-enabled in `project.godot` autoload
- 02-VERIFICATION.md updated: `gaps_found` → `passed`, gaps list removed
- v1.0-MILESTONE-AUDIT.md updated: AI-02 now satisfied, status → `tech_debt`
