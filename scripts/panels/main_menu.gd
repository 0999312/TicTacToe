extends UIPanel


@onready var title_label: Label = %TitleLabel
@onready var subtitle_label: Label = %SubtitleLabel
@onready var pvp_button: Button = %PvPButton
@onready var pvai_button: Button = %PvAIButton
@onready var settings_button: Button = %SettingsButton
@onready var quit_button: Button = %QuitButton
@onready var version_label: Label = %VersionLabel


func _on_init() -> void:
	UIHelpers.setup_button_animation(pvp_button)
	UIHelpers.setup_button_animation(pvai_button)
	UIHelpers.setup_button_animation(settings_button)
	UIHelpers.setup_button_animation(quit_button)
	pvp_button.pressed.connect(_on_pvp_pressed)
	pvai_button.pressed.connect(_on_pvai_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	_refresh_texts()


func _on_open(_data: Dictionary = {}) -> void:
	_refresh_texts()


func _refresh_texts() -> void:
	title_label.text = tr("main_menu.title")
	subtitle_label.text = tr("main_menu.subtitle")
	pvp_button.text = tr("main_menu.pvp")
	pvai_button.text = tr("main_menu.pvai_x")
	settings_button.text = tr("main_menu.settings")
	quit_button.text = tr("main_menu.quit")
	version_label.text = tr("main_menu.version")


func _on_pvp_pressed() -> void:
	EventBus.publish(GameStartRequestEvent.new(GameManager.GameMode.PVP, GameManager.Player.X))


func _on_pvai_pressed() -> void:
	EventBus.publish(GameStartRequestEvent.new(GameManager.GameMode.PVAI, GameManager.Player.X))


func _on_settings_pressed() -> void:
	UIManager.open_panel(ResourceLocation.from_string("tic_tac_toe:settings"))


func _on_quit_pressed() -> void:
	get_tree().quit()
