# Phase 00: Foundation, Sound & Localization - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-17
**Phase:** 00-Foundation, Sound & Localization
**Areas discussed:** Event type organization, Sound mapping & AudioBus design, Settings persistence structure, Localization key design & CJK font

---

## Event Type Organization

### How should event type references be organized?
| Option | Description | Selected |
|--------|-------------|----------|
| class_name on events | Add `class_name CellPlacedEvent` to each event script. EventBus auto-resolves via `get_event_type()`. | ✓ |
| StringName constants file | Create `event_types.gd` with centralized constants. | |
| Both class_name + constants | Dual approach — most safety but extra maintenance. | |

### GameManager _event_types cache — keep or remove?
| Option | Description | Selected |
|--------|-------------|----------|
| Remove _event_types cache | Delete `_cache_event_types()` method. Publish directly with `CellPlacedEvent.new(...)`. | ✓ |
| Keep cache with class refs | Preserve dict with class references as keys. | |

### Subscription syntax?
| Option | Description | Selected |
|--------|-------------|----------|
| StringName literals &"..." | `EventBus.subscribe(&"CellPlacedEvent", callback)` — compiled-time intern, no heap alloc. | ✓ |
| String literals "..." | Standard strings, auto-converted to StringName per call. | |

### Apply class_name to new Phase 0 events?
| Option | Description | Selected |
|--------|-------------|----------|
| Add class_name to new events too | All new events (SettingChangedEvent) follow same pattern. | ✓ |
| Only existing 7 events | New events handled differently — inconsistent. | |

### What new events does Phase 0 need?
| Option | Description | Selected |
|--------|-------------|----------|
| SettingChangedEvent (per-key) | `key: String, value: Variant` — one event per setting change. | ✓ |
| SettingsChangedEvent (unified) | All settings in one event. | |
| LanguageChangedEvent (separate) | Dedicated language event — but framework already provides this. | |

### How should sound playback be triggered?
| Option | Description | Selected |
|--------|-------------|----------|
| EventBus → SoundManager bridge | Game events published → AudioController listens → calls SoundManager. | ✓ |
| GameManager calls SoundManager directly | GameManager couples to audio. | |
| Sound via GUIDE actions | GUIDE actions trigger sounds. | |

---

## Sound Mapping & AudioBus Design

### AudioBusLayout bus names?
| Option | Description | Selected |
|--------|-------------|----------|
| Master / SFX / Music | Two custom buses under Master. UI sounds route through SFX. | ✓ |
| SFX / Music / UI | Three custom buses. | |
| Game SFX / UI SFX / Music / Ambient | Four buses. | |

### How to map kenney sounds to game events?
| Option | Description | Selected |
|--------|-------------|----------|
| Semantic mapping per event | Each game event → best matching kenney category (drop, confirmation, error, etc.). | ✓ |
| Minimal single category | All sounds from one category. | |
| Claude decides | Let Claude pick specific files during implementation. | |

### Where should audio orchestration live?
| Option | Description | Selected |
|--------|-------------|----------|
| New AudioController autoload | Dedicated autoload for audio logic — clean separation. | ✓ |
| Add to existing main.gd | Already ~280 lines, would grow past 300. | |
| Add to GameManager | Audio + game logic coupling. | |

### Music tracks?
| Option | Description | Selected |
|--------|-------------|----------|
| One track now, second in Phase 1 | Use existing `off_to_osaka.mp3`. Source second track during UI phase. | ✓ |
| One track for both | Same music menu and gameplay. | |
| Two tracks | Source additional music now. | |

### How to configure SoundManager for custom buses?
| Option | Description | Selected |
|--------|-------------|----------|
| Route via SoundManager buses | `set_default_sound_bus("SFX")`, `set_default_music_bus("Music")`. | ✓ |
| Direct AudioServer control | Bypass SoundManager abstraction. | |
| Custom AudioStreamPlayer nodes | Abandon SoundManager plugin entirely. | |

### How to configure sound-to-event mapping?
| Option | Description | Selected |
|--------|-------------|----------|
| ResourceLocation + RegistryManager | mc_game_framework native pattern. SoundRegistry extends RegistryBase. | ✓ |
| Resource-based sound map | Custom Resource .tres for editor configuration. | |
| AudioStreamRandomizer per event | Built-in Godot randomization. | |

### ResourceLocation namespace?
| Option | Description | Selected |
|--------|-------------|----------|
| Single namespace: tic_tac_toe | All resources under one namespace. | ✓ |
| Per-type namespaces | Separate namespaces for sounds, music, etc. | |

### Registry for sounds?
| Option | Description | Selected |
|--------|-------------|----------|
| SoundRegistry extends RegistryBase | Type-safe sound registry. | ✓ |
| Use existing RegistryManager directly | No new class, less type safety. | |

### Sound preloading?
| Option | Description | Selected |
|--------|-------------|----------|
| Preload all in AudioController._ready() | Load ~15 sounds into dict cache at startup. | ✓ |
| Lazy load on first play | Load on demand — first play has micro-latency. | |

