extends RefCounted
class_name UIHelpers


static func setup_button_animation(button: Button) -> void:
	var hover_tween: Tween
	var exit_tween: Tween
	var press_tween: Tween
	var release_tween: Tween

	button.mouse_entered.connect(func():
		if hover_tween and hover_tween.is_valid():
			hover_tween.kill()
		hover_tween = button.create_tween().set_parallel(true)
		hover_tween.tween_property(button, "scale", Vector2(1.05, 1.05), 0.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		hover_tween.tween_property(button, "modulate", Color(1.15, 1.15, 1.15, 1.0), 0.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	)

	button.mouse_exited.connect(func():
		if exit_tween and exit_tween.is_valid():
			exit_tween.kill()
		exit_tween = button.create_tween().set_parallel(true)
		exit_tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		exit_tween.tween_property(button, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	)

	button.button_down.connect(func():
		if press_tween and press_tween.is_valid():
			press_tween.kill()
		press_tween = button.create_tween()
		press_tween.tween_property(button, "scale", Vector2(0.95, 0.95), 0.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	)

	button.button_up.connect(func():
		if release_tween and release_tween.is_valid():
			release_tween.kill()
		release_tween = button.create_tween()
		release_tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	)
