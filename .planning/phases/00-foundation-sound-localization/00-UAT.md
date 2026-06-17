---
status: testing
phase: 00-foundation-sound-localization
source: [00-01-SUMMARY.md, 00-02-SUMMARY.md, 00-03-SUMMARY.md]
started: 2026-06-17T01:45:00Z
updated: 2026-06-17T02:10:00Z
---

## Current Test

number: 5
name: Settings Persist Across Restarts
expected: |
  修改音量设置后退出游戏，重新启动后音量恢复到上次设置的值（不会重置为默认值）。
awaiting: user response

## Tests

### 1. Game Launches Without Errors
expected: 启动游戏后，主菜单正常显示。标题栏显示游戏标题。无报错输出到控制台。所有 autoload 正确初始化。
result: issue
reported: "错误 (18, 1)： The function signature doesn't match the parent."
severity: blocker
fix: SettingsManager.get()/set() 与 Node.get()/Object.set() 签名冲突。重命名为 get_value()/set_value()。已修复 (3e3944b, 6cc631f)。

### 2. Main Menu Text Displays in Chinese (Default Locale)
expected: 主菜单显示中文文本：标题 "井字棋"、按钮 "双人对战"、"人机对战 - 先手"、"人机对战 - 后手"。
result: pass
fix: auto_translate 改为显式 _refresh_all_text() + call_deferred (0e4327d, c9e85cb)

### 3. Audio Plays: Background Music on Startup
expected: 进入主菜单后有背景音乐播放。音量可控（默认 80%）。
result: pass

### 4. Audio Plays: SFX During Gameplay
expected: 落子时有音效反馈（点击音效）。获胜/失败/平局时有对应音效播放。
result: pass

### 5. Settings Persist Across Restarts
expected: 修改音量设置后退出游戏，重新启动后音量恢复到上次设置的值（不会重置为默认值）。
result: skipped
reason: 设置面板在 Phase 1 才会创建，目前无 UI 入口调整音量。SettingsManager 持久化基础设施已就绪（ConfigFile save/load）。

### 6. Translation Files Load Correctly (Structural)
expected: translations/zh_CN.json 和 translations/en_US.json 文件存在且为有效 JSON。两个文件具有相同的键结构。
result: pass
evidence: 00-VERIFICATION.md L10N-01 confirmed — both JSON files exist with identical key structure (21 entries across 4 panels).

### 7. Event System Uses class_name (Structural)
expected: 所有 8 个 Event 类都有 class_name 声明。EventBus 订阅使用 StringName 格式。
result: pass
evidence: 00-VERIFICATION.md FND-01, CQ-01 confirmed — all 8 events have class_name, all subscriptions use &"ClassName" format.

## Summary

total: 7
passed: 5
issues: 1
pending: 0
skipped: 1

## Gaps

- truth: "启动游戏后，主菜单正常显示。无报错输出到控制台。"
  status: resolved
  reason: "SettingsManager.get()/set() 与 Godot 内置 Node.get()/Object.set() 方法签名冲突。重命名为 get_value()/set_value()。"
  severity: blocker
  test: 1
  artifacts: [autoload/settings_manager.gd, autoload/audio_controller.gd, scripts/main.gd]
  fix_commit: 3e3944b
- truth: "主菜单显示中文文本。所有文本使用 MiSans 字体无乱码。"
  status: resolved
  reason: "auto_translate 不可靠。替换为 _refresh_all_text() 显式 tr() 设置 + call_deferred 延迟。"
  severity: blocker
  test: 2
  artifacts: [scripts/main.gd]
  fix_commit: 0e4327d, c9e85cb
