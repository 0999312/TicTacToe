extends Area2D
class_name Cell

@export var cell_index: int = 0
@onready var sprite: Sprite2D = $Sprite2D
@onready var highlight: Sprite2D = $Highlight

var _x_texture: Texture2D = preload("res://assets/sprites/x_mark.svg")
var _o_texture: Texture2D = preload("res://assets/sprites/o_mark.svg")
var _empty_texture: Texture2D


func _ready() -> void:
	add_to_group("cell")
	_empty_texture = sprite.texture
	EventBus.subscribe(&"CellPlacedEvent", _on_cell_placed)
	EventBus.subscribe(&"GameStartedEvent", _on_game_started)
	EventBus.subscribe(&"GameWonEvent", _on_game_over)
	EventBus.subscribe(&"GameDrawEvent", _on_game_over)
	EventBus.subscribe(&"CursorMovedEvent", _on_cursor_moved)
	if highlight:
		highlight.visible = false


func refresh() -> void:
	var val := GameManager.get_cell(cell_index)
	match val:
		GameManager.Player.X:
			sprite.texture = _x_texture
		GameManager.Player.O:
			sprite.texture = _o_texture
		_:
			sprite.texture = _empty_texture


func set_highlight(active: bool) -> void:
	if highlight:
		highlight.visible = active


func disable() -> void:
	input_pickable = false


func enable() -> void:
	input_pickable = true


func _on_cell_placed(event: Event) -> void:
	if "cell_index" in event:
		var cell_idx: int = event.get("cell_index")
		if cell_idx == cell_index:
			refresh()


func _on_game_started(_event: Event) -> void:
	refresh()
	enable()


func _on_game_over(_event: Event) -> void:
	disable()


func _on_cursor_moved(event: Event) -> void:
	if "cursor_index" in event:
		var idx: int = event.get("cursor_index")
		set_highlight(idx == cell_index)
