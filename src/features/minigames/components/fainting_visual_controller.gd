class_name FaintingVisualController
extends Node

var root: MiniFaintingFirstAid
var anim: FaintingAnimationController
var patient_sprite: Sprite2D
var action_sprite: Sprite2D
var real_player: Node2D
var world_patient: Sprite2D

var pulse_point: Panel
var heart_icon: TextureRect
var pulse_prompt: Label
var ecg_line: ECGLineControl

var shake_timer: float = 0.0

const PATIENT = preload("res://src/shared/assets/sprites/patient_lying.png")
const CURACION = preload("res://src/shared/assets/sprites/curacion.png")
const PLAYER_ACTION_POS = Vector2(732.0, 620.0)

func setup(minigame: MiniFaintingFirstAid, animation_controller: FaintingAnimationController) -> void:
	root = minigame
	anim = animation_controller
	
	pulse_point = root.game_container.get_node_or_null("PulsePoint")
	heart_icon = root.game_container.get_node_or_null("HeartIcon")
	
	# Create ECG Line Control (bottom strip, below all text)
	ecg_line = ECGLineControl.new()
	ecg_line.anchor_left = 0.0
	ecg_line.anchor_top = 0.0
	ecg_line.anchor_right = 1.0
	ecg_line.anchor_bottom = 0.0
	ecg_line.offset_left = 0
	ecg_line.offset_top = 560
	ecg_line.offset_right = 0
	ecg_line.offset_bottom = 656
	root.game_container.add_child(ecg_line)

	# Hide world patient and create local one
	var world = root.get_tree().current_scene
	if world:
		world_patient = world.find_child("PatientInWorld", true, false) as Sprite2D
		if world_patient:
			world_patient.visible = false
			patient_sprite = Sprite2D.new()
			patient_sprite.texture = PATIENT
			patient_sprite.centered = false
			patient_sprite.global_position = world_patient.global_position
			patient_sprite.scale = world_patient.scale
			world.add_child(patient_sprite)

		# Setup action sprite (player animation)
		real_player = world.find_child("Player", true, false) as Node2D
		if real_player and is_instance_valid(real_player):
			var real_sprite = real_player.get_node("Sprite2D")
			if real_sprite:
				real_sprite.visible = false
		
		action_sprite = Sprite2D.new()
		action_sprite.texture = CURACION
		action_sprite.hframes = MiniFaintingFirstAid.CURACION_HFRAMES
		action_sprite.vframes = MiniFaintingFirstAid.CURACION_VFRAMES
		action_sprite.frame = 7
		action_sprite.centered = true
		action_sprite.scale = Vector2(1.25, 1.25)
		world.add_child(action_sprite)
		action_sprite.global_position = PLAYER_ACTION_POS
		
		var kneel_tween = create_tween().set_trans(Tween.TRANS_QUINT)
		kneel_tween.tween_property(action_sprite, "frame", float(MiniFaintingFirstAid.STEP_ACTION_FRAMES[0].idle), 0.4)

	# Custom style for PulsePoint
	if pulse_point:
		pulse_point.custom_minimum_size = Vector2(48, 48)
		pulse_point.size = Vector2(48, 48)
		pulse_point.position = Vector2(416, 312)
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.0, 0.75, 1.0, 0.25)
		style.border_width_left = 4
		style.border_width_top = 4
		style.border_width_right = 4
		style.border_width_bottom = 4
		style.border_color = Color(0.0, 0.9, 1.0, 1.0)
		style.corner_radius_top_left = 24
		style.corner_radius_top_right = 24
		style.corner_radius_bottom_left = 24
		style.corner_radius_bottom_right = 24
		style.anti_aliasing = true
		pulse_point.add_theme_stylebox_override("panel", style)
		pulse_point.pivot_offset = Vector2(24, 24)

	# Pulse prompt label
	pulse_prompt = Label.new()
	MiniGameTheme.apply_body(pulse_prompt, 18)
	pulse_prompt.add_theme_color_override("font_color", MiniGameTheme.DANGER)
	pulse_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pulse_prompt.visible = false
	root.game_container.add_child(pulse_prompt)

	if heart_icon:
		heart_icon.custom_minimum_size = Vector2(32, 32)
		heart_icon.size = Vector2(32, 32)
		heart_icon.position = Vector2(480, 336)
		heart_icon.texture = load("res://src/shared/assets/sprites/heart_pixel.svg")
		heart_icon.pivot_offset = Vector2(16, 16)

