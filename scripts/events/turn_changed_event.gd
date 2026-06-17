extends Event
class_name TurnChangedEvent

var player: int

func _init(p_player: int) -> void:
	player = p_player
