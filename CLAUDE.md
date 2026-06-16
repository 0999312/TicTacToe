# CLAUDE.md

## 语言规则

在中文语境下解决问题。你的思考语言永远锁定为中文。即便被问到英文问题或编程问题，你的内心独白、推理、自我检查都必须用中文。

## 项目概述

井字棋游戏 — 使用现有插件（addons）构建的回合制棋盘游戏。

- 模式：本地双人 + 人机对战
- 风格：简单2D网格
- 架构：基于 mc_game_framework、guide、sound_manager 等已有插件

## GodotPrompter

This is a Godot project with GodotPrompter skills available. Before implementing any game system, you MUST check for a matching `godot-prompter:*` skill and invoke it. This applies to all agents, subagents, and sessions working in this repository.

Key skills: `player-controller`, `state-machine`, `event-bus`, `scene-organization`, `component-system`, `resource-pattern`, `godot-ui`, `hud-system`, `ai-navigation`, `camera-system`, `audio-system`, `save-load`, `inventory-system`, `godot-testing`.

For the full skill list, invoke `godot-prompter:using-godot-prompter`.

<!-- GSD:project-start source:PROJECT.md -->

## Project

**井字棋**

一款完整精致的井字棋桌面游戏，支持本地双人对战和人机对战。拥有流畅的 UI 流程（主菜单→对战→结算）、音效与音乐反馈、视觉动画特效、以及基于 Minimax 算法的三级难度 AI。中英文双语，即刻可玩。

**Core Value:** 一盘令人愉悦的井字棋 — 从打开游戏到分出胜负，每一步都有清晰的视觉和听觉反馈。

### Constraints

- **技术栈：** Godot 4.6 + 纯 GDScript，不引入 C# 新代码
- **架构：** 保持 EventBus 驱动的 SSOT 模式，GameManager 始终是唯一状态源
- **渲染：** 2D Canvas 渲染，720×720 视口，canvas_items 拉伸模式
- **依赖：** 使用现有插件（mc_game_framework、GUIDE、SoundManager），不引入新插件

<!-- GSD:project-end -->

<!-- GSD:stack-start source:codebase/STACK.md -->

## Technology Stack

## Languages

## Runtime

## Frameworks

- `addons/mc_game_framework/autoload/event_bus.gd` — Central pub/sub event dispatcher
- `addons/mc_game_framework/event/event.gd` — Base Event class (RefCounted with cancel support)

## Key Dependencies

- Author: SyameimaruZheng
- Version: 0.0 (early/in-development)
- Provides: Event bus (`EventBus`), UI Manager (`UIManager`), Registry system (`RegistryManager`), I18N (`I18NManager`), Component/Codec system
- Plugin script: `addons/mc_game_framework/mc_game_framework.gd`
- Author: Jan Thoma
- Version: 0.13.0
- Provides: Context-based input mapping with cross-device support (keyboard, mouse, gamepad, touch)
- Autoload singleton: `GUIDE`
- All gameplay actions (place mark, navigate grid) are routed through GUIDE
- Author: Nathan Hoad
- Version: 2.6.1
- Provides: Channel-based audio playback (sound_effects, ui_sound_effects, ambient_sounds, music)
- Autoload singleton: `SoundManager`
- Author: Butch Wesley
- Version: 9.6.0
- Provides: Test runner, assertions, doubles/mocking
- No tests currently written

## Configuration

