extends Event
class_name GameWonEvent

var winner: int

func _init(p_winner: int) -> void:
	winner = p_winner
