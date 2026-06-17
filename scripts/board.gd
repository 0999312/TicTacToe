extends Node2D
class_name Board


var _gameplay_context: GUIDEMappingContext
var _place_mark_action: GUIDEAction
var _nav_up_action: GUIDEAction
var _nav_down_action: GUIDEAction
var _nav_left_action: GUIDEAction
var _nav_right_action: GUIDEAction
var _nav_stick_action: GUIDEAction
var _stick_accumulator: Vector2 = Vector2.ZERO
const STICK_THRESHOLD: float = 0.3

var _win_line_tween: Tween
var _pulse_tween: Tween
const WIN_LINE_COLOR: Color = Color(0.91, 0.72, 0.29, 1)


func _ready() -> void:
	EventBus.subscribe(&"GameStartedEvent", _on_game_started)
	EventBus.subscribe(&"GameWonEvent", _on_game_won)
	EventBus.subscribe(&"GameDrawEvent", _on_game_over)
	EventBus.subscribe(&"GamePausedEvent", _on_game_paused)
	EventBus.subscribe(&"GameResumedEvent", _on_game_resumed)


func _exit_tree() -> void:
	EventBus.unsubscribe(&"GameStartedEvent", _on_game_started)
	EventBus.unsubscribe(&"GameWonEvent", _on_game_won)
	EventBus.unsubscribe(&"GameDrawEvent", _on_game_over)
	EventBus.unsubscribe(&"GamePausedEvent", _on_game_paused)
	EventBus.unsubscribe(&"GameResumedEvent", _on_game_resumed)
	_disable_guide_context()


func _setup_guide_input() -> void:
	_place_mark_action = load("res://resources/actions/place_mark.tres")
	_nav_up_action = load("res://resources/actions/nav_up.tres")
	_nav_down_action = load("res://resources/actions/nav_down.tres")
	_nav_left_action = load("res://resources/actions/nav_left.tres")
	_nav_right_action = load("res://resources/actions/nav_right.tres")
	_nav_stick_action = load("res://resources/actions/grid_navigate.tres")

	_gameplay_context = GUIDEMappingContext.new()
	_gameplay_context.display_name = "gameplay"

	# --- place_mark ---
	var pm_mapping := GUIDEActionMapping.new()
	pm_mapping.action = _place_mark_action

	pm_mapping.input_mappings.append(_make_input_mapping(
		_make_mouse(MOUSE_BUTTON_LEFT), [], [GUIDETriggerPressed.new()]))
	pm_mapping.input_mappings.append(_make_input_mapping(
		_make_touch(), [], [GUIDETriggerDown.new()]))
	pm_mapping.input_mappings.append(_make_input_mapping(
		_make_key(KEY_ENTER), [], [GUIDETriggerPressed.new()]))
	pm_mapping.input_mappings.append(_make_input_mapping(
		_make_key(KEY_SPACE), [], [GUIDETriggerPressed.new()]))
	pm_mapping.input_mappings.append(_make_input_mapping(
		_make_joy_button(JOY_BUTTON_A), [], [GUIDETriggerPressed.new()]))

	_gameplay_context.mappings.append(pm_mapping)

	# --- 4 direction actions (BOOL, discrete: key + D-Pad, just_triggered) ---
	_setup_direction_action(
		_nav_up_action,
		KEY_W, KEY_UP,
		GUIDEInputJoyDirection.Direction.NEGATIVE, JOY_AXIS_LEFT_Y,
		Vector2(0, -1))

	_setup_direction_action(
		_nav_down_action,
		KEY_S, KEY_DOWN,
		GUIDEInputJoyDirection.Direction.POSITIVE, JOY_AXIS_LEFT_Y,
		Vector2(0, 1))

	_setup_direction_action(
		_nav_left_action,
		KEY_A, KEY_LEFT,
		GUIDEInputJoyDirection.Direction.NEGATIVE, JOY_AXIS_LEFT_X,
		Vector2(-1, 0))

	_setup_direction_action(
		_nav_right_action,
		KEY_D, KEY_RIGHT,
		GUIDEInputJoyDirection.Direction.POSITIVE, JOY_AXIS_LEFT_X,
		Vector2(1, 0))

	# --- analog stick (AXIS_2D, any device) ---
	var stick_mapping := GUIDEActionMapping.new()
	stick_mapping.action = _nav_stick_action
	var joy_axis := GUIDEInputJoyAxis2D.new()
	joy_axis.joy_index = -1
	stick_mapping.input_mappings.append(_make_input_mapping(
		joy_axis, [], [GUIDETriggerDown.new()]))
	_gameplay_context.mappings.append(stick_mapping)

	# Connect signals (with guard against duplicate connections on re-entry)
	if not _place_mark_action.just_triggered.is_connected(_on_place_mark):
		_place_mark_action.just_triggered.connect(_on_place_mark)
		_nav_up_action.just_triggered.connect(func(): _on_nav_discrete(Vector2(0, -1)))
		_nav_down_action.just_triggered.connect(func(): _on_nav_discrete(Vector2(0, 1)))
		_nav_left_action.just_triggered.connect(func(): _on_nav_discrete(Vector2(-1, 0)))
		_nav_right_action.just_triggered.connect(func(): _on_nav_discrete(Vector2(1, 0)))
		_nav_stick_action.triggered.connect(_on_nav_stick)

		# Esc -> open PauseMenu
		var esc_action := GUIDEAction.new()
		var esc_mapping := GUIDEActionMapping.new()
		esc_mapping.action = esc_action
		esc_mapping.input_mappings.append(_make_input_mapping(
			_make_key(KEY_ESCAPE), [], [GUIDETriggerPressed.new()]))
		_gameplay_context.mappings.append(esc_mapping)
		esc_action.just_triggered.connect(_on_esc_pressed)

	GUIDE.enable_mapping_context(_gameplay_context, false, 0)


