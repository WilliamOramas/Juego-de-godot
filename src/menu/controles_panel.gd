extends Panel

func _ready() -> void:
	visible = false
	modulate.a = 0.0

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("Pause"):
		hide_panel()
		get_viewport().set_input_as_handled()

func show_panel() -> void:
	modulate.a = 0.0
	visible = true
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.15)

func hide_panel() -> void:
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.1)
	tween.tween_callback(func(): visible = false)

func _on_close_pressed() -> void:
	hide_panel()
