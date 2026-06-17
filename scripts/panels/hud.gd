extends UIPanel


@onready var mode_label: Label = $VBoxContainer/ModeLabel
@onready var turn_label: Label = $VBoxContainer/HBoxContainer/CenterVBox/TurnLabel
@onready var thinking_label: Label = $VBoxContainer/HBoxContainer/CenterVBox/ThinkingLabel
@onready var x_wins_label: Label = $VBoxContainer/HBoxContainer/LeftVBox/XWinsLabel
@onready var o_wins_label: Label = $VBoxContainer/HBoxContainer/RightVBox/OWinsLabel
@onready var draws_label: Label = $VBoxContainer/HBoxContainer/RightVBox/DrawsLabel


var _initialized: bool = false


func _ready() -> void:
	if _initialized:
		return
	_initialized = true
	EventBus.subscribe(&"TurnChangedEvent", _on_turn_changed)
	EventBus.subscribe(&"ScoreChangedEvent", _on_score_changed)
	EventBus.subscribe(&"GameStartedEvent", _on_game_started)
	EventBus.subscribe(&"LanguageChangedEvent", _on_language_changed)
	EventBus.subscribe(&"AiThinkingEvent", _on_ai_thinking)


func _on_destroy() -> void:
	super._on_destroy()
	EventBus.unsubscribe(&"TurnChangedEvent", _on_turn_changed)
	EventBus.unsubscribe(&"ScoreChangedEvent", _on_score_changed)
	EventBus.unsubscribe(&"GameStartedEvent", _on_game_started)
	EventBus.unsubscribe(&"LanguageChangedEvent", _on_language_changed)
	EventBus.unsubscribe(&"AiThinkingEvent", _on_ai_thinking)


func _on_language_changed(_event: Event) -> void:
	_refresh_all()


func _on_open(_data: Dictionary = {}) -> void:
	_refresh_all()


func _refresh_all() -> void:
	var mode_text := tr("hud.mode_pvp") if GameManager.mode == GameManager.GameMode.PVP else tr("hud.mode_pvai")
	mode_label.text = mode_text
	_turn_label_update()
	_score_label_update()


func _turn_label_update() -> void:
	var player_text := GameManager.get_current_player_text()
	turn_label.text = tr("hud.turn").format([player_text])


func _score_label_update() -> void:
	x_wins_label.text = tr("hud.x_wins").format([GameManager.player1_score])
	o_wins_label.text = tr("hud.o_wins").format([GameManager.player2_score])
	draws_label.text = tr("hud.draws").format([GameManager.draw_score])


func _on_turn_changed(event: Event) -> void:
	var player_val: int = event.player
	var player_text := "X" if player_val == GameManager.Player.X else "O"
	turn_label.text = tr("hud.turn").format([player_text])


func _on_score_changed(event: Event) -> void:
	var p1: int = event.p1_score
	var p2: int = event.p2_score
	var d: int = event.draw_score
	x_wins_label.text = tr("hud.x_wins").format([p1])
	o_wins_label.text = tr("hud.o_wins").format([p2])
	draws_label.text = tr("hud.draws").format([d])


func _on_game_started(event: Event) -> void:
	var mode_val: int = event.mode
	var mode_text := tr("hud.mode_pvp") if mode_val == GameManager.GameMode.PVP else tr("hud.mode_pvai")
	mode_label.text = mode_text


func _on_ai_thinking(event: Event) -> void:
	var is_thinking: bool = event.thinking
	thinking_label.visible = is_thinking
