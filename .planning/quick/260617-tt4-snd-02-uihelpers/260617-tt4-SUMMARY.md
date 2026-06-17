---
quick_id: 260617-tt4
slug: snd-02-uihelpers
description: "修复 SND-02：按钮音效未连接到 UIHelpers"
date: 2026-06-17
status: complete
commit: pending
files_modified:
  - scripts/utils/ui_helpers.gd
  - .planning/v1.0-MILESTONE-AUDIT.md
---

# Quick Task 260617-tt4: Summary

**Status:** complete

## What Changed

Wired `AudioController.play_button_hover()` and `AudioController.play_button_click()` into `UIHelpers.setup_button_animation()`:

- `mouse_entered` callback: added `AudioController.play_button_hover()` before visual tween
- `button_down` callback: added `AudioController.play_button_click()` before visual tween

Both methods are safe to call — they have internal null-checks for sound resources.

MILESTONE-AUDIT.md updated: SND-02 now satisfied, status → passed (29/29).