- All configuration is in `project.godot` (Godot's built-in config format)
- No `.env` files or external configuration systems
- Game version: `0.1.0`
- No build system (Godot exports directly from the editor)
- No CI/CD configuration detected
- No `Dockerfile` or deployment configs

## Input Map

- `place_mark`: Bound to left mouse button (`MOUSE_BUTTON_LEFT`) via the built-in Input Map. However, this is not used by the game code — all gameplay input is handled through GUIDE's action system instead.

## Directory Layout

## Platform Requirements

- Godot Engine 4.6 or compatible
- No external SDKs or runtimes required
- Works on Windows, macOS, Linux (Godot cross-platform)
- Godot built-in export templates for Windows, macOS, Linux, web (HTML5), Android, iOS
- No special platform requirements beyond standard Godot export

<!-- GSD:stack-end -->

<!-- GSD:conventions-start source:CONVENTIONS.md -->

## Conventions

## Naming Patterns

- `snake_case.gd` for all script files — `main.gd`, `cell.gd`, `game_manager.gd`, `cell_placed_event.gd`
- Resource files follow `.tres` extension with the action name: `grid_navigate.tres`, `place_mark.tres`
- Scene files follow `snake_case.tscn`: `main.tscn`, `cell.tscn`
- `PascalCase` for classes declared with `class_name` — `Cell` in `scripts/cell.gd`
- Enums declared with `enum` keyword use `PascalCase` for the type name — `Player`, `GameMode`, `GameState`
- Enum values use `UPPER_SNAKE_CASE` — `Player.X`, `GameMode.PVP`, `GameState.PLAYING`
- `snake_case` for all functions — `place_mark()`, `move_cursor()`, `get_cell()`
- Public API functions omit prefix: `start_game()`, `reset_board()`
- Private/internal functions prefixed with underscore: `_check_winner()`, `_switch_turn()`, `_do_ai_move()`, `_is_board_full()`
- Godot callback overrides use `_` prefix: `_ready()`, `_init()`
- Signal/EventBus handler functions use `_on_` prefix: `_on_cell_placed()`, `_on_game_started()`, `_on_place_mark()`
- Factory/helper functions use `_make_` prefix: `_make_key()`, `_make_input_mapping()`, `_show_only()`
- `snake_case` for all variables — `cell_index`, `current_player`, `move_count`
- Private instance variables prefixed with underscore: `_gameplay_context`, `_x_texture`, `_o_texture`, `_stick_accumulator`, `_event_types`
- Constants use `UPPER_SNAKE_CASE` — `STICK_THRESHOLD` (float), `WIN_LINES` (Array)
- Node references use `@onready var` with `snake_case` — `@onready var sprite: Sprite2D = $Sprite2D`
- Exported properties use `@export var` with `snake_case` — `@export var cell_index: int = 0`
- Prefix with `p_` to distinguish from member variables — `p_cell_index`, `p_player`, `p_mode`, `p_winner`, `p_p1`, `p_draw`
- Exception: Some public methods use unprefixed param names — `start_game(p_mode, p_player_side)` vs `place_mark(cell_index)` (inconsistent)

## Code Style

- 4-space indentation (GDScript standard, confirmed across all `.gd` files)
- Opening braces on the same line (`func foo():`, `if condition:`)
- Consistent spacing around operators — `move_count += 1`, `board[cell_index] = current_player`
- Whitespace between logical blocks within functions
- No `.eslint` or GDScript linter config detected
- `project.godot` enables the GUT, guide, mc_game_framework, and sound_manager editor plugins
- One explicit `@warning_ignore("integer_division")` annotation used in `game_manager.gd:122` — indicates conscious use of integer division in cursor navigation

## Import Organization

- `load()` at point of use for dynamic resources — `load("res://resources/actions/place_mark.tres")`
- `preload()` for compile-time known resources — `preload("res://assets/sprites/x_mark.svg")` in `cell.gd`
- `const` paths for event type strings — `const GameManagerClass := preload("res://autoload/game_manager.gd")` in tests
- EventBus subscriptions use resource path strings: `EventBus.subscribe("res://scripts/events/cell_placed_event.gd", _on_cell_placed)`
- Event class references cached at runtime: `_event_types["game_started"] = load("res://scripts/events/game_started_event.gd")`

## Type Annotations

- All function return types annotated with `-> void`, `-> bool`, `-> int`, `-> String`
- All parameters annotated: `func place_mark(cell_index: int) -> bool`
- All variables annotated: `var _x_texture: Texture2D`, `var count: int`
- `@onready` variables typed: `@onready var sprite: Sprite2D = $Sprite2D`
- Node type used in autoload references: `var gm: Node = autoqfree(GameManagerClass.new())`
- Type inference with `:=` used for local variables: `var winner := _check_winner()`

## Error Handling

- Early return on invalid state — `if state != GameState.PLAYING: return`
- Guard clauses at function entry for bounds checking — `if cell_index < 0 or cell_index > 8: return false`
- Boolean return values from GameManager methods to indicate success/failure — `place_mark()` returns `bool`
- No try/catch usage (GDScript does not support it)
- No custom error types or error reporting beyond return values
- `cell.gd:50` — `if "cell_index" in event:` uses duck-typing check before accessing event properties
- `cell.gd:22,37` — `if highlight:` null-check before accessing optional nodes
- `game_manager.gd:130` — `if _event_types.has("cursor_moved"):` checks key existence before publish
- `main.gd:162` — `if _is_mouse_or_touch_active() and board_node:` chained null-guard before accessing board

## Logging

## Comments

- Section headers use `# ---` separator comments: `# --- place_mark ---`, `# --- factories ---`, `# --- button callbacks ---`
- Architecture-level section dividers with blank lines before and after
- One inline comment on `_setup_direction_action` usage explaining the input type
- No JSDoc/TSDoc-style documentation comments on any functions
- No method-level docstrings — function purpose inferred from naming

## Function Design

- Boolean for validity checks: `place_mark()` returns `bool`, `is_game_over()` returns `bool`
- Integer for state queries: `get_cell()` returns `int`, `get_winner()` returns `int`
- Void for event handlers and state mutators
- String for display values: `get_current_player_text()` returns `String`

## Module Design

- `class_name Cell` in `cell.gd` — one exported class for reuse
- `@export var cell_index: int` — exported property for scene configuration in Cell
- All other scripts (main.gd, game_manager.gd, events) do not use `class_name` — they are accessed via Autoload or `load()`

## Event System Conventions

- All events extend `Event` (from mc_game_framework)
- Fields declared as typed member variables
- Constructor `_init` uses `p_`-prefixed parameters
- Events with no data (`game_draw_event.gd`) have an empty body
- Subscriptions use the full resource path string
- Handlers are `_on_` prefixed private methods
- Subscriptions set up in `_ready()` of the subscribing node
- Event class references cached in a dictionary at runtime
- Published with `EventBus.publish()` using `new()` on cached references

## Input Handling Conventions

- `GUIDEAction` resources loaded from `res://resources/actions/*.tres`
- `GUIDEMappingContext` created with all action mappings
- Each action has a `GUIDEActionMapping` with multiple `GUIDEInputMapping` entries
- Input types: `GUIDEInputKey`, `GUIDEInputMouseButton`, `GUIDEInputTouchBase`, `GUIDEInputJoyButton`, `GUIDEInputJoyDirection`, `GUIDEInputJoyAxis2D`
- Trigger types: `GUIDETriggerPressed` (discrete), `GUIDETriggerDown` (continuous)
- Signals connected on actions: `.just_triggered.connect(_on_place_mark)`, `.triggered.connect(_on_nav_stick)`

## Scene Node Conventions

- `@onready` annotations used consistently: `@onready var main_menu: Control = $CanvasLayer/MainMenu`
- Path-based node references (not `%UniqueName` despite AGENTS.md recommendation)
- Node groups used for Cell iteration: `add_to_group("cell")` and `get_tree().get_nodes_in_group("cell")`
- `$` shorthand used inline: `$Board`, `$CanvasLayer/GameOverPanel/VBoxContainer/ResultLabel`

<!-- GSD:conventions-end -->

<!-- GSD:architecture-start source:ARCHITECTURE.md -->

## Architecture

## System Overview

```text

```

## Component Responsibilities

| Component | Responsibility | File |
|-----------|----------------|------|
| GameManager | Game state authority: board array, turn control, win/draw detection, Minimax AI, score tracking | `res://autoload/game_manager.gd` |
| Main | Scene orchestrator: UI panel switching, GUIDE input setup, EventBus subscription, input-to-GameManager forwarding | `res://scripts/main.gd` |
| Cell (Area2D) | Visual grid cell: displays X/O sprites, highlights cursor position, receives click events | `res://scripts/cell.gd` |
| EventBus | Global publish/subscribe event bus for cross-system communication | `res://addons/mc_game_framework/autoload/event_bus.gd` |
| UIManager | Stack-based UI panel manager with layers, overlays, toasts, popup queue | `res://addons/mc_game_framework/autoload/ui_manager.gd` |
| RegistryManager | Type registry for components, UI panels, etc. | `res://addons/mc_game_framework/autoload/registry_manager.gd` |
| I18NManager | JSON-based translation loading and language switching | `res://addons/mc_game_framework/autoload/i18n_manager.gd` |
| SoundManager | Audio playback: SFX, UI sounds, ambient, music with pooling | `res://addons/sound_manager/sound_manager.gd` |
| GUIDE | Input framework: action-based input mapping with context priority, multi-device support | `res://addons/guide/guide.gd` |

## Pattern Overview

- **Singleton Autoloads** provide global access to systems (GameManager, EventBus, SoundManager, etc.) -- registered in `res://project.godot` `[autoload]` section
- **EventBus publish/subscribe** is the primary cross-system communication pattern -- systems do not call each other directly except when GameManager is the target
- **GameManager is the Single Source of Truth (SSOT)** for all game state -- scenes and cells only read, never own state
- **Scene tree is view-only** -- `main.tscn` + `cell.tscn` handle rendering and input forwarding, never game logic
- **GUIDE input framework** decouples input devices from game actions through action resources and mapping contexts
- **Stack-based UI management** via UIManager for panel lifecycle (open/close/pause/resume)

## Layers

- Purpose: Global systems accessible from anywhere via name
- Location: `res://autoload/` + `res://addons/*/autoload/`
- Contains: GameManager, EventBus, UIManager, RegistryManager, I18NManager, SoundManager, GUIDE
- Depends on: Nothing (Godot bootstrap)
- Used by: All scenes and scripts
- Purpose: Game entry point, orchestrates UI and board
- Location: `res://scenes/main.tscn`, `res://scripts/main.gd`
- Contains: Menu/HUD/Result panels, Board with 9 cells
- Depends on: GameManager, EventBus, GUIDE, SoundManager
- Used by: Godot runtime (set as main scene in `project.godot`)
- Purpose: Render game marks and handle input events
- Location: `res://scenes/cell.tscn`, `res://scripts/cell.gd`
- Contains: Sprite2D for X/O, Highlight sprite for cursor, CollisionShape2D
- Depends on: GameManager (reads cell state), EventBus (subscribes to events)
- Used by: Main scene Board node
- Purpose: Reusable game development infrastructure
- Location: `res://addons/mc_game_framework/`, `res://addons/guide/`, `res://addons/sound_manager/`, `res://addons/gut/`
- Contains: Event system, component system, codec system, input framework, audio manager, test runner
- Depends on: Godot 4.x engine
- Used by: GameManager, Main, Cell

## Autoload Configuration

```gdscript

```

## Data Flow

### Primary Request Path -- Player Places Mark (PvP)

### AI Move Flow (PvAI)

### Cursor Navigation Flow (Keyboard/Controller)

### State Management

- **Game state** lives entirely in `GameManager` (board array, current_player, mode, scores, cursor_index)
- **No state duplication** in scenes or cells -- they read from GameManager via direct calls (`GameManager.get_cell(index)`) or receive event notifications
- **UI state** (which panel is visible) is managed locally in `Main` via `_show_only()` which toggles visibility of MainMenu/HUD/GameOverPanel
- **Event data** is encapsulated in Event subclasses (e.g., `CellPlacedEvent` has `cell_index` and `player` fields)

## Event System

### EventBus (`res://addons/mc_game_framework/autoload/event_bus.gd`)

- `subscribe(event_type: StringName, listener: Callable)` -- register a listener for an event type
- `unsubscribe(event_type: StringName, listener: Callable)` -- remove a listener
- `publish(event: Event)` -- dispatch event to all listeners; supports cancellation via `event.cancel()`

### Custom Events (in `res://scripts/events/`)

| Event Class | Fields | File |
|-------------|--------|------|
| `GameStartedEvent` | `mode: int` | `res://scripts/events/game_started_event.gd` |
| `CellPlacedEvent` | `cell_index: int, player: int` | `res://scripts/events/cell_placed_event.gd` |
| `TurnChangedEvent` | `player: int` | `res://scripts/events/turn_changed_event.gd` |
| `GameWonEvent` | `winner: int` | `res://scripts/events/game_won_event.gd` |
| `GameDrawEvent` | (none) | `res://scripts/events/game_draw_event.gd` |
| `ScoreChangedEvent` | `p1_score, p2_score, draw_score: int` | `res://scripts/events/score_changed_event.gd` |
| `CursorMovedEvent` | `cursor_index: int` | `res://scripts/events/cursor_moved_event.gd` |

### Communication Pattern Summary

| Pattern | Used For | Example |
|---------|----------|---------|
| Direct method call | Main -> GameManager commands | `GameManager.place_mark(idx)` |
| EventBus publish | GameManager -> all subscribers notification | `EventBus.publish(CellPlacedEvent.new(...))` |
| EventBus subscribe | Scene/listener registration for events | `EventBus.subscribe("res://scripts/events/cell_placed_event.gd", _on_cell_placed)` |
| Direct property read | Cell reads GameManager state | `GameManager.get_cell(cell_index)` |
| GUIDE signal | Input action -> handler | `_place_mark_action.just_triggered.connect(_on_place_mark)` |
| Godot signal | Button pressed -> Main handler | Connected in `main.tscn` via `[connection]` blocks |

## Key Abstractions

- Purpose: Base class for all event data objects
- Extends: `RefCounted` (no node needed, auto memory-managed)
- Features: cancellation support, type detection via script path
- All game events extend this class
- Purpose: Minecraft-style Data Component system for attaching typed data to any object (Node, Resource, RefCounted)
- Currently NOT used by the Tic-Tac-Toe game code -- it is framework infrastructure available for future use
- Pattern: Entity-Component via composition using metadata storage
- Purpose: Decouple physical input (keyboard, mouse, controller) from logical game actions
- Actions are Resource files (`.tres`): `res://resources/actions/place_mark.tres`, `nav_up.tres`, etc.
- The mapping context in `main.gd` binds inputs to actions and action signals to game logic handlers
- Purpose: Stack-based panel management with layers (SCENE, NORMAL, POPUP, TOAST, OVERLAY)
- Currently NOT used by Tic-Tac-Toe -- panels are managed manually via `_show_only()` visibility toggling
- Available for future expansion with proper panel lifecycle

## Entry Points

- Location: `res://scenes/main.tscn` (set as `run/main_scene` in `project.godot` line 19)
- Script: `res://scripts/main.gd`
- Triggers: Godot engine loads this scene on launch
- Responsibilities: Initialize UI, set up GUIDE input context, subscribe to EventBus, coordinate game flow
- mc_game_framework: `res://addons/mc_game_framework/mc_game_framework.gd` (EditorPlugin) -- registers autoload singletons and inspector plugins
- GUIDE: `res://addons/guide/plugin.gd` -- registers GUIDE autoload and editor tools
- SoundManager: `res://addons/sound_manager/plugin.gd` -- registers SoundManager autoload
- GUT: `res://addons/gut/plugin.cfg` -- test runner plugin

## Scene Tree Philosophy

```

```

- **UI and game world are separated** by CanvasLayer -- UI is in screen space, Board is in world space
- **Cell instances are statically placed** in the scene tree (9 instances in `main.tscn`), not dynamically generated
- **Panel visibility is mutually exclusive** -- only one of MainMenu/HUD/GameOverPanel is visible at a time, managed by `_show_only()`

## Architectural Constraints

- **Single-threaded:** Godot 4.x single-threaded game loop; AI Timer uses `one_shot` timer for 0.3s delay to simulate "thinking" without blocking
- **Global state:** GameManager is a Singleton with mutable state (board array, scores). All systems read from it directly. No immutability enforcement.
- **No circular imports:** Architecture prevents this -- scenes only depend on Autoloads (always available), never the reverse
- **Event subscription via script path string:** Subscribers reference event types by their script resource path string (e.g., `"res://scripts/events/cell_placed_event.gd"`). This is fragile if files move -- no compile-time checking.
- **Event type lookup duplication:** GameManager caches event types in `_event_types` dictionary (`res://autoload/game_manager.gd:38-46`) keyed by string names, requiring manual sync if events are added/removed.

## Anti-Patterns

### Hard-coded scene references in code

```gdscript

```

### Manual panel visibility management

### Event type caching pattern

## Error Handling

- Guard clauses at function entry: `if state != GameState.PLAYING: return false` (`res://autoload/game_manager.gd:82-83`)
- Boolean return values for operation success: `place_mark()` returns `bool` (`res://autoload/game_manager.gd:81`)
- No exception handling -- Godot GDScript does not have try/catch
- No error logging within game logic (GameManager does not use `push_error` or `printerr`)
- EventBus has internal stale listener cleanup (`res://addons/mc_game_framework/autoload/event_bus.gd:26-41`)

## Cross-Cutting Concerns

<!-- GSD:architecture-end -->

<!-- GSD:skills-start source:skills/ -->

## Project Skills

| Skill | Description | Path |
|-------|-------------|------|
| game-architect | READ this skill when designing or planning any game system architecture — including combat, skills, AI, UI, multiplayer, narrative, or scene systems. Contains paradigm selection guides (DDD / Data-Driven / Prototype), system-specific design references, and mixing strategies. Works as a domain knowledge plugin alongside workflow skills (OpenSpec, SpecKit) or plan mode of an agent. | `.claude/skills/game-architect/SKILL.md` |
<!-- GSD:skills-end -->

<!-- GSD:workflow-start source:GSD defaults -->

## GSD Workflow Enforcement

Before using Edit, Write, or other file-changing tools, start work through a GSD command so planning artifacts and execution context stay in sync.

Use these entry points:

- `/gsd-quick` for small fixes, doc updates, and ad-hoc tasks
- `/gsd-debug` for investigation and bug fixing
- `/gsd-execute-phase` for planned phase work

Do not make direct repo edits outside a GSD workflow unless the user explicitly asks to bypass it.
<!-- GSD:workflow-end -->

<!-- GSD:profile-start -->

## Developer Profile

> Profile not yet configured. Run `/gsd-profile-user` to generate your developer profile.
> This section is managed by `generate-claude-profile` -- do not edit manually.
<!-- GSD:profile-end -->
