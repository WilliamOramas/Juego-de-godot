class_name FaintingUIController
extends Node

var root: MiniFaintingFirstAid
var anim: FaintingAnimationController

var instruction_label: Label
var help_label: Label
var timer_label: Label
var feedback_label: Label
var step_label: Label
var progress_bar: ProgressBar
var dial_label: Label
var hearts_box: HBoxContainer
var keycap_rect: TextureRect

var checkmark_label: Label
var x_label: Label

var touch_button: Button
var touch_dial_container: HBoxContainer
var _is_touch_pressed: bool = false

signal touch_pressed
signal touch_released
signal touch_dial_pressed(key: int)

const KEYCAP_NORMAL = preload("res://src/assets/sprites/keycap_q.svg")
const KEYCAP_PRESSED = preload("res://src/assets/sprites/keycap_q_pressed.svg")

func setup(minigame: MiniFaintingFirstAid, animation_controller: FaintingAnimationController) -> void:
	root = minigame
	anim = animation_controller

	instruction_label = root.game_container.get_node("InstructionLabel")
	help_label = root.game_container.get_node("HelpLabel")
	timer_label = root.game_container.get_node("TimerLabel")
	feedback_label = root.game_container.get_node("FeedbackLabel")
	step_label = root.game_container.get_node("StepLabel")
	progress_bar = root.game_container.get_node("ProgressBar")
	dial_label = root.game_container.get_node("DialLabel")
	var hearts_label = root.game_container.get_node("HeartsLabel")

	# Restyle texts to diegetic positions (anchored top-left for expand-safe layout)
	instruction_label.anchor_left = 0.0
	instruction_label.anchor_top = 0.0
	instruction_label.anchor_right = 0.0
	instruction_label.anchor_bottom = 0.0
	instruction_label.offset_left = 48
	instruction_label.offset_top = 85
	instruction_label.offset_right = 976
	instruction_label.offset_bottom = 145
	instruction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT

	help_label.anchor_left = 0.0
	help_label.anchor_top = 0.0
	help_label.anchor_right = 0.0
	help_label.anchor_bottom = 0.0
	help_label.offset_left = 56
	help_label.offset_top = 152
	help_label.offset_right = 968
	help_label.offset_bottom = 220
	help_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT

	step_label.set_anchors_preset(Control.PRESET_TOP_LEFT)
	step_label.offset_left = 16
	step_label.offset_top = 16

	timer_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	timer_label.offset_left = -55
	timer_label.offset_top = 10
	timer_label.offset_right = 55

	# Keycap
	keycap_rect = TextureRect.new()
	keycap_rect.texture = KEYCAP_NORMAL
	keycap_rect.anchor_left = 0.0
	keycap_rect.anchor_top = 0.0
	keycap_rect.anchor_right = 0.0
	keycap_rect.anchor_bottom = 0.0
	keycap_rect.offset_left = 64
	keycap_rect.offset_top = 264
	keycap_rect.offset_right = 115
	keycap_rect.offset_bottom = 302
	keycap_rect.visible = false
	root.game_container.add_child(keycap_rect)

	MiniGameTheme.apply_primary(instruction_label, 22)
	MiniGameTheme.apply_muted(help_label, 14)
	MiniGameTheme.style_neon_panel(instruction_label, MiniGameTheme.NEON_CYAN)
	MiniGameTheme.style_neon_panel(help_label, MiniGameTheme.NEON_CYAN * Color(0.7, 0.7, 0.7, 1.0))
	MiniGameTheme.apply_primary(timer_label, 22)
	MiniGameTheme.style_neon_panel(timer_label, MiniGameTheme.NEON_CYAN)
	MiniGameTheme.apply_primary(feedback_label, 24)
	MiniGameTheme.style_neon_panel(feedback_label, MiniGameTheme.NEON_GREEN)
	MiniGameTheme.apply_muted(step_label, 12)
	step_label.add_theme_color_override("font_color", MiniGameTheme.TEXT_MUTED)
	MiniGameTheme.apply_primary(dial_label, 30)
	dial_label.add_theme_color_override("font_color", MiniGameTheme.NEON_CYAN)

	MiniGameTheme.style_progress_bar_neon(progress_bar, MiniGameTheme.NEON_GREEN)

	# Progress bar reposition
	progress_bar.anchor_left = 0.0
	progress_bar.anchor_top = 0.0
	progress_bar.anchor_right = 0.0
	progress_bar.anchor_bottom = 0.0
	progress_bar.offset_left = 240
	progress_bar.offset_top = 258
	progress_bar.offset_right = 784
	progress_bar.offset_bottom = 298

	# Hearts Box
	if hearts_label: hearts_label.visible = false
	hearts_box = HBoxContainer.new()
	hearts_box.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	hearts_box.offset_left = -230
	hearts_box.offset_top = 10
	hearts_box.offset_right = -24
	hearts_box.offset_bottom = 52
	hearts_box.alignment = BoxContainer.ALIGNMENT_END
	hearts_box.add_theme_constant_override("separation", 10)
	root.game_container.add_child(hearts_box)
	for i in range(3):
		var heart_rect = TextureRect.new()
		heart_rect.texture = load("res://src/assets/sprites/heart_pixel.svg")
		heart_rect.custom_minimum_size = Vector2(36, 36)
		heart_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		heart_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		hearts_box.add_child(heart_rect)

	# Checkmark and X labels for feedback
	checkmark_label = Label.new()
	checkmark_label.text = "✓"
	checkmark_label.add_theme_color_override("font_color", MiniGameTheme.FEEDBACK_GOOD)
	checkmark_label.add_theme_font_size_override("font_size", 48)
	checkmark_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	checkmark_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	checkmark_label.anchor_left = 0.5
	checkmark_label.anchor_top = 0.5
	checkmark_label.anchor_right = 0.5
	checkmark_label.anchor_bottom = 0.5
	checkmark_label.offset_left = -30
	checkmark_label.offset_top = -100
	checkmark_label.offset_right = 30
	checkmark_label.offset_bottom = -40
	checkmark_label.visible = false
	root.game_container.add_child(checkmark_label)

	x_label = Label.new()
	x_label.text = "✗"
	x_label.add_theme_color_override("font_color", MiniGameTheme.FEEDBACK_BAD)
	x_label.add_theme_font_size_override("font_size", 48)
	x_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	x_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	x_label.anchor_left = 0.5
	x_label.anchor_top = 0.5
	x_label.anchor_right = 0.5
	x_label.anchor_bottom = 0.5
	x_label.offset_left = -30
	x_label.offset_top = -100
	x_label.offset_right = 30
	x_label.offset_bottom = -40
	x_label.visible = false
	root.game_container.add_child(x_label)

	# Touch button (for hold/tap/timed_press/ecg)
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