### Music flow?
| Option | Description | Selected |
|--------|-------------|----------|
| Menu ↔ Gameplay crossfade | Crossfade via SoundManager.play_music() with crossfade_duration. | ✓ |
| Always playing, no crossfade | Music loops, no transitions. | |

### FND-02: SoundManager double registration?
| Option | Description | Selected |
|--------|-------------|----------|
| Remove project.godot duplicate | Keep only plugin-based registration. | ✓ |
| Keep both | Harmless but produces warnings. | |

### FND-03: AudioBusLayout creation?
| Option | Description | Selected |
|--------|-------------|----------|
| Runtime detection + manual editor setup | Editor configures buses. Runtime verifies and creates if missing. | ✓ |
| Editor only | No runtime check. | |
| AudioBusLayout .tres + project.godot | Godot native config file. | |

### Volume recovery on startup?
| Option | Description | Selected |
|--------|-------------|----------|
| Load on startup, save on change | AudioController reads from SettingsManager, applies on boot. | ✓ |
| Runtime only | No persistence. | |

---

## Settings Persistence Structure

### ConfigFile location?
| Option | Description | Selected |
|--------|-------------|----------|
| user://settings.cfg | Standard Godot writable path, cross-platform. | ✓ |
| res://settings.cfg | Read-only in exported builds. | |

### Data structure?
| Option | Description | Selected |
|--------|-------------|----------|
| Sections: [audio], [gameplay], [language] | Organized by domain. | ✓ |
| Single [settings] section | Flat structure. | |

### Who owns ConfigFile persistence?
| Option | Description | Selected |
|--------|-------------|----------|
| New SettingsManager autoload | Dedicated persistence layer. | ✓ |
| Add to GameManager | Mixes game logic with persistence. | |
| Each component saves independently | Decentralized, potential file conflicts. | |

### When to persist?
| Option | Description | Selected |
|--------|-------------|----------|
| On settings screen exit or game exit | Debounced save — memory as live state. | ✓ |
| Save immediately on every change | Atomic per-change writes. | |

### Default values strategy?
| Option | Description | Selected |
|--------|-------------|----------|
| Default settings Resource file | `.tres` resource — editor-configurable defaults. | ✓ |
| Hardcoded in SettingsManager | Code-only defaults. | |

### API design?
| Option | Description | Selected |
|--------|-------------|----------|
| Simple get/set with memory cache | `_settings: Dictionary` cache. `set()` publishes SettingChangedEvent. | ✓ |
| Direct ConfigFile read/write | Disk on every access. | |

### Error handling for corrupt config?
| Option | Description | Selected |
|--------|-------------|----------|
| Silent fallback to defaults + push_warning | Game continues, warning logged. | ✓ |
| Block startup with error dialog | Too aggressive for a config file issue. | |

### Autoload initialization order?
| Option | Description | Selected |
|--------|-------------|----------|
| Autoload order in project.godot | SettingsManager before AudioController. | ✓ |
| Lazy init via deferred _ready() | All autoloads defer settings read by one frame. | |

---

## Localization Key Design & CJK Font

### Translation key naming strategy?
| Option | Description | Selected |
|--------|-------------|----------|
| Nested by UI panel | `main_menu.title`, `hud.turn_label` — clear structure. | ✓ |
| Flat global keys | All keys at top level. | |
| Functional categories | `ui.btn.start_pvp`, `ui.label.turn_x`. | |

### CJK font?
| Option | Description | Selected |
|--------|-------------|----------|
| MiSans-Semibold (user-provided) | Already in `fonts/` — use .ttf variant. | ✓ |
| Noto Sans SC | Google open-source. | |
| Source Han Sans SC | Adobe/Google joint release. | |

### Translation file format?
| Option | Description | Selected |
|--------|-------------|----------|
| JSON → I18NManager | Framework native, nested dict auto-flatten to dotted keys. | ✓ |
| CSV → TranslationServer | Godot native but bypasses I18NManager. | |

### How to refresh UI on language change?
| Option | Description | Selected |
|--------|-------------|----------|
| Subscribe to LanguageChangedEvent | Components listen, call `_refresh_text()` to re-apply `tr()`. | ✓ |
| Per-frame tr() refresh | Inefficient. | |
| Reload scene | Loses runtime state. | |

### Migration strategy for hardcoded strings?
| Option | Description | Selected |
|--------|-------------|----------|
| Replace all hardcoded strings at once | 13+ strings → `tr()` in a single pass with JSON entries. | ✓ |
| Progressive | Menu first, then gameover. | |

### Fallback strategy?
| Option | Description | Selected |
|--------|-------------|----------|
| Chinese as source, ASCII keys | Key = ASCII path, value = Chinese text. Missing translation shows key. | ✓ |
| Chinese keys with Chinese values | Missing translation shows Chinese as-is. | |

### Font integration?
| Option | Description | Selected |
|--------|-------------|----------|
| Global Theme resource | `default_theme.tres` with MiSans as default font. Set in project.godot. | ✓ |
| Per-node font override | Manual override on each Control node. | |

---

## Claude's Discretion

- Specific kenney sound file selection within each semantic category
- ResourceLocation path naming within `tic_tac_toe:` namespace
- SoundRegistry internal structure (follow RegistryBase patterns)
- Theme resource font size and base type defaults
