extends Event
class_name ScoreChangedEvent

var p1_score: int
var p2_score: int
var draw_score: int

func _init(p_p1: int, p_p2: int, p_draw: int) -> void:
	p1_score = p_p1
	p2_score = p_p2
	draw_score = p_draw
