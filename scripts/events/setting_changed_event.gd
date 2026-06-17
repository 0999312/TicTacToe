extends Event
class_name SettingChangedEvent

var key: String
var value: Variant

func _init(p_key: String, p_value: Variant) -> void:
	key = p_key
	value = p_value
