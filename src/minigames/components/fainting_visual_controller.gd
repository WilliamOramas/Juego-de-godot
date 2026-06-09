class_name FaintingVisualController
extends Node

var root: MiniFaintingFirstAid
var patient_sprite: Sprite2D
var action_sprite: Sprite2D
var real_player: Node2D
var world_patient: Sprite2D

var pulse_point: Panel
var heart_icon: TextureRect
var pulse_prompt: Label
var ecg_line: ECGLineControl

var shake_timer: float = 0.0

const PATIENT = preload("res://src/assets/sprites/patient_lying.png")
const CURACION = preload("res://src/assets/sprites/curacion.png")
const PLAYER_ACTION_POS = Vector2(732.0, 620.0)

func setup(minigame: MiniFaintingFirstAid) -> void:
	root = minigame
	
	pulse_point = root.get_node_or_null("GameContainer/PulsePoint")
	heart_icon = root.get_node_or_null("GameContainer/HeartIcon")
	
	# Create ECG Line Control
	ecg_line = ECGLineControl.new()
	ecg_line.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.get_node("GameContainer").add_child(ecg_line)

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
		pulse_point.position = Vector2(326, 426)
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
	pulse_prompt.add_theme_font_size_override("font_size", 18)
	pulse_prompt.add_theme_color_override("font_color", Color(0.65, 0.1, 0.08, 1))
	pulse_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pulse_prompt.visible = false
	root.get_node("GameContainer").add_child(pulse_prompt)

	if heart_icon:
		heart_icon.custom_minimum_size = Vector2(32, 32)
		heart_icon.size = Vector2(32, 32)
		heart_icon.position = Vector2(378, 458)
		heart_icon.texture = load("res://src/assets/sprites/heart_pixel.svg")
		heart_icon.pivot_offset = Vector2(16, 16)

func _process(delta: float) -> void:
	if not root._is_running:
		return
	
	if ecg_line:
		ecg_line.lives = root._lives
	
	# Camera shake
	var trauma: float = 0.0
	if shake_timer > 0:
		shake_timer -= delta
		trauma = (shake_timer / 0.5) * 15.0
	
	var main_camera: Camera2D = root.get_viewport().get_camera_2d()
	if main_camera:
		var time: float = Time.get_ticks_msec() / 1000.0
		var wobble_x = sin(time * 2.5) * 1.5 + cos(time * 1.7) * 2.0
		var wobble_y = cos(time * 3.1) * 1.5 + sin(time * 1.3) * 2.0
		main_camera.offset = Vector2(wobble_x, wobble_y) + Vector2(randf_range(-trauma, trauma), randf_range(-trauma, trauma))

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
	shake_timer = 0.5
	if not action_sprite or not is_instance_valid(action_sprite):
		return
	var orig_pos = action_sprite.position
	var shake = create_tween().set_trans(Tween.TRANS_QUINT)
	shake.tween_property(action_sprite, "position", orig_pos + Vector2(4, 0), 0.05)
	shake.tween_property(action_sprite, "position", orig_pos + Vector2(-4, 0), 0.05)
	shake.tween_property(action_sprite, "position", orig_pos + Vector2(2, 0), 0.05)
	shake.tween_property(action_sprite, "position", orig_pos, 0.05)

func update_patient_color(lives: int) -> void:
	if patient_sprite:
		var colors = {3: Color.WHITE, 2: Color(1, 0.7, 0.7), 1: Color(1, 0.3, 0.3)}
		patient_sprite.modulate = colors.get(lives, Color(0.5, 0.1, 0.1))

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
	if real_player and is_instance_valid(real_player):
		real_player.z_index = 0
		var real_sprite = real_player.get_node("Sprite2D")
		if real_sprite:
			real_sprite.visible = true
	
	if action_sprite and is_instance_valid(action_sprite):
		action_sprite.queue_free()
		
	if world_patient and is_instance_valid(world_patient):
		world_patient.modulate = Color.WHITE
		if success:
			world_patient.visible = false
		else:
			world_patient.visible = true
			world_patient.modulate = Color(0.5, 0.1, 0.1)
			
	if patient_sprite and is_instance_valid(patient_sprite):
		patient_sprite.queue_free()
		
	var main_camera = root.get_viewport().get_camera_2d()
	if main_camera:
		main_camera.offset = Vector2.ZERO
