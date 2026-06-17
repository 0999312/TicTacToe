extends Node

@export var sfx_volume: float = 0.8
@export var music_volume: float = 0.8
@export var difficulty: int = 1
@export var locale: String = "zh_CN"

const SETTINGS_PATH := "user://settings.cfg"

var _config := ConfigFile.new()
var _cache: Dictionary = {}


func _ready() -> void:
	_load_config()


func get(key: String, default: Variant = null) -> Variant:
	return _cache.get(key, default)


func set(key: String, value: Variant) -> void:
	_cache[key] = value
	EventBus.publish(SettingChangedEvent.new(key, value))


func save() -> void:
	for key in _cache.keys():
		var parts := key.split("/")
		if parts.size() == 2:
			_config.set_value(parts[0], parts[1], _cache[key])
	var err := _config.save(SETTINGS_PATH)
	if err != OK:
		push_error("SettingsManager: failed to save settings: ", err)


func _load_config() -> void:
	var err := _config.load(SETTINGS_PATH)
	if err != OK:
		push_warning("SettingsManager: no settings file found (%d), using defaults" % err)
		_populate_cache_from_config()
		return
	_populate_cache_from_config()


func _populate_cache_from_config() -> void:
	if _config.has_section_key("audio", "sfx_volume"):
		_cache["audio/sfx_volume"] = _config.get_value("audio", "sfx_volume", sfx_volume)
	else:
		_cache["audio/sfx_volume"] = sfx_volume

	if _config.has_section_key("audio", "music_volume"):
		_cache["audio/music_volume"] = _config.get_value("audio", "music_volume", music_volume)
	else:
		_cache["audio/music_volume"] = music_volume

	if _config.has_section_key("gameplay", "difficulty"):
		_cache["gameplay/difficulty"] = _config.get_value("gameplay", "difficulty", difficulty)
	else:
		_cache["gameplay/difficulty"] = difficulty

	if _config.has_section_key("language", "locale"):
		_cache["language/locale"] = _config.get_value("language", "locale", locale)
	else:
		_cache["language/locale"] = locale


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save()
		get_tree().quit()
