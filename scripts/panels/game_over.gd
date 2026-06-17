extends UIPanel


@onready var result_label: Label = %ResultLabel
@onready var score_label: Label = %ScoreLabel
@onready var play_again_button: Button = %PlayAgainButton
@onready var menu_button: Button = %MenuButton


func _on_init() -> void:
	UIHelpers.setup_button_animation(play_again_button)
	UIHelpers.setup_button_animation(menu_button)
	play_again_button.pressed.connect(_on_play_again)
	menu_button.pressed.connect(_on_back_to_menu)
	EventBus.subscribe(&"LanguageChangedEvent", _on_language_changed)


func _on_destroy() -> void:
	EventBus.unsubscribe(&"LanguageChangedEvent", _on_language_changed)


func _on_language_changed(_event: Event) -> void:
	_refresh_texts()


func _on_open(_data: Dictionary = {}) -> void:
	_update_result(_data)
	score_label.text = tr("game_over.score_recap").format([
		GameManager.player1_score,
		GameManager.player2_score,
		GameManager.draw_score
	])


func _update_result(data: Dictionary) -> void:
	if data.has("winner"):
		var winner_text := "X" if data["winner"] == GameManager.Player.X else "O"
		result_label.text = tr("game_over.win").format([winner_text])
	elif data.has("draw") and data["draw"]:
		result_label.text = tr("game_over.draw")


func _refresh_texts() -> void:
	score_label.text = tr("game_over.score_recap").format([
		GameManager.player1_score,
		GameManager.player2_score,
		GameManager.draw_score
	])
	play_again_button.text = tr("game_over.play_again")
	menu_button.text = tr("game_over.back")


func _on_play_again() -> void:
	EventBus.publish(RematchEvent.new())
	UIManager.back(UILayer.POPUP)


func _on_back_to_menu() -> void:
	EventBus.publish(NavigateToMenuEvent.new())
	UIManager.back(UILayer.POPUP)
