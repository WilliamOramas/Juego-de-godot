class_name CPRTouchController
extends Node

var root: MiniCPR

var touch_button: Button
var touch_dial_container: HBoxContainer
var _is_touch_pressed: bool = false

signal touch_pressed
signal touch_released
signal touch_dial_pressed(key: int)

func setup(minigame: MiniCPR) -> void:
	root = minigame
	_create_touch_ui()

func _create_touch_ui() -> void:
	# Main touch button (for hold/tap/compress)
	touch_button = Button.new()
	touch_button.text = "PRESIONAR"
	touch_button.anchor_left = 0.0
	touch_button.anchor_top = 0.0
	touch_button.anchor_right = 0.0
	touch_button.anchor_bottom = 0.0
	touch_button.offset_left = 320
	touch_button.offset_top = 330
	touch_button.offset_right = 704
	touch_button.offset_bottom = 400
	touch_button.visible = false
	touch_button.mouse_filter = Control.MOUSE_FILTER_STOP

	MiniGameTheme.style_neon_button(touch_button, MiniGameTheme.NEON_CYAN)
	touch_button.add_theme_font_size_override("font_size", 22)

	touch_button.button_down.connect(func():
		_is_touch_pressed = true
		touch_pressed.emit()
	)
	touch_button.button_up.connect(func():
		_is_touch_pressed = false
		touch_released.emit()
	)
	root.game_container.add_child(touch_button)

	# Touch dial buttons (for DIAL_112)
	touch_dial_container = HBoxContainer.new()
	touch_dial_container.anchor_left = 0.0
	touch_dial_container.anchor_top = 0.0
	touch_dial_container.anchor_right = 0.0
	touch_dial_container.anchor_bottom = 0.0
	touch_dial_container.offset_left = 240
	touch_dial_container.offset_top = 310
	touch_dial_container.offset_right = 784
	touch_dial_container.offset_bottom = 390
	touch_dial_container.alignment = BoxContainer.ALIGNMENT_CENTER
	touch_dial_container.visible = false
	touch_dial_container.add_theme_constant_override("separation", 24)
	touch_dial_container.mouse_filter = Control.MOUSE_FILTER_STOP

	for i in range(3):
		var dial_btn = Button.new()
		dial_btn.text = str(i + 1)
		dial_btn.custom_minimum_size = Vector2(64, 64)

		MiniGameTheme.style_neon_button(dial_btn, MiniGameTheme.NEON_CYAN)
		dial_btn.add_theme_font_size_override("font_size", 26)

		var keycode = KEY_1 if i == 0 else KEY_2 if i == 1 else KEY_3
		dial_btn.pressed.connect(func(): touch_dial_pressed.emit(keycode))

		touch_dial_container.add_child(dial_btn)

	root.game_container.add_child(touch_dial_container)

func update_touch_visibility(step_type: int) -> void:
	var needs_touch_button = (step_type != MiniCPR.StepType.DIAL_112)
	touch_button.visible = needs_touch_button

	if needs_touch_button:
		match step_type:
			MiniCPR.StepType.SAFETY:
				touch_button.text = "CONFIRMAR"
			MiniCPR.StepType.COMPRESS, MiniCPR.StepType.CYCLE:
				touch_button.text = "COMPRIMIR"
			MiniCPR.StepType.BREATH:
				touch_button.text = "RESPIRAR"

	var needs_touch_dial = (step_type == MiniCPR.StepType.DIAL_112)
	touch_dial_container.visible = needs_touch_dial

func is_touch_pressed() -> bool:
	return _is_touch_pressed
