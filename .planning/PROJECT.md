# 井字棋

## What This Is

一款完整精致的井字棋桌面游戏，支持本地双人对战和人机对战。拥有流畅的 UI 流程（主菜单→对战→结算）、音效与音乐反馈、视觉动画特效、以及基于 Minimax 算法的三级难度 AI。中英文双语，即刻可玩。

## Core Value

一盘令人愉悦的井字棋 — 从打开游戏到分出胜负，每一步都有清晰的视觉和听觉反馈。

## Requirements

### Validated

- ✓ 本地双人对战（PvP）— 现有
- ✓ 人机对战（PvAI，基础 AI）— 现有
- ✓ 胜负/平局检测 — 现有
- ✓ 棋盘渲染与点击交互 — 现有
- ✓ EventBus 发布/订阅架构 — 现有
- ✓ GUIDE 输入框架集成 — 现有
- ✓ SoundManager 自动加载已注册 — 现有
- ✓ I18NManager 自动加载已注册 — 现有
- ✓ UIManager 自动加载已注册 — 现有

### Active

- [ ] 游戏全程音效反馈（落子、胜利、失败、按钮点击）
- [ ] 背景音乐播放（主菜单、对战中）
- [ ] 音效与音乐独立音量控制
- [ ] 落子动画效果
- [ ] 胜利连线视觉特效
- [ ] 场景过渡动画（淡入淡出）
- [ ] 按钮微交互反馈（悬浮、点击）
- [ ] 主菜单界面（标题、开始按钮、模式选择）
- [ ] 游戏内 HUD（当前玩家指示、比分显示）
- [ ] 结算画面（胜负/平局结果、再来一局、返回菜单）
- [ ] 设置面板（音量、AI 难度、语言切换）
- [ ] Minimax 算法实现（替代当前简易 AI）
- [ ] 三级 AI 难度（简单/中等/困难）
- [ ] 中英文双语支持
- [ ] 游戏内语言切换
- [ ] 消除 EventBus 硬编码脚本路径
- [ ] 添加 `push_error`/`push_warning` 错误处理
- [ ] 减少重复代码，提取公共模式
- [ ] 事件订阅路径迁移至资源化配置

### Out of Scope

- 联网对战 — 保持纯本地游戏
- AI 性格差异化（不同策略风格）— 仅分难度级别
- 导出与构建配置 — 本次不涉及
- 大规模测试套件 — 本次不涉及

## Context

- **技术环境：** Godot 4.6，纯 GDScript，Forward Plus 渲染器，720×720 视口
- **现有架构：** EventBus 驱动的状态管理模式。GameManager 是游戏状态唯一数据源（SSOT），场景仅负责渲染和输入转发
- **现有插件：** mc_game_framework（EventBus/UIManager/I18NManager）、GUIDE v0.13.0（输入）、SoundManager v2.6.1（音频，已注册但未调用）、GUT v9.6.0（测试）
- **现有问题：** SoundManager 和 kenney_interface_sounds（100+ WAV）闲置；EventBus 订阅使用硬编码路径；项目中无 `push_error`/`push_warning` 调用；UIManager 已注册但 UI 直接操作可见性
- **kenney_interface_sounds 音效资源：** 已有完整的 UI 音效素材包，可直接用于按钮、界面交互等音效

## Constraints

- **技术栈：** Godot 4.6 + 纯 GDScript，不引入 C# 新代码
- **架构：** 保持 EventBus 驱动的 SSOT 模式，GameManager 始终是唯一状态源
- **渲染：** 2D Canvas 渲染，720×720 视口，canvas_items 拉伸模式
- **依赖：** 使用现有插件（mc_game_framework、GUIDE、SoundManager），不引入新插件

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Minimax 算法替代简易 AI | 当前 AI 逻辑过于简单，Minimax 是井字棋标准解 | — Pending |
| UIManager 接管 UI 管理 | 当前 `main.gd` 直接操作 UI 可见性，应改用已注册的 UIManager | — Pending |
| SoundManager 正式接入 | 已注册但从未调用，需配合 kenney_interface_sounds 资源 | — Pending |
| 事件订阅资源化 | 消除硬编码脚本路径，提高可维护性 | — Pending |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `/gsd-transition`):
1. Requirements invalidated? → Move to Out of Scope with reason
2. Requirements validated? → Move to Validated with phase reference
3. New requirements emerged? → Add to Active
4. Decisions to log? → Add to Key Decisions
5. "What This Is" still accurate? → Update if drifted

**After each milestone** (via `/gsd-complete-milestone`):
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-06-17 after initialization*
