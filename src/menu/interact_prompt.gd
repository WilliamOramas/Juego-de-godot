class_name InteractPrompt
extends PanelContainer

var _on_interact_callback: Callable

func setup(on_interact: Callable) -> void:
	_on_interact_callback = on_interact
	
	pivot_offset = size / 2.0
	scale = Vector2.ZERO
	var tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2.ONE, 0.25)

func _on_interact_pressed() -> void:
	if _on_interact_callback.is_valid():
		_on_interact_callback.call()

func set_button_visible(is_visible: bool) -> void:
	%InteractButton.visible = is_visible

func _unhandled_input(event: InputEvent) -> void:
	# If the button is hidden, its shortcut might not fire natively.
	# We catch the E key here just in case, to allow closing the dialog.
	if not %InteractButton.visible and event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_E:
			_on_interact_pressed()
			get_viewport().set_input_as_handled()
