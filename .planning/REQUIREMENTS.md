# Requirements: 井字棋

**Defined:** 2026-06-17
**Core Value:** 一盘令人愉悦的井字棋 — 从打开游戏到分出胜负，每一步都有清晰的视觉和听觉反馈

## v1 Requirements

Requirements for the polish milestone. Each maps to roadmap phases.

### Foundation

- [ ] **FND-01**: EventBus 脚本路径使用 StringName 常量替代硬编码字符串
- [ ] **FND-02**: 移除 SoundManager 双重注册，验证单例正确性
- [ ] **FND-03**: 创建 AudioBusLayout（SFX / Music / UI 三条总线）
- [ ] **FND-04**: 项目代码添加 `push_error`/`push_warning` 错误处理

### UI

- [ ] **UI-01**: 主菜单界面 — 标题、双人对战/人机对战按钮、设置按钮、退出按钮
- [ ] **UI-02**: 游戏内 HUD — 当前玩家提示（X/O）、比分显示（X胜/O胜/平局）
- [ ] **UI-03**: 结算面板 — 结果显示（谁胜/平局）、再来一局、返回菜单按钮
- [ ] **UI-04**: 设置面板 — 音效/音乐音量滑块、AI 难度选择、语言切换
- [ ] **UI-05**: 所有 UI 面板使用 UIManager 栈式管理替代 `_show_only()` 直接操作

### Sound

- [ ] **SND-01**: 游戏 SFX 播放 — 落子音效、胜利音效、失败音效、平局音效
- [ ] **SND-02**: 按钮交互音效 — 点击音效、悬浮音效（使用 kenney_interface_sounds）
- [ ] **SND-03**: 背景音乐 — 主菜单音乐、对战中音乐，支持淡入淡出切换
- [ ] **SND-04**: 音效与音乐独立音量控制，设置面板滑块调节

### AI

- [ ] **AI-01**: Minimax 算法实现（含 alpha-beta 剪枝）
- [ ] **AI-02**: 三级难度 — 简单（随机）、中等（深度限制+随机注入）、困难（完整搜索）
- [ ] **AI-03**: AI 思考延迟差异化（简单 0.5-1.0s、中等 0.3-0.6s、困难 0.2-0.4s）
- [ ] **AI-04**: 设置面板 AI 难度选择器

### Animation

- [ ] **ANM-01**: 胜利连线动画 — Tween 绘制高亮线条划过获胜行/列/对角线
- [ ] **ANM-02**: 落子动画 — X/O 棋子 scale 从 0 弹跳到 1
- [ ] **ANM-03**: 场景过渡 — 菜单↔对战的淡入淡出效果（CanvasLayer + ColorRect）
- [ ] **ANM-04**: 按钮微交互 — 悬浮时轻微缩放/颜色变化

### Localization

- [ ] **L10N-01**: 中英文翻译文件（JSON 格式，ASCII-only key ID）
- [ ] **L10N-02**: CJK 字体后备支持（Noto Sans SC 或等效）
- [ ] **L10N-03**: 游戏内语言切换（设置面板），实时生效
- [ ] **L10N-04**: 所有 UI 文本使用 `tr()` 函数，自动翻译模式

### Code Quality

- [ ] **CQ-01**: 消除所有 `preload("res://...")` 硬编码路径，改用 `@export` 或常量
- [ ] **CQ-02**: 所有 GameManager 公共方法添加参数校验和 `push_warning`
- [ ] **CQ-03**: 提取重复代码至共享辅助函数
- [ ] **CQ-04**: 设置持久化 — ConfigFile 保存/加载音量、难度、语言选择

## v2 Requirements

Deferred to future release.

- **ONL-01**: 联网对战（ENet/WebSocket）
- **UNDO-01**: 悔棋功能（仅限 PvP）
- **TUTO-01**: 新手引导
- **THEME-01**: 可自定义棋盘主题

## Out of Scope

| Feature | Reason |
|---------|--------|
| AI 性格差异化（策略风格） | 仅分难度级别，不区分策略风格 |
| 导出与构建配置 | 本次不涉及 |
| 大规模测试套件 | 本次不涉及，GUT 框架已在位待后续 |
| 撤消/悔棋 | v1 保持简洁，v2 考虑 |
| 联网对战 | 纯本地游戏，10x 范围扩张 |
| 成就/徽章系统 | 依赖外部平台，超出项目范围 |
| 6x6/4x4 棋盘模式 | 保持标准 3x3 井字棋 |
| 自定义棋盘主题/皮肤 | 单一精致主题即可 |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| All | Phase 0-5 | Pending |

**Coverage:**
- v1 requirements: 25 total
- Mapped to phases: TBD
- Unmapped: TBD

---
*Requirements defined: 2026-06-17*
*Last updated: 2026-06-17 after initial definition*
