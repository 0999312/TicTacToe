extends UIPanel


@onready var back_button: Button = $VBoxContainer/TopBar/BackButton
@onready var tab_container: TabContainer = $VBoxContainer/TabContainer
@onready var sfx_slider: HSlider = $VBoxContainer/TabContainer/AudioTab/AudioVBox/SFXRow/SFXSlider
@onready var music_slider: HSlider = $VBoxContainer/TabContainer/AudioTab/AudioVBox/MusicRow/MusicSlider
@onready var sfx_value_label: Label = $VBoxContainer/TabContainer/AudioTab/AudioVBox/SFXRow/SFXValueLabel
@onready var music_value_label: Label = $VBoxContainer/TabContainer/AudioTab/AudioVBox/MusicRow/MusicValueLabel
@onready var easy_button: Button = $VBoxContainer/TabContainer/GameTab/GameVBox/DifficultyRow/EasyButton
@onready var medium_button: Button = $VBoxContainer/TabContainer/GameTab/GameVBox/DifficultyRow/MediumButton
@onready var hard_button: Button = $VBoxContainer/TabContainer/GameTab/GameVBox/DifficultyRow/HardButton
@onready var language_option_button: OptionButton = $VBoxContainer/TabContainer/LanguageTab/LangVBox/LanguageOptionButton

const ACCENT_COLOR: Color = Color(0.91, 0.72, 0.29, 1)
const DIFFICULTY_BUTTONS: Array[String] = ["EasyButton", "MediumButton", "HardButton"]


var _initialized: bool = false
var _return_layer: int = UILayer.NORMAL


func _ready() -> void:
	if _initialized:
		return
	_initialized = true
	# Button animations
	UIHelpers.setup_button_animation(back_button)
	UIHelpers.setup_button_animation(easy_button)
	UIHelpers.setup_button_animation(medium_button)
	UIHelpers.setup_button_animation(hard_button)

	# Back button
	back_button.pressed.connect(_on_back_pressed)

	# Slider connections
	sfx_slider.value_changed.connect(_on_sfx_volume_changed)
	music_slider.value_changed.connect(_on_music_volume_changed)

	# Difficulty buttons
	easy_button.pressed.connect(func(): _on_difficulty_selected(0))
	medium_button.pressed.connect(func(): _on_difficulty_selected(1))
	hard_button.pressed.connect(func(): _on_difficulty_selected(2))

	# Language dropdown
	language_option_button.add_item("中文", 0)
	language_option_button.add_item("English", 1)
	language_option_button.add_item("日本語", 2)
	language_option_button.item_selected.connect(_on_language_selected)


func _on_open(_data: Dictionary = {}) -> void:
	# Read current values from SettingsManager
	var sfx_vol := SettingsManager.get_value("audio/sfx_volume", 0.8) as float
	var music_vol := SettingsManager.get_value("audio/music_volume", 0.8) as float
	var difficulty := SettingsManager.get_value("gameplay/difficulty", 1) as int
	var locale := SettingsManager.get_value("language/locale", "zh_CN") as String

	# Set sliders
	sfx_slider.value = sfx_vol * 100.0
	music_slider.value = music_vol * 100.0
	sfx_value_label.text = "%d%%" % (sfx_vol * 100)
	music_value_label.text = "%d%%" % (music_vol * 100)

	# Highlight selected difficulty
	_update_difficulty_highlight(difficulty)

	# Set language dropdown
	match locale:
		"en_US":
			language_option_button.select(1)
		"ja_JP":
			language_option_button.select(2)
		_:
			language_option_button.select(0)

	# Store return layer for back navigation
	_return_layer = _data.get("return_layer", UILayer.NORMAL)

	# Set tab titles from translations
	tab_container.set_tab_title(0, tr("settings.tab_audio"))
	tab_container.set_tab_title(1, tr("settings.tab_game"))
	tab_container.set_tab_title(2, tr("settings.tab_language"))


func _on_close() -> void:
	SettingsManager.save()


func _on_sfx_volume_changed(value: float) -> void:
	sfx_value_label.text = "%d%%" % value
	var vol := value / 100.0
	SettingsManager.set_value("audio/sfx_volume", vol)


func _on_music_volume_changed(value: float) -> void:
	music_value_label.text = "%d%%" % value
	var vol := value / 100.0
	SettingsManager.set_value("audio/music_volume", vol)


func _on_difficulty_selected(level: int) -> void:
	_update_difficulty_highlight(level)
	SettingsManager.set_value("gameplay/difficulty", level)


func _update_difficulty_highlight(selected: int) -> void:
	var buttons := [easy_button, medium_button, hard_button]
	for i in range(buttons.size()):
		if i == selected:
			buttons[i].modulate = ACCENT_COLOR
		else:
			buttons[i].modulate = Color.WHITE


func _on_language_selected(index: int) -> void:
	var locale: String
	match index:
		1:
			locale = "en_US"
		2:
			locale = "ja_JP"
		_:
			locale = "zh_CN"
	I18NManager.set_language(locale)
	SettingsManager.set_value("language/locale", locale)

	# Refresh tab titles after language change
	tab_container.set_tab_title(0, tr("settings.tab_audio"))
	tab_container.set_tab_title(1, tr("settings.tab_game"))
	tab_container.set_tab_title(2, tr("settings.tab_language"))


func _on_back_pressed() -> void:
	UIManager.back(_return_layer)
