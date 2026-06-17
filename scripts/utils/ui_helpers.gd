extends RefCounted
class_name UIHelpers


static func setup_button_animation(button: Button) -> void:
	button.mouse_entered.connect(func():
		if button.has_meta(&"hover_tween"):
			var prev: Tween = button.get_meta(&"hover_tween") as Tween
			if prev and prev.is_valid():
				prev.kill()
		var t := button.create_tween().set_parallel(true)
		t.tween_property(button, "scale", Vector2(1.05, 1.05), 0.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		t.tween_property(button, "modulate", Color(1.15, 1.15, 1.15, 1.0), 0.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		button.set_meta(&"hover_tween", t)
	)

	button.mouse_exited.connect(func():
		if button.has_meta(&"exit_tween"):
			var prev: Tween = button.get_meta(&"exit_tween") as Tween
			if prev and prev.is_valid():
				prev.kill()
		var t := button.create_tween().set_parallel(true)
		t.tween_property(button, "scale", Vector2(1.0, 1.0), 0.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		t.tween_property(button, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		button.set_meta(&"exit_tween", t)
	)

	button.button_down.connect(func():
		if button.has_meta(&"press_tween"):
			var prev: Tween = button.get_meta(&"press_tween") as Tween
			if prev and prev.is_valid():
				prev.kill()
		var t := button.create_tween()
		t.tween_property(button, "scale", Vector2(0.95, 0.95), 0.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		button.set_meta(&"press_tween", t)
	)

	button.button_up.connect(func():
		if button.has_meta(&"release_tween"):
			var prev: Tween = button.get_meta(&"release_tween") as Tween
			if prev and prev.is_valid():
				prev.kill()
		var t := button.create_tween()
		t.tween_property(button, "scale", Vector2(1.0, 1.0), 0.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		button.set_meta(&"release_tween", t)
	)