func _disable_guide_context() -> void:
	if _gameplay_context:
		GUIDE.disable_mapping_context(_gameplay_context)
	_gameplay_context = null


func _setup_direction_action(action: GUIDEAction, key1: Key, key2: Key,
		joy_dir: GUIDEInputJoyDirection.Direction, joy_axis: JoyAxis, _move_vec: Vector2) -> void:
	var mapping := GUIDEActionMapping.new()
	mapping.action = action
	mapping.input_mappings.append(_make_input_mapping(
		_make_key(key1), [], [GUIDETriggerPressed.new()]))
	mapping.input_mappings.append(_make_input_mapping(
		_make_key(key2), [], [GUIDETriggerPressed.new()]))
	var jd := GUIDEInputJoyDirection.new()
	jd.joy_index = -1
	jd.direction = joy_dir
	jd.axis = joy_axis
	mapping.input_mappings.append(_make_input_mapping(
		jd, [], [GUIDETriggerPressed.new()]))
	_gameplay_context.mappings.append(mapping)


# --- factories ---

func _make_input_mapping(input: GUIDEInput, mods: Array[GUIDEModifier], trigs: Array[GUIDETrigger]) -> GUIDEInputMapping:
	var im := GUIDEInputMapping.new()
	im.input = input
	im.modifiers = mods
	im.triggers = trigs
	return im


func _make_mouse(btn: MouseButton) -> GUIDEInputMouseButton:
	var m := GUIDEInputMouseButton.new()
	m.button = btn
	return m


func _make_touch() -> GUIDEInputTouchBase:
	return GUIDEInputTouchBase.new()


func _make_key(kc: Key) -> GUIDEInputKey:
	var k := GUIDEInputKey.new()
	k.key = kc
	return k


func _make_joy_button(btn: JoyButton) -> GUIDEInputJoyButton:
	var j := GUIDEInputJoyButton.new()
	j.button = btn
	j.joy_index = -1
	return j


# --- place_mark handler ---

func _on_place_mark() -> void:
	if GameManager.state != GameManager.GameState.PLAYING:
		return
	var cell_idx := GameManager.cursor_index
	if _is_mouse_or_touch_active():
		var mouse_global: Vector2 = get_global_mouse_position()
		var local_pos: Vector2 = to_local(mouse_global)
		var cells := get_tree().get_nodes_in_group("cell")
		for c in cells:
			if c is Area2D and local_pos.distance_to(c.position) < 80.0:
				cell_idx = c.cell_index
				break
	GameManager.place_mark(cell_idx)


# --- direction handlers ---

func _on_nav_discrete(direction: Vector2) -> void:
	if GameManager.state != GameManager.GameState.PLAYING:
		return
	GameManager.move_cursor(direction)