func _process(_delta: float) -> void:
	if not root._is_running:
		return
	var is_pressed = Input.is_action_pressed("Phone") or _is_touch_pressed
	if is_pressed:
		if keycap_rect and keycap_rect.texture != KEYCAP_PRESSED:
			keycap_rect.texture = KEYCAP_PRESSED
	else:
		if keycap_rect and keycap_rect.texture != KEYCAP_NORMAL:
			keycap_rect.texture = KEYCAP_NORMAL

func update_ui(step_data: Dictionary, step_index: int, total_steps: int, lives: int) -> void:
	instruction_label.text = step_data.instruction
	help_label.text = step_data.help.replace("[Q] ", "").replace("[Q]", "")
	step_label.text = "Paso %d/%d" % [step_index + 1, total_steps]

	if hearts_box:
		for i in range(hearts_box.get_child_count()):
			var child = hearts_box.get_child(i)
			if i < lives:
				child.modulate.a = 1.0
			else:
				child.modulate.a = 0.2

	var is_hold = (step_data.type == MiniFaintingFirstAid.StepType.HOLD_CHECK_RESPONSE or step_data.type == MiniFaintingFirstAid.StepType.HOLD_CHECK_BREATHING or step_data.type == MiniFaintingFirstAid.StepType.HOLD_ELEVATE)
	progress_bar.visible = is_hold

	if keycap_rect:
		var needs_keycap = (step_data.type == MiniFaintingFirstAid.StepType.HOLD_CHECK_RESPONSE or step_data.type == MiniFaintingFirstAid.StepType.HOLD_CHECK_BREATHING or step_data.type == MiniFaintingFirstAid.StepType.HOLD_ELEVATE or step_data.type == MiniFaintingFirstAid.StepType.TAP or step_data.type == MiniFaintingFirstAid.StepType.TIMED_PRESS or step_data.type == MiniFaintingFirstAid.StepType.ECG)
		if needs_keycap and not keycap_rect.visible:
			_animate_keycap_appear()
		keycap_rect.visible = needs_keycap

	# Touch button visibility
	var needs_touch_button = (step_data.type == MiniFaintingFirstAid.StepType.HOLD_CHECK_RESPONSE or step_data.type == MiniFaintingFirstAid.StepType.HOLD_CHECK_BREATHING or step_data.type == MiniFaintingFirstAid.StepType.HOLD_ELEVATE or step_data.type == MiniFaintingFirstAid.StepType.TAP or step_data.type == MiniFaintingFirstAid.StepType.TIMED_PRESS or step_data.type == MiniFaintingFirstAid.StepType.ECG)
	touch_button.visible = needs_touch_button
	if needs_touch_button:
		match step_data.type:
			MiniFaintingFirstAid.StepType.HOLD_CHECK_RESPONSE, MiniFaintingFirstAid.StepType.HOLD_CHECK_BREATHING, MiniFaintingFirstAid.StepType.HOLD_ELEVATE:
				touch_button.text = "MANTENER"
			MiniFaintingFirstAid.StepType.TAP:
				touch_button.text = "PRESIONAR"
			MiniFaintingFirstAid.StepType.TIMED_PRESS:
				touch_button.text = "PULSO"
			MiniFaintingFirstAid.StepType.ECG:
				touch_button.text = "CORAZÓN"

	# Touch dial visibility
	var needs_touch_dial = (step_data.type == MiniFaintingFirstAid.StepType.DIAL_112)
	touch_dial_container.visible = needs_touch_dial

	# Update dial label visibility
	if step_data.type != MiniFaintingFirstAid.StepType.DIAL_112:
		dial_label.visible = false
	else:
		dial_label.visible = true