func _process(_delta: float) -> void:
	if not root._is_running:
		return
	
	if ecg_line:
		ecg_line.lives = root._lives
	
	# Dynamic alignment of indicators on the patient
	if patient_sprite and is_instance_valid(patient_sprite) and patient_sprite.texture:
		var texture_size = patient_sprite.texture.get_size()
		if pulse_point and pulse_point.visible:
			var local_pos_pulse = Vector2(23.6, 33.2) - (texture_size / 2.0)
			var screen_pos_pulse = patient_sprite.get_global_transform_with_canvas() * local_pos_pulse
			pulse_point.position = screen_pos_pulse - pulse_point.size / 2.0
			if pulse_prompt:
				pulse_prompt.position = screen_pos_pulse + Vector2(-60, 40)
				pulse_prompt.visible = pulse_prompt.text != ""
		elif pulse_prompt:
			pulse_prompt.visible = false
			
		if heart_icon and heart_icon.visible:
			var local_pos_heart = Vector2(41.2, 42.8) - (texture_size / 2.0)
			var screen_pos_heart = patient_sprite.get_global_transform_with_canvas() * local_pos_heart
			heart_icon.position = screen_pos_heart - heart_icon.size / 2.0

func set_action_frame(step_index: int, frame_type: String = "idle") -> void:
	if not action_sprite or not is_instance_valid(action_sprite):
		return
	var frames: Dictionary = MiniFaintingFirstAid.STEP_ACTION_FRAMES[step_index]
	match frame_type:
		"idle":
			action_sprite.frame = frames.idle
		"action":
			action_sprite.frame = frames.action

func trigger_shake() -> void:
	anim.add_trauma(0.6)
	if action_sprite and is_instance_valid(action_sprite):
		anim.play_shake(action_sprite, 10.0, 0.5)

func flash_error() -> void:
	anim.play_flash(root.background, Color(0.8, 0.1, 0.1, 0.5), 0.2)

func update_patient_color(lives: int) -> void:
	if patient_sprite:
		var colors = {3: Color.WHITE, 2: Color(1, 0.7, 0.7), 1: Color(1, 0.3, 0.3)}
		var target_color = colors.get(lives, Color(0.5, 0.1, 0.1))
		anim.play_color_transition(patient_sprite, target_color, 0.3)

func toggle_indicators(step_type: int) -> void:
	if pulse_point:
		pulse_point.visible = (step_type == MiniFaintingFirstAid.StepType.TIMED_PRESS)
		pulse_point.modulate.a = 0.2
		pulse_point.scale = Vector2(1.0, 1.0)
		
	if heart_icon:
		heart_icon.visible = (step_type == MiniFaintingFirstAid.StepType.ECG)
		heart_icon.modulate.a = 0.15
		heart_icon.scale = Vector2(1.0, 1.0)

func cleanup(success: bool) -> void:
	anim.kill_all()
	anim.reset_camera()
	
	if real_player and is_instance_valid(real_player):
		real_player.z_index = 0
		var real_sprite = real_player.get_node("Sprite2D")
		if real_sprite:
			real_sprite.visible = true
	
	if action_sprite and is_instance_valid(action_sprite):
		action_sprite.queue_free()
		
	if world_patient and is_instance_valid(world_patient):
		world_patient.z_index = -1
		world_patient.modulate = Color.WHITE
		if success:
			world_patient.visible = false
		else:
			world_patient.visible = true
			world_patient.modulate = Color(0.5, 0.1, 0.1)
			
	if patient_sprite and is_instance_valid(patient_sprite):
		patient_sprite.queue_free()
