extends Event
class_name CursorMovedEvent

var cursor_index: int

func _init(p_cursor_index: int) -> void:
	cursor_index = p_cursor_index
