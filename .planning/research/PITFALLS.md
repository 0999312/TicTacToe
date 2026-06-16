# Domain Pitfalls: 井字棋 Polish Phase

**Domain:** Godot 4.6 2D game polish (audio, animation, UI, AI, localization)
**Researched:** 2026-06-17
**Overall confidence:** HIGH

---

## Critical Pitfalls

Mistakes that cause rewrites, data loss, or major debugging sessions.

### Pitfall 1: SoundManager Integration Without Audio Bus Architecture

**What goes wrong:**
SoundManager is registered as an autoload but never called. When audio is finally added, developers dump all sounds onto the Master bus, leading to no individual volume control for SFX vs. music, no ducking, no effect chains. Audio becomes a tangled, unbranchable mess.

**Why it happens:**
SoundManager's API provides `play_ui_sound()` and `play_music()` but does not force you to set up audio buses. The path of least resistance is to skip bus setup entirely. Godot's default project has only a Master bus, so every sound competes on the same channel.

**Consequences:**
- Cannot mute music independently from SFX
- Cannot apply reverb/compression to only one category
- Volume sliders in settings require workarounds (per-stream volume tracking) instead of a simple `set_bus_volume_db()`
- Mid-project bus addition requires re-wiring every call site

**Prevention:**
Create a proper audio bus layout BEFORE writing any SoundManager calls in game code:

```
Master
  ├── Music     (BGM tracks, crossfade-enabled)
  ├── SFX       (gameplay sounds: place, win, draw)
  ├── UI        (button clicks, menu navigation sounds)
  └── Ambient   (future-proofing, empty for now)
```

Use `AudioServer.get_bus_index("Music")` in SoundManager calls. Never hardcode bus indices. The Lefrec fork of SoundManager (v2.6.1) supports four distinct buses natively.

**Detection:**
- No AudioBusLayout resource in the project (default layout)
- SoundManager calls pass no bus argument or always pass `"Master"`
- Volume slider code tracks individual AudioStreamPlayer volumes instead of using AudioServer bus volumes

**Which phase should address it:**
Phase 1 (Audio Integration). Must be done first — retrofitting buses after SFX calls are scattered across the codebase creates regressions.

---

### Pitfall 2: Tween Lifecycle Management (Killed/Orphaned Tweens)

**What goes wrong:**
Tweens are created in `_process()` or signal handlers without storing a reference. Old tweens accumulate, conflicting with new animations. When a scene changes, orphaned tweens targeting freed nodes cause crashes or silent failures. The `finished` signal never fires on killed tweens, causing `await tween.finished` to hang forever.

