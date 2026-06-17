extends Event
class_name CellPlacedEvent

var cell_index: int
var player: int

func _init(p_cell_index: int, p_player: int) -> void:
	cell_index = p_cell_index
	player = p_player
