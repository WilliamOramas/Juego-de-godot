class_name FaintingAnimationController
extends Node

var root: MiniFaintingFirstAid

# Tween references (for cleanup)
var _active_tweens: Array[Tween] = []

func setup(minigame: MiniFaintingFirstAid) -> void:
	root = minigame

func _add_tween(tw: Tween) -> void:
	if tw:
		_active_tweens.append(tw)
		tw.finished.connect(func(): _active_tweens.erase(tw), CONNECT_ONE_SHOT)

func kill_all() -> void:
	for tw in _active_tweens:
		if tw and tw.is_valid():
			tw.kill()
	_active_tweens.clear()

# ============================================================================
# PULSE ANIMATION (reusable for pulse_point and heart_icon)
# ============================================================================
func play_pulse(node: Control) -> Tween:
	if not node or not is_instance_valid(node):
		return null
	
	var tw := create_tween().set_parallel(true)
	_add_tween(tw)
	
	# Phase 1: Flash in (0.0s - 0.15s)
	tw.tween_property(node, "modulate:a", 1.0, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(node, "scale", Vector2(1.25, 1.25), 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	# Phase 2: Dip (0.15s - 0.3s)
	var chain1 := tw.chain().set_parallel(true)
	chain1.tween_property(node, "modulate:a", 0.4, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	chain1.tween_property(node, "scale", Vector2(0.9, 0.9), 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	
	# Phase 3: Peak (0.3s - 0.45s)
	var chain2 := chain1.chain().set_parallel(true)
	chain2.tween_property(node, "modulate:a", 1.0, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	chain2.tween_property(node, "scale", Vector2(1.4, 1.4), 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	# Phase 4: Fade out (0.45s - 1.0s)
	var chain3 := chain2.chain().set_parallel(true)
	chain3.tween_property(node, "modulate:a", 0.2, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	chain3.tween_property(node, "scale", Vector2(1.0, 1.0), 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	
	return tw

# ============================================================================
# HEARTBEAT ANIMATION (ECG heart icon)
# ============================================================================
func play_heartbeat(node: TextureRect) -> Tween:
	if not node or not is_instance_valid(node):
		return null
	
	var tw := create_tween().set_parallel(true)
	_add_tween(tw)
	
	# Phase 1: Beat in (0.0s - 0.15s)
	tw.tween_property(node, "modulate:a", 1.0, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(node, "scale", Vector2(1.2, 1.2), 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	# Phase 2: Dip (0.15s - 0.25s)
	var chain1 := tw.chain().set_parallel(true)
	chain1.tween_property(node, "modulate:a", 0.4, 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	chain1.tween_property(node, "scale", Vector2(0.95, 0.95), 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	
	# Phase 3: Peak (0.25s - 0.4s)
	var chain2 := chain1.chain().set_parallel(true)
	chain2.tween_property(node, "modulate:a", 1.0, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	chain2.tween_property(node, "scale", Vector2(1.35, 1.35), 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	# Phase 4: Fade out (0.4s - 0.9s)
	var chain3 := chain2.chain().set_parallel(true)
	chain3.tween_property(node, "modulate:a", 0.15, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	chain3.tween_property(node, "scale", Vector2(1.0, 1.0), 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	
	return tw

# ============================================================================
# STEP TRANSITION (fade out/in)
# ============================================================================
func play_step_transition(container: Control, callback: Callable) -> void:
	if not container or not is_instance_valid(container):
		callback.call()
		return
	
	var tw := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	_add_tween(tw)
	
	# Fade out
	tw.tween_property(container, "modulate:a", 0.0, 0.15)
	# Callback in middle
	tw.tween_callback(callback)
	# Fade in
	tw.tween_property(container, "modulate:a", 1.0, 0.15)

# ============================================================================
# FLASH EFFECT (error feedback)
# ============================================================================
func play_flash(node: CanvasItem, color: Color, duration: float = 0.15) -> Tween:
	if not node or not is_instance_valid(node):
		return null
	
	var original_modulate := node.modulate
	var tw := create_tween().set_trans(Tween.TRANS_QUAD)
	_add_tween(tw)
	
	tw.tween_property(node, "modulate", color, duration * 0.3).set_ease(Tween.EASE_OUT)
	tw.tween_property(node, "modulate", original_modulate, duration * 0.7).set_ease(Tween.EASE_IN)
	
	return tw

# ============================================================================
# SHAKE EFFECT (enhanced with zoom)
# ============================================================================
func play_shake(node: Node2D, intensity: float = 8.0, duration: float = 0.4) -> Tween:
	if not node or not is_instance_valid(node):
		return null
	
	var original_pos := node.position
	var tw := create_tween().set_trans(Tween.TRANS_QUINT)
	_add_tween(tw)
	
	var steps := 6
	var step_duration := duration / steps
	
	for i in range(steps):
		var offset := Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity))
		tw.tween_property(node, "position", original_pos + offset, step_duration)
		intensity *= 0.7
	
	tw.tween_property(node, "position", original_pos, step_duration)
	return tw

# ============================================================================
# POP EFFECT (scale 0 -> 1 with TRANS_BACK)
# ============================================================================
func play_pop(node: Control) -> Tween:
	if not node or not is_instance_valid(node):
		return null
	
	node.scale = Vector2(0, 0)
	var tw := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_add_tween(tw)
	
	tw.tween_property(node, "scale", Vector2(1, 1), 0.25)
	return tw

# ============================================================================
# COLOR TRANSITION (smooth color change)
# ============================================================================
func play_color_transition(node: CanvasItem, target_color: Color, duration: float = 0.3) -> Tween:
	if not node or not is_instance_valid(node):
		return null
	
	var tw := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	_add_tween(tw)
	
	tw.tween_property(node, "modulate", target_color, duration)
	return tw

# ============================================================================
# FLOATING TEXT (feedback text animation)
# ============================================================================
func play_floating_text(label: Label, start_pos: Vector2, end_pos: Vector2, duration: float = 1.0) -> Tween:
	if not label or not is_instance_valid(label):
		return null
	
	label.position = start_pos
	label.modulate.a = 1.0
	
	var tw := create_tween().set_parallel(true)
	_add_tween(tw)
	
	tw.tween_property(label, "position", end_pos, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(label, "modulate:a", 0.0, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	
	return tw

# ============================================================================
# CAMERA TRAUMA (for main camera shake)
# ============================================================================
var _trauma: float = 0.0
var _trauma_decay: float = 2.0

func add_trauma(amount: float) -> void:
	_trauma = clamp(_trauma + amount, 0.0, 1.0)

func _process(delta: float) -> void:
	if _trauma <= 0.0:
		return
	
	var main_camera := root.get_tree().root.get_camera_2d()
	if not main_camera:
		return
	
	var time := Time.get_ticks_msec() / 1000.0
	var shake_amount := _trauma * _trauma * 20.0
	
	var offset_x := (sin(time * 10.0) + cos(time * 7.3)) * shake_amount * 0.5
	var offset_y := (cos(time * 8.5) + sin(time * 6.7)) * shake_amount * 0.5
	
	main_camera.offset = Vector2(offset_x, offset_y)
	
	_trauma = max(0.0, _trauma - delta * _trauma_decay)
	
	if _trauma <= 0.0:
		main_camera.offset = Vector2.ZERO

func reset_camera() -> void:
	_trauma = 0.0
	var main_camera := root.get_tree().root.get_camera_2d()
	if main_camera:
		main_camera.offset = Vector2.ZERO
