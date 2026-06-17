extends Node2D

@onready var main_menu: Control = $CanvasLayer/MainMenu
@onready var hud: Control = $CanvasLayer/HUD
@onready var game_over_panel: Control = $CanvasLayer/GameOverPanel
@onready var result_label: Label = $CanvasLayer/GameOverPanel/VBoxContainer/ResultLabel
@onready var turn_label: Label = $CanvasLayer/HUD/VBoxContainer/TurnLabel
@onready var mode_label: Label = $CanvasLayer/HUD/VBoxContainer/ModeLabel
@onready var score_label: Label = $CanvasLayer/MainMenu/VBoxContainer/ScoreLabel

var _gameplay_context: GUIDEMappingContext
var _place_mark_action: GUIDEAction
var _nav_up_action: GUIDEAction
var _nav_down_action: GUIDEAction
var _nav_left_action: GUIDEAction
var _nav_right_action: GUIDEAction
var _nav_stick_action: GUIDEAction
var _stick_accumulator: Vector2 = Vector2.ZERO
const STICK_THRESHOLD: float = 0.3


func _ready() -> void:
	_show_only(main_menu)
	EventBus.subscribe(&"GameStartedEvent", _on_game_started)
	EventBus.subscribe(&"TurnChangedEvent", _on_turn_changed)
	EventBus.subscribe(&"GameWonEvent", _on_game_won)
	EventBus.subscribe(&"GameDrawEvent", _on_game_draw)
	EventBus.subscribe(&"ScoreChangedEvent", _on_score_changed)
	EventBus.subscribe(&"LanguageChangedEvent", _on_language_changed)
	_setup_guide_input()
	I18NManager.load_translation("zh_CN", "res://translations/zh_CN.json")
	I18NManager.load_translation("en_US", "res://translations/en_US.json")
	var saved_locale := SettingsManager.get_value("language/locale", "zh_CN") as String
	I18NManager.set_language(saved_locale)


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

	# Connect signals
	_place_mark_action.just_triggered.connect(_on_place_mark)
	_nav_up_action.just_triggered.connect(func(): _on_nav_discrete(Vector2(0, -1)))
	_nav_down_action.just_triggered.connect(func(): _on_nav_discrete(Vector2(0, 1)))
	_nav_left_action.just_triggered.connect(func(): _on_nav_discrete(Vector2(-1, 0)))
	_nav_right_action.just_triggered.connect(func(): _on_nav_discrete(Vector2(1, 0)))
	_nav_stick_action.triggered.connect(_on_nav_stick)

	GUIDE.enable_mapping_context(_gameplay_context, false, 0)


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
	var board_node := $Board
	if _is_mouse_or_touch_active() and board_node:
		var mouse_global: Vector2 = board_node.get_global_mouse_position()
		var local_pos: Vector2 = board_node.to_local(mouse_global)
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


# --- button callbacks ---

func _on_pvp_pressed() -> void:
	_start_game(GameManager.GameMode.PVP, GameManager.Player.X)


func _on_pvai_x_pressed() -> void:
	_start_game(GameManager.GameMode.PVAI, GameManager.Player.X)


func _on_pvai_o_pressed() -> void:
	_start_game(GameManager.GameMode.PVAI, GameManager.Player.O)


func _on_rematch_pressed() -> void:
	GameManager.reset_board()
	_stick_accumulator = Vector2.ZERO


func _on_back_to_menu_pressed() -> void:
	GameManager.state = GameManager.GameState.IDLE
	_show_only(main_menu)


# --- EventBus handlers ---

func _on_game_started(event: Event) -> void:
	var mode_val: int = event.get("mode")
	_show_only(hud)
	var mode_text := tr("hud.mode_pvp") if mode_val == GameManager.GameMode.PVP else tr("hud.mode_pvai")
	mode_label.text = mode_text
	_stick_accumulator = Vector2.ZERO


func _on_turn_changed(event: Event) -> void:
	var player_val: int = event.get("player")
	var player_text := "X" if player_val == GameManager.Player.X else "O"
	turn_label.text = tr("hud.turn").format([player_text])


func _on_game_won(event: Event) -> void:
	var winner_val: int = event.get("winner")
	var winner_text := "X" if winner_val == GameManager.Player.X else "O"
	result_label.text = tr("game_over.win").format([winner_text])
	_show_only(game_over_panel)


func _on_game_draw(_event: Event) -> void:
	result_label.text = tr("game_over.draw")
	_show_only(game_over_panel)


func _on_score_changed(event: Event) -> void:
	var p1: int = event.get("p1_score")
	var p2: int = event.get("p2_score")
	var d: int = event.get("draw_score")
	score_label.text = tr("main_menu.score").format([p1, p2, d])


func _on_language_changed(_event: Event) -> void:
	_refresh_text()


func _refresh_text() -> void:
	# Update all dynamic text elements
	if GameManager.state == GameManager.GameState.PLAYING or GameManager.state == GameManager.GameState.OVER:
		var mode_key := "hud.mode_pvp" if GameManager.mode == GameManager.GameMode.PVP else "hud.mode_pvai"
		mode_label.text = tr(mode_key)
		turn_label.text = tr("hud.turn").format([GameManager.get_current_player_text()])
	score_label.text = tr("main_menu.score").format([GameManager.player1_score, GameManager.player2_score, GameManager.draw_score])


# --- helpers ---

func _start_game(p_mode: int, p_side: int) -> void:
	GameManager.start_game(p_mode, p_side)


func _show_only(panel: Control) -> void:
	main_menu.visible = (panel == main_menu)
	hud.visible = (panel == hud)
	game_over_panel.visible = (panel == game_over_panel)
