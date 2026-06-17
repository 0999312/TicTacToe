# 井字棋

## What This Is

一款完整精致的井字棋桌面游戏，支持本地双人对战和人机对战。拥有流畅的 UI 流程（主菜单→对战→结算）、音效与音乐反馈、视觉动画特效、以及基于 Minimax 算法的三级难度 AI。中英日三语，即刻可玩。

## Core Value

一盘令人愉悦的井字棋 — 从打开游戏到分出胜负，每一步都有清晰的视觉和听觉反馈。

## Requirements

### Validated

- ✓ 本地双人对战（PvP）— v1.0
- ✓ 人机对战（PvAI，三级难度 Minimax AI）— v1.0
- ✓ 胜负/平局检测 — v1.0
- ✓ 棋盘渲染与点击交互 — v1.0
- ✓ EventBus 发布/订阅架构（StringName 常量化）— v1.0
- ✓ GUIDE 输入框架集成 — v1.0
- ✓ SoundManager 音效播放（落子/胜利/失败/按钮/背景音乐）— v1.0
- ✓ I18NManager 双语/三语切换 — v1.0
- ✓ UIManager UI 面板栈管理 — v1.0
- ✓ 游戏全程音效反馈 + 背景音乐（双轨交叉淡化）— v1.0
- ✓ 独立音效/音乐音量控制 — v1.0
- ✓ 落子弹跳动画 + 赢线绘制 + 场景淡入淡出 + 按钮微交互 — v1.0
- ✓ 主菜单 + 游戏内 HUD + 结算画面 + 暂停菜单 + 设置面板 — v1.0
- ✓ Minimax 算法实现（含 alpha-beta 剪枝）— v1.0
- ✓ 三级 AI 难度（简单/中等/困难，参数差异化）— v1.0
- ✓ AI 思考延迟 + HUD 思考指示器 — v1.0
- ✓ 中英日三语支持 + 游戏内实时语言切换 — v1.0
- ✓ ConfigFile 设置持久化（音量/难度/语言）— v1.0
- ✓ push_error/push_warning 错误处理 — v1.0
- ✓ 公共辅助函数提取（ui_helpers.gd）— v1.0

### Active

*下一里程碑的需求将在 /gsd-new-milestone 中定义。*

### Out of Scope

- 联网对战 — 保持纯本地游戏
- AI 性格差异化（不同策略风格）— 仅分难度级别
- 导出与构建配置 — 不涉及
- 大规模测试套件 — 不涉及
- 自定义棋盘主题/皮肤 — 单一精致主题足够

## Context

**已发布 v1.0**（2026-06-17）。~2,400 行 GDScript，36 个文件。

- **技术栈：** Godot 4.6，纯 GDScript，720×720 视口，canvas_items 拉伸模式
- **架构：** EventBus 驱动的 SSOT 模式。GameManager 是唯一状态源，场景仅负责渲染和输入转发
- **插件：** mc_game_framework（EventBus/UIManager/I18NManager）、GUIDE v0.13.0、SoundManager v2.6.1、GUT v9.6.0
- **已知技术债务：** 4 项 Phase 1 低严重度项目（共享 action 资源、CONNECT_ONE_SHOT 消耗、缺失 EventBus 取消订阅、网格清理迭代）

## Constraints

- **技术栈：** Godot 4.6 + 纯 GDScript，不引入 C# 新代码
- **架构：** 保持 EventBus 驱动的 SSOT 模式，GameManager 始终是唯一状态源
- **渲染：** 2D Canvas 渲染，720×720 视口，canvas_items 拉伸模式
- **依赖：** 使用现有插件（mc_game_framework、GUIDE、SoundManager），不引入新插件

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Minimax 算法替代简易 AI | 当前 AI 逻辑过于简单，Minimax 是井字棋标准解 | ✓ Good — alpha-beta 剪枝 + 三级难度，AI 表现优秀 |
| UIManager 接管 UI 管理 | 当前 main.gd 直接操作 UI 可见性，应改用已注册的 UIManager | ✓ Good — 所有 5 个面板通过 UIManager 栈管理，消除 _show_only() |
| SoundManager 正式接入 | 已注册但从未调用，需配合 kenney_interface_sounds 资源 | ✓ Good — AudioController 桥接 EventBus→SoundManager，8 种音效 + 2 首音乐 |
| 事件订阅资源化 | 消除硬编码脚本路径，提高可维护性 | ✓ Good — 全部改用 StringName（&"EventClassName"）格式 |
| Phase 合并 | Sound+Localization→Phase 0, UI+Animation→Phase 1, AI standalone→Phase 2 | ✓ Good — 基础设施→视觉层→AI 的清晰分层，Phase 1/2 可并行 |
| SoundManager 仅 plugin 注册 | 避免 project.godot [autoload] 重复注册产生编辑器警告 | ✓ Good — 零重复警告 |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition:**
1. Requirements invalidated? → Move to Out of Scope with reason
2. Requirements validated? → Move to Validated with phase reference
3. New requirements emerged? → Add to Active
4. Decisions to log? → Add to Key Decisions
5. "What This Is" still accurate? → Update if drifted

**After each milestone:**
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-06-17 after v1.0 milestone*
