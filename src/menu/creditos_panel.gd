extends Panel

func _ready() -> void:
	visible = false
	modulate.a = 0.0
	set_process_input(false)

func show_panel() -> void:
	set_process_input(true)
	modulate.a = 0.0
	visible = true
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.15)

func hide_panel() -> void:
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.1)
	tween.tween_callback(func():
		visible = false
		set_process_input(false)
	)

func _on_close_pressed() -> void:
	hide_panel()
