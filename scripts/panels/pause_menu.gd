extends UIPanel


@onready var resume_button: Button = $VBoxContainer/ResumeButton
@onready var settings_button: Button = $VBoxContainer/SettingsButton
@onready var menu_button: Button = $VBoxContainer/MenuButton

var _pause_context: GUIDEMappingContext
var _prev_music_volume: float = 0.0


var _initialized: bool = false


func _ready() -> void:
	if _initialized:
		return
	_initialized = true
	UIHelpers.setup_button_animation(resume_button)
	UIHelpers.setup_button_animation(settings_button)
	UIHelpers.setup_button_animation(menu_button)
	resume_button.pressed.connect(_on_resume_game)
	settings_button.pressed.connect(_on_open_settings)
	menu_button.pressed.connect(_on_back_to_menu)
	EventBus.subscribe(&"LanguageChangedEvent", _on_language_changed)


func _on_destroy() -> void:
	EventBus.unsubscribe(&"LanguageChangedEvent", _on_language_changed)


func _on_language_changed(_event: Event) -> void:
	_refresh_texts()


func _refresh_texts() -> void:
	resume_button.text = tr("pause.resume")
	settings_button.text = tr("pause.settings")
	menu_button.text = tr("pause.quit")


func _on_open(_data: Dictionary = {}) -> void:
	# Store and reduce music volume (D-23: 50% if above 0.1 threshold)
	_prev_music_volume = SoundManager.get_music_volume()
	if _prev_music_volume > 0.1:
		SoundManager.set_music_volume(_prev_music_volume * 0.5)

	# Create GUIDE context for Esc key to resume
	var resume_action: GUIDEAction = load("res://resources/actions/place_mark.tres")
	_pause_context = GUIDEMappingContext.new()
	_pause_context.display_name = "pause_menu"
	var mapping := GUIDEActionMapping.new()
	mapping.action = resume_action
	mapping.input_mappings.append(_make_esc_mapping())
	_pause_context.mappings.append(mapping)
	GUIDE.enable_mapping_context(_pause_context, false, 0)
	resume_action.just_triggered.connect(_on_esc_pressed, CONNECT_ONE_SHOT)

	# Notify board to disable gameplay input
	EventBus.publish(GamePausedEvent.new())


func _on_close() -> void:
	# Disable GUIDE context
	if _pause_context:
		GUIDE.disable_mapping_context(_pause_context)
		_pause_context = null

	# Restore music volume (D-23)
	if _prev_music_volume > 0.1:
		SoundManager.set_music_volume(_prev_music_volume)

	# Notify board to re-enable gameplay input
	EventBus.publish(GameResumedEvent.new())


func _on_resume_game() -> void:
	UIManager.back(UILayer.POPUP)


func _on_esc_pressed() -> void:
	UIManager.back(UILayer.POPUP)


func _on_open_settings() -> void:
	UIManager.open_panel(ResourceLocation.from_string("tic_tac_toe:settings"), {"return_layer": UILayer.POPUP}, UILayer.POPUP)


func _on_back_to_menu() -> void:
	UIManager.back(UILayer.POPUP)
	EventBus.publish(NavigateToMenuEvent.new())


func _make_esc_mapping() -> GUIDEInputMapping:
	var im := GUIDEInputMapping.new()
	var k := GUIDEInputKey.new()
	k.key = KEY_ESCAPE
	im.input = k
	im.triggers = [GUIDETriggerPressed.new()]
	return im
