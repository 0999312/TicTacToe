# TicTacToe

一款完整精致的井字棋桌面游戏，基于 Godot 4.6 构建。

## 特性

- **双人对战** — 本地两人轮流落子
- **人机对战** — 基于 Minimax 算法的三级难度 AI
- **完整 UI 流程** — 主菜单 → 对战 → 结算 → 重赛
- **音效与音乐** — 落子、胜利、UI 交互的完整音频反馈
- **视觉动画** — 光标高亮、脉冲动画、胜负连线特效
- **三语支持** — 中文 / English / 日本語 即时切换
- **多输入设备** — 鼠标、键盘、手柄、触屏均可操作

## 技术栈

- **引擎：** Godot 4.6
- **语言：** GDScript
- **渲染：** 2D Canvas，720×720 视口
- **依赖插件：**
  - [mc_game_framework](https://github.com/SyameimaruZheng/mc_game_framework) — 事件总线、UI 管理、国际化、注册表
  - [GUIDE](https://github.com/njamster/guide) — 跨设备输入映射
  - [SoundManager](https://github.com/nathanhoad/godot_sound_manager) — 音频管理
  - [GUT](https://github.com/bitwes/Gut) — 单元测试框架

## 架构

EventBus 驱动的 SSOT（单一状态源）模式：

- `GameManager` (Autoload) — 棋盘状态、回合控制、胜负判定、Minimax AI
- `EventBus` — 跨系统发布/订阅通信
- `Main` — 场景编排、UI 面板切换、输入上下文管理
- `Cell` — 网格格子的视觉呈现与输入转发

## 快速开始

1. 用 Godot 4.6 打开项目
2. 运行 `res://scenes/main.tscn`（已在项目设置中配置为主场景）
3. 选择游戏模式开始对战

## 运行测试

在 Godot 编辑器中切换到 GUT 面板，运行测试套件。

## 许可

MIT License — 详见 [LICENSE](LICENSE)
