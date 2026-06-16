---
phase: 00
slug: foundation-sound-localization
status: draft
tool: none (Godot 4.6)
created: 2026-06-17
---

# Phase 00 — UI Design Contract

> Visual and interaction contract for infrastructure phase (Foundation, Sound, Localization).
> This is NOT a UI panel design phase — no new scenes or Control nodes are added. The contract covers design tokens, audio feedback, and copywriting contracts that Phase 1 panels will inherit.

---

## Design System

| Property | Value | Source |
|----------|-------|--------|
| Engine | Godot 4.6 | project.godot |
| Viewport | 720x720, canvas_items stretch | project.godot |
| Component library | Godot Control nodes (Label, Button, Panel) | Existing main.tscn |
| Icon library | None (grid piece sprites are SVG: x_mark.svg, o_mark.svg, highlight_square.svg) | Existing assets |
| Font | MiSans-Semibold (8MB .ttf at `fonts/MiSans-Semibold.ttf`) | D-23 |
| Theme | Global Theme resource at `res://resources/theme/default_theme.tres` | D-23 |
| UI framework | UIManager available but NOT used in Phase 0 — manual `_show_only()` stays | D-24 (defer to Phase 1) |

---

## Spacing Scale

Godot Control nodes use pixel values in a 720x720 viewport. Spacing values from existing scene, declared for Phase 1 consumption:

| Token | Value | Usage | Existing Example |
|-------|-------|-------|------------------|
| xs | 4px | Tight element internal padding | GridLine2D width |
| sm | 8px | Compact separation | (reserved for Phase 1) |
| md | 15-20px | Default VBoxContainer separation | GameOverPanel separation=15, MainMenu separation=20 |
| lg | 24px | Section spacing | (reserved for Phase 1) |
| xl | 32px | Major gaps between element groups | (reserved for Phase 1) |
| 2xl | 48px | Grid cell size (160px cell / 3.33) | Cell CollisionShape2D 160x160 |
| grid | 200px | Board cell pitch (center-to-center) | Cell0 at (160,160), Cell1 at (360,160) |

**Spacing baseline:** All new layouts in Phase 1 MUST use multiples of md (15-20px). Do not introduce arbitrary pixel values.

**Existing spacing exceptions inherited from Phase 0:**
- Theme_override_constants/separation = 15 on GameOverPanel VBoxContainer
- Theme_override_constants/separation = 20 on MainMenu VBoxContainer
- Custom minimum sizes (Spacer1 = 20px, Spacer2 = 20px)
- These are preserved as-is until Phase 1 refactors panels.

---

## Typography

All text uses MiSans-Semibold (CJK-capable). Font sizes are declared for the global Theme resource and existing scene overrides:

| Role | Size | Weight | Source |
|------|------|--------|--------|
| Title / Game Over Result | 48px / 40px | Semibold (default) | MainMenu TitleLabel (48), ResultLabel (40) |
| Turn Indicator | 32px | Semibold (default) | HUD TurnLabel |
| Primary Button / Mode Label | 24px / 22px | Semibold (default) | PvPButton (24), ModeLabel (22) |
| Score / Body | 20px | Semibold (default) | ScoreLabel |

**Theme default:** Theme resource at `res://resources/theme/default_theme.tres` sets:
- `default_font` = MiSans-Semibold.ttf
- `default_font_size` = 20 (body text baseline)
- All existing theme_override_font_sizes on individual nodes remain in place (they override Theme defaults)

**Future-proofing:** Phase 1 may introduce additional sizes (e.g., 14px for secondary labels, 28px for section headers). Add those in Phase 1's UI-SPEC.

---

## Color

Current scene colors are applied directly to Control nodes. There is no centralized Theme color scheme yet. These values are the design contract for Phase 0 — they must not be changed until Phase 1's visual pass.

| Role | Value | Usage | Node |
|------|-------|-------|------|
| Background (60%) | #14141E (Color(0.08, 0.08, 0.12)) | Main menu full-screen background | MainMenu/ColorRect |
| Surface (30%) | #1A1A26 (Color(0.1, 0.1, 0.15, 0.92)) | Game over panel card | GameOverPanel/PanelBg (StyleBoxFlat) |
| Overlay (temporary) | #00000080 (Color(0, 0, 0, 0.5)) | Game over dimming overlay | GameOverPanel bg ColorRect |
| Grid line | #B3B3B3 (Color(0.7, 0.7, 0.7)) | Board grid lines | Board/GridLine* |
| Cursor highlight | #FFFFFF40 (Color(1, 1, 1, 0.25)) | Cell focus indicator | Cell/Highlight modulate |
| Text (default) | Inherit (white by default in Godot Light theme) | All labels, buttons | — |
| Accent (10%) | NOT SET IN PHASE 0 | Reserved for Phase 1 (buttons, interactive elements) | — |
| Destructive | NOT APPLICABLE IN PHASE 0 | No destructive actions exist | — |

