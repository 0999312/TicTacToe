extends Node2D


@onready var transition_overlay: ColorRect = $CanvasLayer/TransitionOverlay


func _ready() -> void:
	_setup_ui_registry()
	_subscribe_events()
	_setup_translations()
	# Open MainMenu on startup
	UIManager.open_panel(ResourceLocation.from_string("tic_tac_toe:main_menu"))


func _setup_ui_registry() -> void:
	var ui_reg := UIRegistry.new()
	RegistryManager.register_registry("ui", ui_reg)

	ui_reg.register_panel(
		ResourceLocation.from_string("tic_tac_toe:main_menu"),
		preload("res://scenes/panels/main_menu.tscn"),
		UILayer.NORMAL,
		UIPanel.CacheMode.CACHE
	)
	ui_reg.register_panel(
		ResourceLocation.from_string("tic_tac_toe:hud"),
		preload("res://scenes/panels/hud.tscn"),
		UILayer.NORMAL,
		UIPanel.CacheMode.CACHE
	)
	ui_reg.register_panel(
		ResourceLocation.from_string("tic_tac_toe:game_over"),
		preload("res://scenes/panels/game_over.tscn"),
		UILayer.POPUP,
		UIPanel.CacheMode.NONE
	)


func _subscribe_events() -> void:
	EventBus.subscribe(&"GameStartRequestEvent", _on_game_start_requested)
	EventBus.subscribe(&"GameStartedEvent", _on_game_started)
	EventBus.subscribe(&"GameWonEvent", _on_game_won)
	EventBus.subscribe(&"GameDrawEvent", _on_game_draw)
	EventBus.subscribe(&"LanguageChangedEvent", _on_language_changed)


func _setup_translations() -> void:
	I18NManager.load_translation("zh_CN", "res://translations/zh_CN.json")
	I18NManager.load_translation("en_US", "res://translations/en_US.json")
	I18NManager.load_translation("ja_JP", "res://translations/ja_JP.json")
	var saved_locale := SettingsManager.get_value("language/locale", "zh_CN") as String
	I18NManager.set_language(saved_locale)


func _on_game_start_requested(event: Event) -> void:
	var mode: int = event.get("mode")
	var side: int = event.get("player_side")

	# Close main menu, open HUD
	UIManager.close_all(UILayer.NORMAL)
	UIManager.open_panel(ResourceLocation.from_string("tic_tac_toe:hud"))

	# Remove previous Board instance if any
	var old_board := find_child("Board", true, false)
	if old_board:
		old_board.queue_free()

	# Instantiate Board scene
	var board_scene := preload("res://scenes/board.tscn")
	var board_instance := board_scene.instantiate()
	add_child(board_instance)

	# Start the game
	GameManager.start_game(mode, side)


func _on_game_started(_event: Event) -> void:
	# Board scene handles GUIDE context setup via its own EventBus subscription
	pass


func _on_game_won(event: Event) -> void:
	var winner_val: int = event.get("winner")
	UIManager.open_panel(
		ResourceLocation.from_string("tic_tac_toe:game_over"),
		{"winner": winner_val},
		UILayer.POPUP
	)


func _on_game_draw(_event: Event) -> void:
	UIManager.open_panel(
		ResourceLocation.from_string("tic_tac_toe:game_over"),
		{"draw": true},
		UILayer.POPUP
	)


func _on_language_changed(_event: Event) -> void:
	# UIPanels handle their own text refresh via event subscriptions / _on_resume
	pass


# Transition helpers (scaffolded for Plan 2 fade animation wiring)
func _fade_out(callback: Callable) -> void:
	transition_overlay.visible = true
	transition_overlay.modulate.a = 0.0
	var tween: Tween = create_tween()
	tween.tween_property(transition_overlay, "modulate:a", 1.0, 0.3)
	tween.tween_callback(callback)


func _fade_in() -> void:
	transition_overlay.modulate.a = 1.0
	transition_overlay.visible = true
	var tween: Tween = create_tween()
	tween.tween_property(transition_overlay, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func(): transition_overlay.visible = false)