**Why it happens:**
Godot 4's Tween API is cleaner than Godot 3's, but its lifecycle rules are subtle:
- `tween.kill()` does NOT set the variable to `null` — the reference still points to an invalid Tween
- `is_instance_valid(tween)` returns `true` for a killed-but-referenced Tween (it's not freed, just invalidated)
- `get_tree().create_tween()` creates a tween NOT bound to any node — it survives the node being freed
- `Node.create_tween()` (no qualifier) binds the tween to `self`, auto-killing when the node exits the tree

**Consequences:**
- UI buttons stop animating after a few clicks (accumulated conflicting tweens)
- Scene transitions freeze because `await overlay_tween.finished` never resolves
- Error spam: "Attempt to call function 'tween_property' in dead Tween"
- Crash when a freed node's tween tries to animate a property

**Prevention pattern (hard rule for all animations):**

```gdscript
# CORRECT pattern for all in-code animations
var _tween: Tween

func _animate_something():
    _kill_tween()                           # kill previous if any
    _tween = create_tween()                 # Node.create_tween() — auto-bound to self
    _tween.tween_property(...)
    _tween.finished.connect(_on_anim_done, CONNECT_ONE_SHOT)

func _kill_tween():
    if _tween and _tween.is_running():
        _tween.kill()
    _tween = null                           # ALWAYS null after kill
```

**Warning signs:**
- Repeated error output about "dead Tween" or "invalid Tween"
- `await tween.finished` blocking forever (check if tween was killed)
- Multiple tweens visible in the Debugger > Tweens tab
- UI flickers because old and new tweens fight over the same property

**Which phase should address it:**
Every animation phase. Enforce the pattern in a project-wide `_kill_tween()` helper or a single `AnimationHelper` autoload.

---

### Pitfall 3: Animating Control Nodes Inside Containers

**What goes wrong:**
You tween a Button's `position` while it sits inside an HBoxContainer or VBoxContainer. The container re-applies its layout every frame, fighting the tween. The result: elements snap back, stutter, or animate to a completely wrong position.

**Why it happens:**
Container nodes call `force_fit()` during `NOTIFICATION_SORT_CHILDREN`, which overwrites child positions every frame. Tweens that modify `position` on container children are fighting an unwinnable battle against the layout system.

**Consequences:**
- Button slide-in animations jerk or reset to container position
- Panel transitions look broken and behave differently depending on window size
- Debugging is confusing because position values change every frame

**Prevention:**
Never animate `position` or `size` on Control nodes that are children of containers. Use one of these strategies:

1. **Wrapper Control approach (recommended for this project):**
   Place a plain `Control` node outside the container as the animation host. Put the animatable element inside it. Tween the wrapper's `position`.
   
2. **Modulate approach for fade only:**
   If the animation is just alpha/fade, tween `modulate.a` — containers do not fight `modulate`.
   
3. **Use AnimationPlayer on anchor-based layouts:**
   For complex UI, use anchors instead of containers for the animated section, then animate with AnimationPlayer keyframes (with resolution-change caveat — see Pitfall 5).

**Detection:**
- A tween'd element's position resets every frame
- Add `print(position)` in `_process()` — if it changes without your code touching it, a container is fighting you
- Node is a child of BoxContainer/GridContainer/etc.

**Which phase should address it:**
Phase 3 (UI Polish). The main menu, HUD, and results screen all use container-arranged buttons. Check each animated element's parent before writing tween code.

---

### Pitfall 4: Fade Transition Flicker (CanvasLayer + Root Modulate)

**What goes wrong:**
You implement a fade-to-black transition by tweening `get_tree().root.modulate.a` from 1 to 0, then changing the scene, then tweening back. The fade transition works on most elements but some UI panels flash fully visible before the overlay appears. Or the transition overlay layer doesn't cover the new scene during swap.

**Why it happens:**
- `CanvasLayer` nodes draw on a separate rendering canvas — they are NOT affected by `root.modulate`. HUDs and UI overlays inside CanvasLayers remain fully opaque while everything else fades.
- Scene transition timing: if `change_scene_to_file()` is called before the fade-out overlay is fully opaque, the old scene is removed and the new scene appears behind a semi-transparent overlay, creating a visible "flash" of the new scene.
- Layer ordering: if the overlay ColorRect is on layer 1 and the game HUD is on layer 2, the overlay draws BEHIND the HUD.

**Consequences:**
- CanvasLayer-based HUD never fades out — breaks immersion
- New scene "pops in" before fade-in completes
- Transition appears glitchy on first run

**Prevention:**
Use a dedicated transition autoload (CanvasLayer with layer = 128, guaranteed above everything):

```gdscript
# transition_autoload.gd
extends CanvasLayer

var _overlay: ColorRect

func _ready():
    layer = 128  # above all game layers
    _overlay = ColorRect.new()
    _overlay.color = Color(0, 0, 0, 0)
    _overlay.anchors_preset = Control.PRESET_FULL_RECT
    _overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(_overlay)

func fade_transition(next_scene: String, duration: float = 0.3) -> Signal:
    # Fade OUT (to black)
    var t = create_tween()
    t.tween_property(_overlay, "color:a", 1.0, duration)
    await t.finished
    # Swap scene while fully black
    get_tree().change_scene_to_file(next_scene)
    await get_tree().process_frame  # wait for new scene to initialize
    # Fade IN (from black)
    t = create_tween()
    t.tween_property(_overlay, "color:a", 0.0, duration)
    return t.finished
```

**Detection:**
- HUD elements visible during fade-out
- Scene visible before fade-in overlay is ready
- Overlay appears behind UI elements

**Which phase should address it:**
Phase 3 (UI Polish). Implement the transition autoload before wiring scene-change buttons.

---

### Pitfall 5: AnimationPlayer RESET Track Causes Size Explosion in Containers

**What goes wrong:**
A Control node inside a Container has an AnimationPlayer with a RESET animation track. After switching scenes and returning, the node's size multiplies (2x, 3x, 4x) each time. The UI grows uncontrollably.

**Why it happens:**
Confirmed Godot 4.0-4.2 bug (GitHub #90079) where RESET animation tracks on container children interact badly with anchor/container layout recalculations. The RESET track re-applies cached size values that conflict with the container's layout pass, causing exponential growth on each scene reload.

**Consequences:**
- Buttons become gigantic after 2-3 scene transitions
- UI is completely broken, requiring editor restart
- Extremely confusing to debug (looks like a layout bug, not an animation bug)

**Prevention:**
For this project (Godot 4.6 — check if still present):
1. Prefer `Tween` over `AnimationPlayer` for all UI animations in this project
2. If using AnimationPlayer, do NOT create RESET tracks on Control nodes that are children of containers
3. If RESET tracks are necessary, use a non-container layout (anchors only) for those nodes

**Detection:**
- UI size doubles/triples after scene transition and return
- Occurs specifically with Container + AnimationPlayer(RESET) combination

**Which phase should address it:**
Phase 3 (UI Polish). When adding button hover animations or panel entrance animations, choose Tween over AnimationPlayer to avoid this class of bugs entirely.

---

### Pitfall 6: Minimax Synchronous Block Without Frame Budgeting

**What goes wrong:**
The Minimax algorithm blocks the main thread during AI computation. While tic-tac-toe's state space is tiny (max 9! ~ 362,880 positions, realistically far fewer), the synchronous call blocks input processing and frame rendering. If the AI is later extended to support larger boards, this becomes a freeze.

**Why it happens:**
The current `_find_best_move()` calls `_minimax()` recursively in a single synchronous call. The Timer timeout that triggers AI moves does not help — the work still happens on the main thread within that timeout callback.

**Consequences:**
- Frame drop during AI move calculation (currently imperceptible for 3x3)
- Pattern encourages copying this synchronous approach for other AI work
- No cancellation support (once started, the AI calculation cannot be interrupted)
- No progress reporting

**Prevention:**
For 3x3 tic-tac-toe, the synchronous approach is fine. But the code should be explicitly hardened:

1. Add `push_warning()` with timing to detect if AI ever takes >16ms (one frame):
   ```gdscript
   var start_time = Time.get_ticks_usec()
   var result = _minimax(board, depth, is_maximizing)
   var elapsed = Time.get_ticks_usec() - start_time
   if elapsed > 16000:
       push_warning("AI move took ", elapsed / 1000.0, "ms — consider async")
   ```
2. Extract board state before calling Minimax (defensive copy) so the AI is not affected by game state changes during computation
3. Tag the function as `## @intentionally_synchronous` for maintainers

**Do NOT prematurely multi-thread:** For tic-tac-toe, WorkerThreadPool overhead exceeds computation time. The forum consensus is that multithreading is counterproductive for trivial state spaces.

**Detection:**
- Frame time spike during AI turn (visible in Debugger > Monitor > Process > Frame Time)
- Player input feels "sticky" right after placing a piece against AI

**Which phase should address it:**
Phase 4 (AI Upgrade). Add the timing guardrail and defensive copy as part of the Minimax rewrite.

---

### Pitfall 7: Localization Key Using Non-ASCII Characters (Android Export)

**What goes wrong:**
Translation CSV files use Chinese characters in the key column (e.g., `双人对战,Two Players`). Works perfectly on Windows/macOS. On Android export, all translations return empty strings.

**Why it happens:**
Confirmed Godot 4 bug (GitHub #107875, #106246): the CSV-to-translation importer on Android does not correctly handle non-ASCII keys. If the keys column contains Chinese, Japanese, Cyrillic, or other non-Latin characters, the translations silently fail on Android.

**Consequences:**
- App passes QA on desktop, ships with broken translations on mobile
- Extremely hard to reproduce without an Android device

**Prevention:**
Use ASCII-only keys in the CSV `keys` column. Put source text in a dedicated column:

```csv
keys,zh,en
pvp_title,双人对战,Two Players
pvai_first,人机对战 - 先手,PvAI - First
```

Never use: `双人对战,Two Players` — that puts Chinese in the key column.

For this project specifically, all current user-facing text is in Chinese. A text audit must convert these to ASCII keys before creating the translation files.

**Detection:**
- Translation CSV has non-ASCII characters in the first column
- `tr()` calls use translated text as the key instead of a key ID
- Current code passes Chinese strings directly to `tr()` (e.g., `tr("双人对战")`)

**Which phase should address it:**
Phase 5 (Localization). Must include a full text audit that converts every `tr("Chinese text")` call to `tr("key_id")` with the translation CSV mapping keys to both languages.

---

### Pitfall 8: EventBus Hardcoded Paths + No Error Handling = Silent Failures

**What goes wrong:**
EventBus subscriptions use `EventBus.subscribe("res://scripts/events/cell_placed_event.gd", callback)`. If the event file is moved or renamed, the subscription silently stops working. The callback never fires. The game appears to work but nothing happens when clicking cells.

Worse, there is zero error handling (no `push_error`, no `push_warning`). If `place_mark()` returns `false`, no code logs it. The failure is invisible.

**Why it happens:**
The original code was written assuming files would never move. Since there's no error handling, failures produce no output. The user sees "click does nothing" with no console clues.

**Consequences:**
- Refactoring event files breaks the game silently
- Invalid game states (e.g., clicking an occupied cell) produce no feedback
- Debugging requires scrutinizing every EventBus subscription call site

**Prevention:**
1. Replace hardcoded paths with UID references or class constants:
   ```gdscript
   const CELL_PLACED_EVENT = preload("res://scripts/events/cell_placed_event.gd")
   EventBus.subscribe(CELL_PLACED_EVENT, _on_cell_placed)
   ```
2. Add error handling wrappers around every EventBus call:
   ```gdscript
   var success = EventBus.publish(event)
   if not success:
       push_error("EventBus.publish failed for ", event)
   ```
3. Add an `assert()` in test mode to verify all subscription paths resolve at startup

**Detection:**
- Event callbacks never fire after file moves/renames
- Empty error output (the problem is lack of errors — silent failure)
- Debugger showing no EventBus activity when interactions happen

**Which phase should address it:**
Phase 0 (Foundation/Cleaning). Must be done before adding new features because new feature code will copy the broken pattern.

---

### Pitfall 9: UIManager Bypass — Direct Visibility Management

**What goes wrong:**
The project has UIManager registered as an autoload (from mc_game_framework) but `main.gd` directly manages panel visibility via `_show_only()` using reference equality checks. When the UIManager is eventually integrated, the existing `_show_only()` calls create a dual-management problem — both UIManager and manual code toggle visibility, fighting each other.

**Why it happens:**
The original developer either didn't understand UIManager's API or found direct visibility management faster. Now there are ~50 lines of manual panel logic that would need to be replaced.

**Consequences:**
- Adding UIManager integration breaks existing panel transitions
- Stack-based panel history (back buttons, escape-to-close) doesn't work because the manual code doesn't track history
- Two systems controlling the same panels = toggling war

**Prevention:**
1. Audit all `show()`/`hide()` calls in `main.gd` before refactoring
2. Replace ALL panel visibility management in a single atomic commit — not piecemeal
3. Use UIManager's stack-based API for all navigations:
   - `UIManager.push_panel(panel_node)` to show
   - `UIManager.pop_panel()` to go back
   - `UIManager.swap_panel(new_panel)` for non-stack transitions

**Detection:**
- `main.gd` has direct `.show()` / `.hide()` calls on panels
- `_show_only()` function exists
- No calls to `UIManager` methods despite UIManager being registered

**Which phase should address it:**
Phase 0 (Foundation/Cleaning). Must be resolved before Phase 3 (UI Polish) or the new UI features will be built on top of the broken system.

---

## Moderate Pitfalls

### Pitfall 10: `AnimationPlayer.animation_finished` Signal Not Emitting

**What goes wrong:**
You connect to `AnimationPlayer.animation_finished` to trigger an action after an animation completes. The signal never fires. Code after `await animation_player.animation_finished` blocks forever.

**Why it happens:**
Multiple Godot 4 scenarios suppress `animation_finished`:
- When using `AnimationTree` (signals go to AnimationTree, not AnimationPlayer)
- When chaining with `queue()` (signal only fires for the entire chain, not per-animation)
- With custom timelines or `stretch_time_scale` (GitHub #94459)
- In crossfade blends (signals are suppressed during xfade)

**Prevention:**
For this project's simple animation needs, use `Tween` with `tween.finished` (see Pitfall 2 for safe pattern) instead of AnimationPlayer for code-triggered animations. If AnimationPlayer is necessary (e.g., complex keyframed animation), add a Call Method Track at the end of the animation as a reliable fallback — method tracks always fire regardless of signal suppression.

**Warning signs:**
- `await animation_player.animation_finished` hangs
- `animation_finished` signal never fires in debugger
- Using both AnimationPlayer and AnimationTree

**Which phase should address it:**
All animation phases. Default to Tween for the code-driven animations in this project (piece placement, button feedback). Use AnimationPlayer only for scenes where keyframe precision is needed (e.g., win line reveal).

---

### Pitfall 11: Audio Finished Signal Not Firing on Scene Change

**What goes wrong:**
A sound effect is playing when a scene transition occurs (e.g., win sound then transition to results screen). The sound cuts off abruptly. Waiting for `await audio_player.finished` before changing scenes hangs if the AudioStreamPlayer node gets freed during scene swap.

**Why it happens:**
- Scene change deletes all nodes in the current scene, including AudioStreamPlayers
- If the AudioStreamPlayer is a child of the current scene, it is destroyed mid-play
- The `finished` signal never fires on a destroyed node
- Web exports have additional issues where the `finished` signal doesn't fire with "Sample" playback type (GitHub #93904)

**Prevention:**
1. Critical sounds (win, lose) should play via the SoundManager autoload, not scene-local AudioStreamPlayers. Autoloads persist across scene changes.
2. For scene transitions triggered by sound completion:
   ```gdscript
   SoundManager.play_ui_sound("win")
   await get_tree().create_timer(0.5).timeout  # fixed delay, not signal-dependent
   TransitionLayer.fade_to_scene("res://results.tscn")
   ```
3. Alternatively, check `is_playing()` in a loop with a safety timeout.

**Detection:**
- Sound cuts off during scene transition
- Game hangs because `await audio_player.finished` never resolves

**Which phase should address it:**
Phase 1 (Audio Integration) combined with Phase 3 (UI Polish, scene transitions). The sound management must be designed to work with scene transitions from the start.

---

### Pitfall 12: Mixing Control and Node2D/Sprite2D in UI Hierarchy

**What goes wrong:**
A background sprite for the main menu uses `Sprite2D` as a child of a `Control` node. On different screen sizes, the sprite doesn't align with the Control-based buttons. Positioning is inconsistent.

**Why it happens:**
Control nodes and Node2D nodes use different layout systems. Control nodes use anchors, containers, and rect-based positioning. Node2D nodes use pixel positions. A Sprite2D inside a Control hierarchy inherits the Control's transform but does not participate in anchor/container layout, so it doesn't adapt to screen size changes.

**Prevention:**
For this project (720x720 fixed viewport with `canvas_items` stretch mode, so screen size is fixed), this is less critical. But as a best practice:
- Use `TextureRect` (Control node) instead of `Sprite2D` for UI images
- Use `NinePatchRect` for scalable UI panels
- Use `ColorRect` for colored backgrounds
- Keep Sprite2D/Node2D only in gameplay areas, not UI

**Detection:**
- UI scene has Sprite2D nodes as children of Panel/Control nodes
- Visual elements don't resize with the window

**Which phase should address it:**
Phase 3 (UI Polish). During the main menu and HUD redesign, audit all node types.

---

### Pitfall 13: Input Handling — Mixed Keyboard/Controller Without Unified Abstraction

**What goes wrong:**
The game uses GUIDE for cursor-style input (arrow keys/WASD for navigation, space/enter for confirm). When adding mouse click support for cell placement, the two input systems have separate code paths. Mouse clicks go through Area2D `_input_event()` while keyboard navigation goes through GUIDE. The cursor and mouse can get out of sync — clicking a cell doesn't move the keyboard cursor, and keyboard cursor position doesn't affect mouse hover state.

**Why it happens:**
GUIDE and Godot's built-in input system are parallel input pipelines. They don't automatically coordinate. Without an abstraction layer that consolidates both input sources into a single "input event" bus, the two systems diverge.

**Prevention:**
1. Route ALL input through a single `InputHandler` abstraction that normalizes keyboard, mouse, and (future) controller input into game actions
2. The cursor should always reflect the last-used input method's state
3. For this project's simple grid: mouse click on a cell = cursor moves to that cell + selects it. This keeps cursor and mouse in sync.

**Detection:**
- Clicking a cell doesn't update the keyboard highlight
- Mouse and keyboard can select different cells simultaneously
- Two code paths for "player placed a piece" — one for keyboard, one for mouse

**Which phase should address it:**
Phase 2 (Gameplay Polish). The cell click interaction needs mouse support to coexist with existing keyboard/GUIDE input.

---

### Pitfall 14: CSV Translation Duplicate UIDs After Reimport

**What goes wrong:**
After editing a translation CSV and reimporting, Godot generates duplicate or invalid UIDs for `.translation` files. Some translations stop working. Deleting `.godot/` cache fixes it temporarily but the problem returns.

**Why it happens:**
A Godot 4.4+ bug (GitHub #103118) where the CSV importer produces negative or duplicate UIDs. The translation resource references become inconsistent after reimport.

**Prevention:**
1. Add `*.translation` to `.gitignore` — these are regenerated from CSV on import and should not be version-controlled
2. After CSV edits, restart Godot to force clean reimport
3. Consider using `.po` (gettext) files instead of CSV if UID issues become persistent — `.po` files have more mature tooling and fewer import bugs
4. Save a backup of the CSV before major edits

**Detection:**
- Console errors about duplicate UIDs after CSV reimport
- Some translations stop resolving after editing the CSV
- `.translation` files have negative numbers in filenames

**Which phase should address it:**
Phase 5 (Localization). Add `.translation` to `.gitignore` as part of the localization setup, before creating the CSV file.

---

### Pitfall 15: SoundManager `Engine.register_singleton()` Redundancy

**What goes wrong:**
SoundManager.gd calls `Engine.register_singleton()` in its `_init()` (line 41), but the plugin is also registered as a project autoload. In some Godot versions, this double-registration causes a warning or error on project startup.

**Why it happens:**
The SoundManager addon was written to work both as a standalone singleton AND as an autoload. The redundant protection causes issues when both mechanisms are active.

**Prevention:**
Remove the `Engine.register_singleton("SoundManager", self)` call from `sound_manager.gd:_init()`. The autoload registration in `project.godot` already handles singleton creation.

**Detection:**
- Console warning about "already registered singleton" on project load
- Debugger shows duplicate SoundManager entries

**Which phase should address it:**
Phase 0 (Foundation/Cleaning). Fix this before writing any SoundManager calls to avoid confusion about which SoundManager instance is being called.

---

## Minor Pitfalls

### Pitfall 16: BGM File Too Large for a Tic-Tac-Toe Game

The existing `music/off_to_osaka.mp3` is 4MB. For a casual tic-tac-toe game, this dominates the export size. The entire game logic is <100KB; the BGM is 40x larger.

**Prevention:**
Re-encode at 128kbps or lower (current bitrate unknown). Or use Ogg Vorbis (`.ogg`) format, which Godot handles natively and compresses better than MP3 for music.

### Pitfall 17: Kenney Interface Sounds as a Dead Asset Dump

100+ WAV files (~3.5MB) in `addons/kenney_interface_sounds/` with no plugin code, no import pipeline, and no references. If left untouched, these are dead weight. If wires are added haphazardly (e.g., copying random files to the project root), the file organization becomes a mess.

**Prevention:**
Create an `assets/audio/sfx/` directory with a purpose-built subset of the Kenney sounds. Import only the sounds you need (place, win, draw, button_click, hover, cancel). Leave the full dump in `addons/` for reference but do not reference files from there directly — copy them to the project's own asset directory.

### Pitfall 18: No Error Handling in Polish Code Addition

New code for animations, audio, and UI tends to follow the existing pattern of zero error handling. A tween fails silently, an audio stream doesn't load, a translation key is missing — no `push_error`, no `push_warning`, no user feedback.

**Prevention:**
Add a project standard: every new function in this polish phase MUST include at least one error check with `push_error()` or `push_warning()`. Enforce via code review checklist:

- [ ] Audio: `push_error` if stream is null
- [ ] Tween: check `is_instance_valid(tween)` before operations
- [ ] Translation: `push_warning` if `tr()` returns the key itself (means missing translation)
- [ ] EventBus: `push_error` if publish/subscribe returns false
- [ ] File loads: `push_error` if `preload()` or `load()` returns null

### Pitfall 19: Kenney Sound Import Settings (WAV + Loop Mode)

Godot imports WAV files with specific defaults. Kenney sounds are UI clicks — they are short, one-shot sounds. If the import preset adds looping by default, clicks become drones. Also, Godot's WAV import can leave unwanted loop metadata if the WAV contains loop points.

**Prevention:**
After copying selected Kenney sounds to `assets/audio/sfx/`, batch-select them in the FileSystem dock and set Import > Loop Mode to "Disabled" and Force > Max Rate to 44100 Hz (or match the project's mixer rate). Verify each plays correctly in the editor before wiring.

### Pitfall 20: Relying on `Input.is_action_just_pressed()` for One-Shot Animations

When a button uses `Input.is_action_just_pressed("click")` to trigger an animation, the animation can trigger multiple times if the input event lasts longer than one frame. The button animation restarts repeatedly, creating a stuttering effect.

**Prevention:**
Always gate animation triggers with a cooldown or state check:

```gdscript
var _animating := false

func _on_button_pressed():
    if _animating:
        return
    _animating = true
    var tween = create_tween()
    tween.tween_property(self, "scale", Vector2(1.1, 1.1), 0.1)
    tween.tween_property(self, "scale", Vector2.ONE, 0.1)
    await tween.finished
    _animating = false
```

### Pitfall 21: Hardcoded Viewport Size Assumptions in Animation Values

Animations that use pixel values (e.g., tween position to `Vector2(360, 400)`) work at 720x720 but break if the viewport or stretch mode changes. For this project, the viewport is fixed at 720x720, but the Stretch Mode is `canvas_items` which can behave differently on high-DPI displays.

**Prevention:**
Use `get_viewport_rect().size` to derive animation endpoints:

```gdscript
var vp_size = get_viewport_rect().size
var center_x = vp_size.x / 2
var offscreen_right = vp_size.x + 100
```

Tag hardcoded pixel values with a comment: `# HARDCODED: assumes 720x720 viewport`.

---

## Phase-Specific Warnings

| Phase | Topic | Likely Pitfall | Mitigation |
|-------|-------|---------------|------------|
| 0 — Foundation | EventBus paths | Pitfall 8 (silent subscription failures) | Replace path strings with `preload()` constants first |
| 0 — Foundation | SoundManager cleanup | Pitfall 15 (double registration) | Remove `register_singleton()` call before using SoundManager |
| 0 — Foundation | UIManager integration | Pitfall 9 (dual visibility management) | Replace ALL `_show_only()` calls in one commit |
| 1 — Audio | SoundManager calls | Pitfall 1 (no bus architecture) | Create AudioBusLayout before first `play_ui_sound()` call |
| 1 — Audio | Sound/transition interaction | Pitfall 11 (sound cut off by scene change) | Route all game sounds through SoundManager autoload |
| 1 — Audio | Kenney sound import | Pitfall 19 (WAV loop mode) | Batch-set import: Loop Off, Max Rate 44100 |
| 2 — Gameplay Polish | Cell animations | Pitfall 2 (tween lifecycle) | Use `_kill_tween()` helper pattern for all tweens |
| 2 — Gameplay Polish | Mouse + keyboard input | Pitfall 13 (input divergence) | Route all input through one InputHandler abstraction |
| 3 — UI Polish | Container animation | Pitfall 3 (container fight) | Use wrapper Control nodes, not direct container children |
| 3 — UI Polish | Scene transition | Pitfall 4 (CanvasLayer fade) | Implement transition autoload BEFORE wiring buttons |
| 3 — UI Polish | AnimationPlayer RESET track | Pitfall 5 (size explosion) | Use Tween, not AnimationPlayer, for UI animations |
| 3 — UI Polish | AnimationPlayer signals | Pitfall 10 (signal not emitted) | Use Tween.finished or Call Method Track fallback |
| 3 — UI Polish | Viewport size assumptions | Pitfall 21 (hardcoded pixels) | Derive from `get_viewport_rect().size` |
| 3 — UI Polish | Node2D in Control tree | Pitfall 12 (layout mismatch) | Replace Sprite2D with TextureRect |
| 4 — AI Upgrade | Minimax synchronous | Pitfall 6 (main thread block) | Add timing guardrail, defensive board copy, do NOT multithread |
| 5 — Localization | CSV key encoding | Pitfall 7 (non-ASCII key failure on Android) | Use ASCII-only keys in CSV, full text audit |
| 5 — Localization | CSV reimport UID clash | Pitfall 14 (duplicate UIDs) | Gitignore `.translation` files |
| All phases | Error handling | Pitfall 18 (silent failures) | Enforce per-function error check in code review |

---

## Sources

- GitHub Issues: #90079 (AnimationPlayer RESET + container), #93904 (web audio finished signal), #107875/#106246 (non-ASCII translation keys on Android), #103118 (translation UID duplication), #57339 (freeze on tween target freed), #107688 (killed subtween breaks parent), #88775 (no audio device = no finished signal)
- Godot Forums: Tween lifecycle best practices, CanvasLayer fade transition technique, AudioStreamPlayer management patterns, Control node animation within containers
- LobeHub Godot Audio Systems guide (audio bus setup, decibel conversion, pooling patterns)
- Godot Docs: Autoloads vs internal nodes best practices, CanvasLayer layer ordering, AudioStreamPlayer class reference
- Project-specific CONCERNS.md: SoundManager dead autoload, EventBus hardcoded paths, zero error handling, UIManager bypass, AGENTS.md violations, no localization setup