**Color contract for Phase 0:**
- Do NOT modify any existing Color values in main.tscn nodes
- The default_theme.tres Theme resource must NOT override colors (only font)
- Phase 1 will centralize colors and introduce the accent palette
- AudioController theme colors: NOT APPLICABLE (no UI)

---

## Theme Resource Structure

New file: `res://resources/theme/default_theme.tres`

| Property | Value | Notes |
|----------|-------|-------|
| Resource type | Theme (Godot built-in) | Set as `gui/theme/custom` in project.godot |
| default_font | `res://fonts/MiSans-Semibold.ttf` | MiSans 8MB .ttf (not .otf per user preference) |
| default_font_size | 20 | Body text baseline |
| default_font_color | NOT SET | Inherit default (white on dark). Phase 1 may set explicitly. |
| Control theme overrides | NONE | Phase 0 is font-only. Do not set Button/Label/Panel colors or styles. |

**Implementation order:**
1. Create `default_theme.tres` with only `default_font` and `default_font_size` set
2. Set `project.godot` `gui/theme/custom` = `res://resources/theme/default_theme.tres`
3. No scene node should need theme_override_font after this, BUT existing theme_override_font_sizes (48, 40, 32, 24, 22, 20) must remain — they override Theme defaults correctly

---

## Audio Feedback Contract

The AudioController autoload bridges game events to sound playback. This section defines the sound-to-event mapping that affects the user's audio experience.

### Sound Asset Map (Kenney Interface Sounds)

All SFX sourced from `addons/kenney_interface_sounds/`. Semantic category → actual `.wav` file is Claude's discretion per D-10. The mapping below is the locked contract:

| Game Event | Semantic Category | Suggested File | Bus |
|------------|-------------------|----------------|-----|
| Cell placed (player) | `drop` | `drop_001.wav` | SFX |
| Player wins | `confirmation` | `confirmation_001.wav` | SFX |
| Player loses | `error` | `error_001.wav` | SFX |
| Draw | `bong` | `bong_001.wav` | SFX |
| Button click | `click` | `click_001.wav` | SFX (via ui_sound_effects channel) |
| Button hover | `tick` | `tick_001.wav` | SFX (via ui_sound_effects channel) |

### AudioBusLayout Configuration

| Bus | Parent | Purpose | Created By |
|-----|--------|---------|-----------|
| Master | (root) | Final output | Godot default |
| SFX | Master | All game SFX + UI sounds | AudioController._ready() or editor |
| Music | Master | Background music | AudioController._ready() or editor |

**Contract rules:**
- UI sounds (button click, hover) route through SFX bus via `SoundManager.set_default_ui_sound_bus("SFX")` — no separate UI bus per D-05
- Background music routes through Music bus via `SoundManager.set_default_music_bus("Music")`
- SoundManager's `ambient_sounds` channel (unused in Phase 0) stays at default bus
- Starting volume defaults: SFX=0.8, Music=0.8 (from SettingsManager defaults)

### Background Music

| Context | Track | Crossfade | Loop |
|---------|-------|-----------|------|
| Main menu | `music/off_to_osaka.mp3` | Fade in on game start (0.5s crossfade) | Yes |
| Gameplay | `music/off_to_osaka.mp3` | Fade in on transition (0.5s crossfade) | Yes |
| Game over | Same as gameplay (continues) | No change | Continues |

No second music track in Phase 0. Gameplay music track deferred to Phase 1 per D-11.

### Volume Control

| Setting | Key | Default | Range | Persisted |
|---------|-----|---------|-------|-----------|
| SFX volume | `audio/sfx_volume` | 0.8 | 0.0–1.0 | `user://settings.cfg` |
| Music volume | `audio/music_volume` | 0.8 | 0.0–1.0 | `user://settings.cfg` |

Volume sliders will be in the settings panel (Phase 1). In Phase 0, AudioController reads persisted values at startup only.

---

