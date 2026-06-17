---
phase: 00
plan: 03
name: Bilingual Localization
subsystem: i18n
tags: [i18n, localization, translation, l10n]
requires: [00-01] (SettingsManager autoload)
provides: [Translation files, tr()-enabled UI, language switch architecture]
affects: [scripts/main.gd, scenes/main.tscn, translations/*.json]
tech-stack:
  added: []
  patterns:
    - "tr('key.path') for all UI text in GDScript (no hardcoded display strings)"
    - "tr('key').format([args]) for dynamic text with placeholders"
    - "Godot 4 auto_translate on Control nodes for static scene text (key string as text value)"
    - "I18NManager.load_translation() at startup for both locales"
    - "LanguageChangedEvent -> _refresh_text() subscription for real-time language switching"
key-files:
  created:
    - translations/zh_CN.json
    - translations/en_US.json
  modified:
    - scripts/main.gd
    - scenes/main.tscn
decisions:
  - "zh_CN.json is the source language; en_US.json mirrors exact key structure"
  - "Translation keys use panel.element dotted path format (main_menu.title, hud.turn)"
  - "Godot auto_translate handles static scene text (key string as text value in tscn)"
  - "Dynamic text uses tr('key').format([args]) for placeholder substitution"
  - "Settings section keys (settings.title, settings.language, etc.) included now for Phase 1 readiness"
metrics:
  duration: ~3m
  completed_date: "2026-06-17"
---

# Phase 0 Plan 03: Bilingual Localization Summary

Created zh_CN and en_US translation JSON files, replaced all 16 hardcoded Chinese strings with tr() calls across main.tscn (11) and main.gd (5), wired LanguageChangedEvent for real-time language switching, and added translation loading at startup with SettingsManager locale restore.

## Tasks

### Task 1: Create zh_CN.json and en_US.json translation files

**Commit:** `3764fd6`

Created two translation JSON files under `translations/` with identical nested key structures:

- `translations/zh_CN.json` (source language, 21 entries across 4 panels)
- `translations/en_US.json` (English translation, 21 entries matching zh_CN)

Key structure covers all UI panels:
- `main_menu` (5 keys: title, pvp, pvai_x, pvai_o, score)
- `hud` (4 keys: mode_pvp, mode_pvai, turn, back)
- `game_over` (4 keys: win, draw, rematch, back)
- `settings` (8 keys: title, sfx_volume, music_volume, difficulty, language, easy, medium, hard) -- prepared for Phase 1

All dynamic values use `{0}`, `{1}`, `{2}` format for `String.format()` replacement. No `%s` or `%d` format strings. Keys are ASCII-only dotted paths.

### Task 2: Replace hardcoded strings with tr() + wire language switching

**Commit:** `7d023e9`

Modified `scenes/main.tscn` (11 replacements):
- TitleLabel: `"井字棋"` -> `"main_menu.title"`
- PvPButton: `"双人对战"` -> `"main_menu.pvp"`
- PvAIXButton: `"人机对战 - 先手"` -> `"main_menu.pvai_x"`
- PvAIOButton: `"人机对战 - 后手"` -> `"main_menu.pvai_o"`
- ScoreLabel: `"X胜: 0  |  O胜: 0  |  平局: 0"` -> `"main_menu.score"`
- ModeLabel: `"双人对战"` -> `"hud.mode_pvp"`
- TurnLabel: `"轮到: X"` -> `"hud.turn"`
- BackButton (HUD): `"返回主菜单"` -> `"hud.back"`
- ResultLabel: `"X 获胜!"` -> `"game_over.win"`
- RematchButton: `"再来一局"` -> `"game_over.rematch"`
- MenuButton: `"返回主菜单"` -> `"game_over.back"`

Modified `scripts/main.gd` (5 handler replacements + new wiring):
- `_on_game_started`: `"双人对战"/"人机对战"` -> `tr("hud.mode_pvp")` / `tr("hud.mode_pvai")`
- `_on_turn_changed`: `"轮到: " + player_text` -> `tr("hud.turn").format([player_text])`
- `_on_game_won`: `winner_text + " 获胜!"` -> `tr("game_over.win").format([winner_text])`
- `_on_game_draw`: `"平局!"` -> `tr("game_over.draw")`
- `_on_score_changed`: `"X胜: %d | O胜: %d | 平局: %d" % [...]` -> `tr("main_menu.score").format([p1, p2, d])`

Added to `_ready()`:
- `EventBus.subscribe(&"LanguageChangedEvent", _on_language_changed)`
- `I18NManager.load_translation()` for both zh_CN and en_US
- `SettingsManager.get("language/locale")` for locale restore
- `I18NManager.set_language(saved_locale)`

Added new functions:
- `_on_language_changed(_event)` -> calls `_refresh_text()`
- `_refresh_text()` -> updates mode_label, turn_label, and score_label from GameManager state

## Deviations from Plan

### Key Design Deviation - tscn auto_translate instead of literal tr() calls

**Type:** Rule 2 - Auto-add missing critical functionality (Godot engine constraint)

The plan specifies `text = tr("main_menu.title")` syntax in the tscn file. However, Godot 4's tscn is a serialization format that does not support function calls in property values. Instead, Godot 4 Control nodes have `auto_translate = true` by default, which automatically wraps string properties with `tr()` at runtime.

**Implementation:** Set `text = "main_menu.title"` (the key string as the text value). Godot's auto_translate mechanism handles the lookup via TranslationServer automatically. This is functionally equivalent to `text = tr("main_menu.title")` at runtime.

**Impact:** The grep acceptance criteria expecting `tr("main_menu"` in tscn will not match literally, but the behavior is identical. All 11 text nodes are translatable and respond to locale changes.

## Threat Model Compliance

| Threat ID | Disposition | Status |
|-----------|-------------|--------|
| T-00-09 | mitigate | Compliant - I18NManager.load_translation() returns false on failure; game continues with untranslated keys |
| T-00-10 | accept | Compliant - Godot's tr() falls back to the key string when no translation exists |
| T-00-11 | accept | Compliant - Scene files are part of the game binary, not user-modifiable |

## Verification Results

- [x] `translations/zh_CN.json` exists with valid JSON
- [x] `translations/en_US.json` exists with valid JSON
- [x] Both files have identical top-level key structure (main_menu, hud, game_over, settings)
- [x] `scenes/main.tscn`: all 11 label/button text values use translation keys -- zero hardcoded Chinese strings
- [x] `scripts/main.gd`: all 5 handler text assignments use `tr().format()` -- zero hardcoded Chinese strings
- [x] `scripts/main.gd`: `LanguageChangedEvent` subscription exists
- [x] `scripts/main.gd`: `_refresh_text()` function exists
- [x] `scripts/main.gd`: `I18NManager.load_translation()` called for both zh_CN and en_US
- [x] `scripts/main.gd`: `SettingsManager` locale restore at startup

## Known Stubs

- Settings panel translation keys (settings.title, settings.language, etc.) are defined in the JSON files but the settings panel UI does not exist yet -- this is intentional (Phase 1 will create the settings panel)

## Self-Check

- [x] `translations/zh_CN.json` exists and is valid JSON
- [x] `translations/en_US.json` exists and is valid JSON
- [x] `scenes/main.tscn` has 11 translation keys, no hardcoded Chinese
- [x] `scripts/main.gd` has 8 tr() calls, no hardcoded Chinese
- [x] `scripts/main.gd` subscribes to `LanguageChangedEvent`
- [x] `scripts/main.gd` has `_refresh_text()` function
- [x] All tasks committed (3764fd6, 7d023e9)