func _on_nav_stick() -> void:
	if GameManager.state != GameManager.GameState.PLAYING:
		return
	var val := _nav_stick_action.value_axis_2d
	_stick_accumulator += val
	if abs(_stick_accumulator.x) >= STICK_THRESHOLD:
		var sign_x := 1 if _stick_accumulator.x > 0 else -1
		GameManager.move_cursor(Vector2(sign_x, 0))
		_stick_accumulator.x = 0.0
	if abs(_stick_accumulator.y) >= STICK_THRESHOLD:
		var sign_y := 1 if _stick_accumulator.y > 0 else -1
		GameManager.move_cursor(Vector2(0, sign_y))
		_stick_accumulator.y = 0.0


func _is_mouse_or_touch_active() -> bool:
	return Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)


# --- EventBus handlers ---

func _on_game_started(_event: Event) -> void:
	_stick_accumulator = Vector2.ZERO
	if _pulse_tween:
		_pulse_tween.kill()
		_pulse_tween = null
	# Remove any previous win line padding
	for child in get_children():
		if child is Line2D and child.name.begins_with("WinLine"):
			child.queue_free()
	if not _gameplay_context:
		_setup_guide_input()
	else:
		GUIDE.enable_mapping_context(_gameplay_context, false, 0)


func _on_game_won(event: Event) -> void:
	var winner: int = event.get("winner")
	var win_indices := _get_win_line_indices(winner)
	if win_indices.size() == 3:
		_animate_win_line(win_indices)
		_animate_winning_cells(win_indices)
	# Keep GUIDE context active so player can see the line, then dismiss on next game start


func _on_esc_pressed() -> void:
	if GameManager.state != GameManager.GameState.PLAYING:
		return
	UIManager.open_panel(ResourceLocation.from_string("tic_tac_toe:pause_menu"), {}, UILayer.POPUP)


func _on_game_over(_event: Event) -> void:
	_disable_guide_context()


func _on_game_paused(_event: Event) -> void:
	if _gameplay_context:
		GUIDE.disable_mapping_context(_gameplay_context)


func _on_game_resumed(_event: Event) -> void:
	if _gameplay_context:
		GUIDE.enable_mapping_context(_gameplay_context, false, 0)


func _get_win_line_indices(winner: int) -> Array:
	for line in GameManager.WIN_LINES:
		var a: int = GameManager.get_cell(line[0])
		var b: int = GameManager.get_cell(line[1])
		var c: int = GameManager.get_cell(line[2])
		if a == winner and b == winner and c == winner:
			return line
	return []


# --- Win line animation ---

func _animate_win_line(win_indices: Array) -> void:
	var cells := get_tree().get_nodes_in_group("cell")
	var positions: Array[Vector2] = []
	for idx in win_indices:
		for c in cells:
			if c is Cell and c.cell_index == idx:
				positions.append(c.position)
				break

	if positions.size() != 3:
		return

	# Calculate start and end points, extending by half cell size
	var start: Vector2 = positions[0]
	var end: Vector2 = positions[2]
	var dir: Vector2 = (end - start).normalized()
	var extend: float = 80.0  # half cell width/height
	start -= dir * extend
	end += dir * extend

	var win_line := Line2D.new()
	win_line.name = "WinLine"
	var start_color := WIN_LINE_COLOR
	start_color.a = 0.0
	win_line.default_color = start_color
	win_line.width = 0.0
	win_line.add_point(start)
	win_line.add_point(end)
	win_line.z_index = 10
	add_child(win_line)

	if _win_line_tween:
		_win_line_tween.kill()
	_win_line_tween = create_tween().set_parallel(true)
	_win_line_tween.tween_property(win_line, "width", 6.0, 0.3).set_trans(Tween.TRANS_SPRING).set_ease(Tween.EASE_OUT)
	_win_line_tween.tween_property(win_line, "default_color:a", 1.0, 0.3)


func _animate_winning_cells(win_indices: Array) -> void:
	if _pulse_tween:
		_pulse_tween.kill()
	_pulse_tween = create_tween().set_parallel(true).set_loops(2)
	var cells := get_tree().get_nodes_in_group("cell")
	for idx in win_indices:
		for c in cells:
			if c is Cell and c.cell_index == idx and c.highlight:
				_pulse_tween.tween_property(c.highlight, "modulate:a", 0.6, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
				_pulse_tween.tween_property(c.highlight, "modulate:a", 0.0, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
