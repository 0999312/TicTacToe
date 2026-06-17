extends Node

# Sound cache: maps "tic_tac_toe:sounds/..." string keys to preloaded AudioStream
var _sound_cache: Dictionary = {}
var _current_music_key: String = ""


func _ready() -> void:
	_ensure_audio_buses()
	_setup_bus_routing()
	_cache_sounds()
	_subscribe_events()
	_apply_volumes()
	_start_menu_music()


# --- Audio Bus Management ---

func _ensure_audio_buses() -> void:
	var required_buses := ["SFX", "Music"]
	for bus_name in required_buses:
		if AudioServer.get_bus_index(bus_name) == -1:
			AudioServer.add_bus()
			var idx := AudioServer.bus_count - 1
			AudioServer.set_bus_name(idx, bus_name)
			AudioServer.set_bus_send(idx, "Master")
			push_warning("AudioController: created missing bus '%s' at runtime" % bus_name)
		else:
			print("AudioController: bus '%s' found" % bus_name)


func _setup_bus_routing() -> void:
	SoundManager.set_default_sound_bus("SFX")
	SoundManager.set_default_ui_sound_bus("SFX")
	SoundManager.set_default_music_bus("Music")


# --- Sound Registration and Caching ---

func _cache_sounds() -> void:
	var registry := SoundRegistry.new()
	RegistryManager.register_registry("sound", registry)

	# Register game sound effects
	registry.register(
		ResourceLocation.from_string("tic_tac_toe:sounds/game/place_mark"),
		load("res://addons/kenney_interface_sounds/drop_001.wav")
	)
	registry.register(
		ResourceLocation.from_string("tic_tac_toe:sounds/game/win"),
		load("res://addons/kenney_interface_sounds/confirmation_001.wav")
	)
	registry.register(
		ResourceLocation.from_string("tic_tac_toe:sounds/game/lose"),
		load("res://addons/kenney_interface_sounds/error_001.wav")
	)
	registry.register(
		ResourceLocation.from_string("tic_tac_toe:sounds/game/draw"),
		load("res://addons/kenney_interface_sounds/bong_001.wav")
	)
	registry.register(
		ResourceLocation.from_string("tic_tac_toe:sounds/ui/click"),
		load("res://addons/kenney_interface_sounds/click_001.wav")
	)
	registry.register(
		ResourceLocation.from_string("tic_tac_toe:sounds/ui/hover"),
		load("res://addons/kenney_interface_sounds/tick_001.wav")
	)
	registry.register(
		ResourceLocation.from_string("tic_tac_toe:music/background"),
		load("res://music/off_to_osaka.mp3")
	)
	registry.register(
		ResourceLocation.from_string("tic_tac_toe:music/breaktime"),
		load("res://music/breaktime.mp3")
	)

	# Preload all registered sounds into _sound_cache
	for key_str in registry.get_all_keys():
		var loc := ResourceLocation.from_string(key_str)
		var stream := registry.get_entry(loc) as AudioStream
		if stream:
			_sound_cache[key_str] = stream
		else:
			push_warning("AudioController: null sound for key: ", key_str)


# --- Event Subscriptions ---

func _subscribe_events() -> void:
	EventBus.subscribe(&"CellPlacedEvent", _on_cell_placed)
	EventBus.subscribe(&"GameWonEvent", _on_game_won)
	EventBus.subscribe(&"GameDrawEvent", _on_game_draw)
	EventBus.subscribe(&"GameStartedEvent", _on_game_started)
	EventBus.subscribe(&"SettingChangedEvent", _on_setting_changed)
	EventBus.subscribe(&"NavigateToMenuEvent", _on_navigate_to_menu)


func _exit_tree() -> void:
	EventBus.unsubscribe(&"CellPlacedEvent", _on_cell_placed)
	EventBus.unsubscribe(&"GameWonEvent", _on_game_won)
	EventBus.unsubscribe(&"GameDrawEvent", _on_game_draw)
	EventBus.unsubscribe(&"GameStartedEvent", _on_game_started)
	EventBus.unsubscribe(&"SettingChangedEvent", _on_setting_changed)
	EventBus.unsubscribe(&"NavigateToMenuEvent", _on_navigate_to_menu)


# --- Volume Initialization ---

func _apply_volumes() -> void:
	var sfx_vol := SettingsManager.get_value("audio/sfx_volume", 0.8) as float
	var music_vol := SettingsManager.get_value("audio/music_volume", 0.8) as float
	SoundManager.set_sound_volume(clampf(sfx_vol, 0.0, 1.0))
	SoundManager.set_music_volume(clampf(music_vol, 0.0, 1.0))


# --- Music ---

func _start_menu_music() -> void:
	var music_stream := _sound_cache.get("tic_tac_toe:music/background") as AudioStream
	if music_stream:
		SoundManager.play_music(music_stream, 0.5)
		_current_music_key = "tic_tac_toe:music/background"


# --- Event Handlers ---

func _on_cell_placed(_event: Event) -> void:
	var sound := _sound_cache.get("tic_tac_toe:sounds/game/place_mark") as AudioStream
	if sound:
		SoundManager.play_sound(sound)


func _on_game_won(event: Event) -> void:
	var winner: int = event.get("winner")
	var is_player_win := winner == GameManager.player_side
	var key := "tic_tac_toe:sounds/game/win" if is_player_win else "tic_tac_toe:sounds/game/lose"
	var sound := _sound_cache.get(key) as AudioStream
	if sound:
		SoundManager.play_sound(sound)


func _on_game_draw(_event: Event) -> void:
	var sound := _sound_cache.get("tic_tac_toe:sounds/game/draw") as AudioStream
	if sound:
		SoundManager.play_sound(sound)


func _on_game_started(_event: Event) -> void:
	if _current_music_key == "tic_tac_toe:music/breaktime":
		return  # Already playing gameplay music
	var music_stream := _sound_cache.get("tic_tac_toe:music/breaktime") as AudioStream
	if music_stream:
		SoundManager.play_music(music_stream, 1.0)
		_current_music_key = "tic_tac_toe:music/breaktime"


func _on_navigate_to_menu(_event: Event) -> void:
	if _current_music_key == "tic_tac_toe:music/background":
		return  # Already playing menu music
	var music_stream := _sound_cache.get("tic_tac_toe:music/background") as AudioStream
	if music_stream:
		SoundManager.play_music(music_stream, 1.0)
		_current_music_key = "tic_tac_toe:music/background"


func _on_setting_changed(event: Event) -> void:
	var key: String = event.get("key")
	var value = event.get("value")
	if key == "audio/sfx_volume":
		SoundManager.set_sound_volume(clampf(value as float, 0.0, 1.0))
	elif key == "audio/music_volume":
		SoundManager.set_music_volume(clampf(value as float, 0.0, 1.0))


# --- Public Helpers ---

func play_button_click() -> void:
	var sound := _sound_cache.get("tic_tac_toe:sounds/ui/click") as AudioStream
	if sound:
		SoundManager.play_ui_sound(sound)


func play_button_hover() -> void:
	var sound := _sound_cache.get("tic_tac_toe:sounds/ui/hover") as AudioStream
	if sound:
		SoundManager.play_ui_sound(sound)
