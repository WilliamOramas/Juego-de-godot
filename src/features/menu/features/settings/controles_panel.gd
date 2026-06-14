extends Panel

signal panel_closed

func _ready() -> void:
	visible = false
	modulate.a = 0.0
	set_process_input(false)

func show_panel() -> void:
	set_process_input(true)
	modulate.a = 0.0
	AnimHelper.fade_in(self)

func hide_panel() -> void:
	AnimHelper.fade_out(self, AnimHelper.FADE_OUT_DURATION, func():
		visible = false
		set_process_input(false)
	)

func _on_close_pressed() -> void:
	hide_panel()
	panel_closed.emit()
