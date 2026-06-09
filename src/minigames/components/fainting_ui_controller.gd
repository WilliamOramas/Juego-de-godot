class_name FaintingUIController
extends Node

var root: MiniFaintingFirstAid

var instruction_label: Label
var help_label: Label
var timer_label: Label
var feedback_label: Label
var step_label: Label
var progress_bar: TextureProgressBar
var dial_label: Label
var hearts_box: HBoxContainer
var keycap_rect: TextureRect

const KEYCAP_NORMAL = preload("res://src/assets/sprites/keycap_q.svg")
const KEYCAP_PRESSED = preload("res://src/assets/sprites/keycap_q_pressed.svg")

func setup(minigame: MiniFaintingFirstAid) -> void:
	root = minigame
	
	instruction_label = root.get_node("GameContainer/InstructionLabel")
	help_label = root.get_node("GameContainer/HelpLabel")
	timer_label = root.get_node("GameContainer/TimerLabel")
	feedback_label = root.get_node("GameContainer/FeedbackLabel")
	step_label = root.get_node("GameContainer/StepLabel")
	progress_bar = root.get_node("GameContainer/ProgressBar")
	dial_label = root.get_node("GameContainer/DialLabel")
	var hearts_label = root.get_node("GameContainer/HeartsLabel")
	
	# Restyle texts to diegetic positions
	instruction_label.set_anchors_preset(Control.PRESET_CENTER)
	instruction_label.offset_left = -320
	instruction_label.offset_top = -120
	instruction_label.offset_right = 180
	instruction_label.offset_bottom = -60
	instruction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	
	help_label.set_anchors_preset(Control.PRESET_CENTER)
	help_label.offset_left = -320
	help_label.offset_top = -50
	help_label.offset_right = 180
	help_label.offset_bottom = 30
	help_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	
	step_label.set_anchors_preset(Control.PRESET_TOP_LEFT)
	step_label.offset_left = 20
	step_label.offset_top = 20
	
	timer_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	timer_label.offset_left = -50
	timer_label.offset_top = 15
	timer_label.offset_right = 50
	
	# Keycap
	keycap_rect = TextureRect.new()
	keycap_rect.texture = KEYCAP_NORMAL
	keycap_rect.set_anchors_preset(Control.PRESET_CENTER)
	keycap_rect.offset_left = -320
	keycap_rect.offset_top = 50
	keycap_rect.offset_right = -288
	keycap_rect.offset_bottom = 82
	keycap_rect.visible = false
	root.get_node("GameContainer").add_child(keycap_rect)
	
	MiniGameTheme.apply_body(instruction_label, 18)
	MiniGameTheme.apply_muted(help_label, 14)
	MiniGameTheme.apply_body(timer_label, 22)
	MiniGameTheme.apply_body(feedback_label, 22)
	MiniGameTheme.apply_muted(step_label, 14)
	MiniGameTheme.apply_primary(dial_label, 28)
	
	MiniGameTheme.style_progress_bar(progress_bar)
	
	# Progress bar reposition
	progress_bar.set_anchors_preset(Control.PRESET_CENTER)
	progress_bar.offset_left = -270
	progress_bar.offset_top = 50
	progress_bar.offset_bottom = 82

	# Hearts Box
	if hearts_label: hearts_label.visible = false
	hearts_box = HBoxContainer.new()
	hearts_box.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	hearts_box.offset_left = -150
	hearts_box.offset_top = 15
	hearts_box.offset_right = -30
	hearts_box.offset_bottom = 47
	hearts_box.alignment = BoxContainer.ALIGNMENT_END
	root.get_node("GameContainer").add_child(hearts_box)
	for i in range(3):
		var heart_rect = TextureRect.new()
		heart_rect.texture = load("res://src/assets/sprites/heart_pixel.svg")
		heart_rect.custom_minimum_size = Vector2(32, 32)
		heart_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		heart_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		hearts_box.add_child(heart_rect)

func _process(_delta: float) -> void:
	if not root._is_running:
		return
	if Input.is_action_pressed("Phone"):
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
	keycap_rect.scale = Vector2(0, 0)
	var tw := create_tween().set_trans(Tween.TRANS_BACK)
	tw.tween_property(keycap_rect, "scale", Vector2(1, 1), 0.2)