## Copywriting Contract

### Translation Key Catalog

This is the complete inventory of 16 hardcoded Chinese strings that Phase 0 replaces with `tr()` calls. All keys follow the pattern `{panel}.{element}` per D-21.

| # | Current String | Location | Translation Key | zh_CN Value | en_US Value |
|---|----------------|----------|----------------|-------------|-------------|
| 1 | "井字棋" | main.tscn:48 TitleLabel | `main_menu.title` | 井字棋 | Tic-Tac-Toe |
| 2 | "双人对战" | main.tscn:58 PvPButton | `main_menu.pvp` | 双人对战 | Player vs Player |
| 3 | "人机对战 - 先手" | main.tscn:63 PvAIXButton | `main_menu.pvai_x` | 人机对战 - 先手 | Player vs AI - First |
| 4 | "人机对战 - 后手" | main.tscn:66 PvAIOButton | `main_menu.pvai_o` | 人机对战 - 后手 | Player vs AI - Second |
| 5 | "X胜: 0 \| O胜: 0 \| 平局: 0" | main.tscn:76 ScoreLabel | `main_menu.score` | X胜: {0} \| O胜: {1} \| 平局: {2} | X Wins: {0} \| O Wins: {1} \| Draws: {2} |
| 6 | "双人对战" | main.tscn:100 ModeLabel | `hud.mode_pvp` | 双人对战 | Player vs Player |
| 7 | "轮到: X" | main.tscn:106 TurnLabel | `hud.turn` | 轮到: {0} | Turn: {0} |
| 8 | "返回主菜单" | main.tscn:112 BackButton | `hud.back` | 返回主菜单 | Back to Menu |
| 9 | "X 获胜!" | main.tscn:150 ResultLabel | `game_over.win` | {0} 获胜! | {0} Wins! |
| 10 | "再来一局" | main.tscn:160 RematchButton | `game_over.rematch` | 再来一局 | Play Again |
| 11 | "返回主菜单" | main.tscn:163 MenuButton | `game_over.back` | 返回主菜单 | Back to Menu |
| 12 | "双人对战"/"人机对战" (dynamic) | main.gd:229 | `hud.mode_pvp` / `hud.mode_pvai` | 双人对战 / 人机对战 | Player vs Player / Player vs AI |
| 13 | "轮到: " + player_text | main.gd:237 | `hud.turn` | 轮到: {0} | Turn: {0} |
| 14 | winner_text + " 获胜!" | main.gd:243 | `game_over.win` | {0} 获胜! | {0} Wins! |
| 15 | "平局!" | main.gd:248 | `game_over.draw` | 平局! | Draw! |
| 16 | "X胜: %d \| O胜: %d \| 平局: %d" | main.gd:256 | `main_menu.score` | X胜: {0} \| O胜: {1} \| 平局: {2} | X Wins: {0} \| O Wins: {1} \| Draws: {2} |

### Translation Files

| File | Language | Source | Loaded By |
|------|----------|--------|-----------|
| `res://translations/zh_CN.json` | Chinese (Simplified) | Primary (source language) | I18NManager.load_translation() at startup |
| `res://translations/en_US.json` | English (US) | Translation of zh_CN | I18NManager.load_translation() at startup |

**Contract rules:**
- Keys are ASCII-only dotted paths (e.g., `main_menu.pvp`)
- zh_CN.json is the source of truth; all keys MUST exist in zh_CN.json first
- en_US.json MUST have the same key structure as zh_CN.json
- Dynamic text uses `tr("key").format([arg0, arg1])` pattern, NOT string concatenation
- All existing hardcoded strings are replaced simultaneously (single commit)

### Text Refresh Contract

When language switches via settings panel (Phase 1), UI components refresh via:

```
I18NManager.set_language("en_US")
  → LanguageChangedEvent (lang_code: "en_US")
  → Main._on_language_changed()
    → Main._refresh_text()
      → turn_label.text = tr("hud.turn").format([...])
      → score_label.text = tr("main_menu.score").format([...])
      → Cell.refresh()  // Cell display is graphical (SVG sprites), NOT text — no refresh needed
```

In Phase 0, the `_refresh_text()` function is added to main.gd and connected to LanguageChangedEvent. The settings panel (language switch trigger) is in Phase 1, but the subscription and handler are wired in Phase 0.

---

## Interaction Contracts

### EventBus Subscription Contract (Phase 0 changes)

