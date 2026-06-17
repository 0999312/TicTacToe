# Phase 1: UI & Animations - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-17
**Phase:** 01-UI & Animations
**Areas discussed:** UIManager 迁移方式, 动画风格与节奏, 设置面板布局与交互, 游戏音乐转接, 主菜单布局与存档信息

---

## UIManager 迁移方式

| Option | Description | Selected |
|--------|-------------|----------|
| 独立场景 + UIPanel | 每个面板独立 .tscn，继承 UIPanel，通过 UIManager.open_panel() 管理 | ✓ |
| 保持单场景 + UIManager | 面板留在 main.tscn，改为继承 UIPanel | |
| 混合方式 | 简单面板留在 main.tscn，复杂面板独立场景 | |

**User's choice:** 独立场景 + UIPanel (Recommended)
**Notes:** 符合 mc_game_framework 设计意图，创建 4+ 新场景文件（MainMenu, HUD, GameOver, Settings, PauseMenu, Board）

**Follow-up decisions:**
- 迁移节奏: 一次性全部替换（不保留旧 `_show_only()` 代码）
- 面板层级: HUD 在 NORMAL 层始终可见，GameOver 以 POPUP 层覆盖 HUD，MainMenu/PauseMenu/Settings 在 NORMAL 层互斥
- Board 也拆为独立场景，main.tscn 只做根容器
- 面板通信: EventBus + GameManager，面板不直接调用 GameManager
- GUIDE: 每面板独立创建/销毁 GUIDEMappingContext
- UIRegistry: 显式注册面板路径

---

## 动画风格与节奏

| Option | Description | Selected |
|--------|-------------|----------|
| 轻快活泼 | 弹性明显，落子 scale 0→1.2→1 (0.25s)，胜利线 0.4s，过渡 0.3s | ✓ |
| 简约克制 | 动画极简，无弹跳，快速反馈 | |
| 华丽丰富 | 多层次动画，粒子/光晕效果 | |

**User's choice:** 轻快活泼 (Recommended)
**Notes:** 适合休闲桌面游戏的氛围

**Follow-up decisions:**
- 胜利连线: 划线 + 高亮格子（双层次反馈）
- 场景过渡: ColorRect 淡入淡出
- 按钮微交互: 缩放 + 颜色变化（hover scale 1.05 + 变亮，press scale 0.95）

---

## 设置面板布局与交互

| Option | Description | Selected |
|--------|-------------|----------|
| 选项卡式 | TabBar 切换 Audio / Game / Language 选项卡 | ✓ |
| 竖排列表 + 分组标题 | 三组竖排，每组 Label 标题 | |

**User's choice:** 选项卡式
**Notes:** 即使用户设置项不多，用户偏好结构化组织

**Follow-up decisions:**
- 音量: HSlider + 实时预览 + 百分比 Label
- AI 难度: 三个独立按钮（Easy / Medium / Hard）
- 语言: OptionButton 下拉菜单（中文 / English / 日本語）
- 生效时机: 即时生效 + 关闭面板时持久化（利用 Phase 0 SettingsManager）
- 新增 PauseMenu 面板（Esc 弹出，恢复/设置/返回主菜单三个按钮）
- 设置面板可从主菜单和暂停菜单两个入口进入
- 返回按钮统一 pop 到上层
- ja_JP 日语支持在本 Phase 一并完成

---

## 游戏音乐转接

| Option | Description | Selected |
|--------|-------------|----------|
| 引入新曲目 | 新增第二首 BGM，菜单和对战分别播放不同曲目 | ✓ |
| 仅用现有曲目 | 共用 off_to_osaka.mp3 | |

**User's choice:** 引入新曲目
**Notes:** `music/breaktime.mp3` 已存在于项目中，是用户提前准备的

**Follow-up decisions:**
- 曲目分配: 菜单 = off_to_osaka.mp3 / 对战 = breaktime.mp3
- Crossfade 时长: 1.0-1.5s
- 暂停行为: 音乐音量降至当前设置值的 50%（当前音量过低则不降）

---

## 主菜单布局与存档信息

| Option | Description | Selected |
|--------|-------------|----------|
| 居中竖排 | 标题顶部居中，按钮竖排居中 | ✓ |
| 左右分栏 | 左侧标题+装饰，右侧按钮栏 | |

**User's choice:** 居中竖排 (Recommended)
**Notes:** 适合 720x720 方窗

**Follow-up decisions:**
- 存档信息: 仅版本号（底部小字 v0.1.0），不显示比分
- 标题: 大字 "井字棋" + 副标题 "Tic-Tac-Toe"
- 按钮: 4 按钮竖排 [双人对战] [人机对战] [设置] [退出游戏]
- 比分: 在 HUD（三列并排: X胜/O胜/平局）和结算面板显示

---

## Claude's Discretion

- Tween 缓动曲线具体选择（在轻快活泼约束内）
- 按钮 hover/press 的 modulate 颜色值
- 设置面板 TabBar 视觉样式
- 各面板内部 spacing 和 label 位置细节
- PauseMenu 背景变暗程度（建议 50% 黑色叠加）
- breaktime.mp3 与 off_to_osaka.mp3 的音量均衡

## Deferred Ideas

None — 讨论内容均在 Phase 1 范围内。ja_JP 支持和 PauseMenu 面板是讨论中自然浮现的合理扩展。
