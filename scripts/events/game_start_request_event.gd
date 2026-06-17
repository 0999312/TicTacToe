extends Event
class_name GameStartRequestEvent

var mode: int
var player_side: int

func _init(p_mode: int, p_player_side: int) -> void:
	mode = p_mode
	player_side = p_player_side