Existing subscriptions use script path strings. Phase 0 converts ALL of these to StringName literals:

| File | Current Subscription | New Subscription | Change Required |
|------|---------------------|-----------------|-----------------|
| main.gd | `res://scripts/events/game_started_event.gd` | `&"GameStartedEvent"` | YES |
| main.gd | `res://scripts/events/turn_changed_event.gd` | `&"TurnChangedEvent"` | YES |
| main.gd | `res://scripts/events/game_won_event.gd` | `&"GameWonEvent"` | YES |
| main.gd | `res://scripts/events/game_draw_event.gd` | `&"GameDrawEvent"` | YES |
| main.gd | `res://scripts/events/score_changed_event.gd` | `&"ScoreChangedEvent"` | YES |
| cell.gd | `res://scripts/events/cell_placed_event.gd` | `&"CellPlacedEvent"` | YES |
| cell.gd | `res://scripts/events/game_started_event.gd` | `&"GameStartedEvent"` | YES |
| cell.gd | `res://scripts/events/game_won_event.gd` | `&"GameWonEvent"` | YES |
| cell.gd | `res://scripts/events/game_draw_event.gd` | `&"GameDrawEvent"` | YES |
| cell.gd | `res://scripts/events/cursor_moved_event.gd` | `&"CursorMovedEvent"` | YES |

New subscriptions (AudioController autoload):

| Subscriber | Event | StringName | Purpose |
|-----------|-------|------------|---------|
| AudioController | CellPlacedEvent | `&"CellPlacedEvent"` | Play drop sound |
| AudioController | GameWonEvent | `&"GameWonEvent"` | Play win/lose sound |
| AudioController | GameDrawEvent | `&"GameDrawEvent"` | Play draw sound |
| AudioController | GameStartedEvent | `&"GameStartedEvent"` | Switch to gameplay music |
| AudioController | SettingChangedEvent | `&"SettingChangedEvent"` | Apply volume on change |

New subscriptions (Main for localization):

| Subscriber | Event | StringName | Purpose |
|-----------|-------|------------|---------|
| Main | LanguageChangedEvent | `&"LanguageChangedEvent"` | Refresh UI text via _refresh_text() |

### Event Publishing Contract (Phase 0 changes)

GameManager replaces its `_event_types` dictionary with direct instantiation:

| Current Pattern | New Pattern |
|----------------|-------------|
| `_event_types["cell_placed"].new(...)` | `CellPlacedEvent.new(...)` |
| `_event_types["game_started"].new(...)` | `GameStartedEvent.new(...)` |
| `_event_types["turn_changed"].new(...)` | `TurnChangedEvent.new(...)` |
| `_event_types["game_won"].new(...)` | `GameWonEvent.new(...)` |
| `_event_types["game_draw"].new(...)` | `GameDrawEvent.new(...)` |
| `_event_types["score_changed"].new(...)` | `ScoreChangedEvent.new(...)` |
| `_event_types["cursor_moved"].new(...)` | `CursorMovedEvent.new(...)` |

Remove `_event_types` dictionary and `_cache_event_types()` from GameManager entirely.

### New Event: SettingChangedEvent

```
File: res://scripts/events/setting_changed_event.gd
class_name: SettingChangedEvent
Fields:
  - key: String       (e.g., "audio/sfx_volume", "gameplay/difficulty", "language/locale")
  - value: Variant    (e.g., 0.8, 1, "en_US")
Published by: SettingsManager.set() on every change.
```

---

## Registry Safety

Not applicable. This is a Godot 4.6 project with no npm registries.

| Registry | Blocks Used | Safety Gate |
|----------|-------------|-------------|
| Godot addons (existing) | mc_game_framework, SoundManager, GUIDE, GUT | N/A — all existing, no new packages |
| Kenney Interface Sounds | SFX WAV files | N/A — CC0 asset pack, included in addons |
| MiSans-Semibold.ttf | CJK font | N/A — included asset file |

---

## Checker Sign-Off

- [ ] Dimension 1 Copywriting: (Awaiting checker)
- [ ] Dimension 2 Visuals: (Awaiting checker — this is infrastructure phase)
- [ ] Dimension 3 Color: (Awaiting checker)
- [ ] Dimension 4 Typography: (Awaiting checker)
- [ ] Dimension 5 Spacing: (Awaiting checker)
- [ ] Dimension 6 Registry Safety: (Awaiting checker — N/A)

**Approval:** pending
