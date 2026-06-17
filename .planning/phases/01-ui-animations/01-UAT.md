---
status: complete
phase: 01-ui-animations
source: [01-01-SUMMARY.md, 01-02-SUMMARY.md]
started: 2026-06-17T16:30:00Z
updated: 2026-06-17T17:45:00Z
---

## Current Test

[testing complete]

## Tests

### 1. 启动游戏 — 主菜单显示
expected: |
  UIManager 显示的精美主菜单，标题+副标题+4按钮+版本号+菜单音乐+按钮悬停动画
result: pass

### 2. PvP 游戏流程 — 面板切换
expected: |
  场景淡出→HUD面板→Board出现→HUD显示模式+回合→音乐切换breaktime
result: pass

### 3. 游戏进行中 — 落子与回合
expected: |
  点击落子弹跳动画、回合切换、光标高亮跟随鼠标、音效
result: pass

### 4. 游戏结束 — 胜利/平局面板
expected: |
  胜利线动画+格子脉冲+GameOver面板弹出+比分+再来一局/返回菜单
result: pass

### 5. 再来一局 + 返回菜单
expected: |
  再来一局重置棋盘，返回菜单淡出→主菜单，无崩溃，无信号泄漏
result: pass

### 6. 按钮微交互动画
expected: |
  悬停scale 1.05+变亮，按下scale 0.95
result: pass

### 7. Esc 暂停菜单
expected: |
  Esc弹出PauseMenu，音乐音量50%，再Esc恢复
result: pass

### 8. 暂停菜单 — 打开设置 + 返回菜单
expected: |
  Settings从PauseMenu打开不叠加，Back正确返回
result: pass

### 9. 设置面板 — 音频标签页
expected: |
  音量HSlider实时生效，持久化
result: pass

### 10. 设置面板 — 游戏 + 语言标签页
expected: |
  难度按钮底部边框高亮，语言下拉即时切换
result: pass

### 11. 音乐系统
expected: |
  菜单off_to_osaka，游戏breaktime，1s交叉淡入淡出
result: pass

## Summary

total: 11
passed: 11
issues: 0
pending: 0
skipped: 0

## Gaps

### 已修复（UAT 过程中发现并解决）

1. **启动崩溃（_on_init 时机）** — `_on_init()` 在 `add_child()` 前调用，`@onready` 为 null。修复：初始化代码移至 `_ready()`，添加 `_initialized` 防护。
2. **% 唯一名称引用失效** — 场景未设 `unique_name_in_owner`。修复：全部改为 `$` 路径引用。
3. **get_meta 报错** — Godot 4.6 在 meta 不存在时抛错。修复：添加 `has_meta()` 检查。
4. **返回菜单后崩溃** — Cell 未在 `_exit_tree()` 取消 EventBus 订阅。修复：添加 `_exit_tree()` 取消所有订阅。
5. **鼠标输入失效** — UIManager NORMAL 层全屏 dimmer 拦截鼠标事件。修复：HUD 移至 SCENE 层。
6. **再来一局时 GUIDE 上下文未重新启用** — `_on_game_started` 在上下文已存在时跳过了重新启用。修复：始终重新启用上下文。
7. **暂停面板无法弹出** — Board 的 GUIDE 上下文缺少 Esc 映射。修复：添加 Esc 按键映射。
8. **设置滑动条过短** — 修复：设置 `custom_minimum_size = Vector2(200, 0)`。
9. **按钮缩放锚点** — 默认从左上角缩放。修复：设置 `pivot_offset = button.size / 2`。
10. **设置面板布局** — 修复：改为居中布局（preset 8, 400×360）。
11. **难度按钮高亮** — modulate 高亮与悬停动画冲突。修复：改用底部边框指示选中状态。
12. **光标跟随鼠标** — 添加 Cell `mouse_entered` → 更新 cursor_index + 发布 CursorMovedEvent。