func update_timer(time_remaining: float) -> void:
	var secs: int = clampi(int(ceil(time_remaining)), 0, 999)
	var mins: int = int(secs / 60.0)
	var secs_remain: int = secs % 60
	timer_label.text = "%02d:%02d" % [mins, secs_remain]
	if time_remaining <= 10.0:
		timer_label.modulate = MiniGameTheme.FEEDBACK_BAD
	elif time_remaining <= 30.0:
		timer_label.modulate = MiniGameTheme.FEEDBACK_WARN
	else:
		timer_label.modulate = MiniGameTheme.TEXT_PRIMARY

func update_dial(target_keys: Array, current_index: int) -> void:
	var display := ""
	for i in target_keys.size():
		if i < current_index:
			display += "[%d] " % target_keys[i]
		else:
			display += "[_] "
	dial_label.text = display.strip_edges()

func update_progress(value: float) -> void:
	progress_bar.value = value

func show_feedback(text: String, color: Color) -> void:
	feedback_label.modulate = color
	feedback_label.text = text

func clear_feedback() -> void:
	feedback_label.text = ""
	feedback_label.modulate = MiniGameTheme.TEXT_PRIMARY

func _animate_keycap_appear() -> void:
	anim.play_pop(keycap_rect)

func show_checkmark() -> void:
	checkmark_label.visible = true
	anim.play_pop(checkmark_label)
	var tw := create_tween()
	tw.tween_interval(0.8)
	tw.tween_callback(func(): checkmark_label.visible = false)

func show_x() -> void:
	x_label.visible = true
	anim.play_pop(x_label)
	var tw := create_tween()
	tw.tween_interval(0.8)
	tw.tween_callback(func(): x_label.visible = false)
