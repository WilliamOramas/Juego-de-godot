class_name FaintingInputController
extends Node

signal step_completed
signal step_failed(reason: String)
signal progress_updated(value: float)
signal dial_updated(target: Array, current_index: int)
signal action_state_changed(state: String)
signal hold_decayed(p_visible: bool)

var root: MiniFaintingFirstAid
var visual: FaintingVisualController
var ui: FaintingUIController
var anim: FaintingAnimationController

# State variables
var sub_progress: int = 0
var hold_timer: float = 0.0
var dial_index: int = 0
var ecg_beat: int = 0
var ecg_active: bool = false
var ecg_waiting: bool = false
var pulse_active: bool = false
var pulse_window: float = 0.0
var pulse_skipped: bool = false
var hold_penalized: bool = false
var tap_timeout: float = 0.0
var ecg_timeout: float = 0.0

var _pulse_anim_timer: float = 0.0
var _touch_pressed: bool = false

func setup(minigame: MiniFaintingFirstAid, v_controller: FaintingVisualController, u_controller: FaintingUIController, animation_controller: FaintingAnimationController) -> void:
	root = minigame
	visual = v_controller
	ui = u_controller
	anim = animation_controller
	
	ui.touch_pressed.connect(_on_touch_pressed)
	ui.touch_released.connect(_on_touch_released)
	ui.touch_dial_pressed.connect(_on_touch_dial_pressed)

func reset_step() -> void:
	sub_progress = 0
	hold_timer = 0.0
	dial_index = 0
	ecg_beat = 0
	ecg_active = false
	ecg_waiting = false
	ecg_timeout = 0.0
	pulse_active = false
	pulse_window = 0.0
	pulse_skipped = false
	hold_penalized = false
	tap_timeout = 0.0
	_pulse_anim_timer = 0.0
	if visual.pulse_prompt:
		visual.pulse_prompt.text = ""
		visual.pulse_prompt.visible = false

func process_input(event: InputEvent, step: Dictionary) -> void:
	match step.type:
		MiniFaintingFirstAid.StepType.TAP:
			if event.is_action_pressed("Phone"):
				tap_timeout = 0.0
				sub_progress += 1
				action_state_changed.emit("action")
				if sub_progress >= step.target:
					step_completed.emit()
				else:
					_play_sound("CorrectSound")
		MiniFaintingFirstAid.StepType.DIAL_112:
			if event is InputEventKey and event.pressed and not event.is_echo():
				var key: int = event.keycode
				var expected: int = step.target[dial_index]
				if key == expected:
					dial_index += 1
					_play_sound("CorrectSound")
					dial_updated.emit(step.target, dial_index)
					if dial_index >= step.target.size():
						step_completed.emit()
				else:
					dial_index = 0
					dial_updated.emit(step.target, dial_index)
					step_failed.emit("Ese no es el número correcto.")
		MiniFaintingFirstAid.StepType.TIMED_PRESS:
			if event.is_action_pressed("Phone") and pulse_active:
				pulse_active = false
				step_completed.emit()
		MiniFaintingFirstAid.StepType.ECG:
			if event.is_action_pressed("Phone") and ecg_waiting:
				ecg_waiting = false
				ecg_timeout = 0.0
				if visual.heart_icon:
					visual.heart_icon.visible = false
				_play_sound("CorrectSound")
				_do_ecg_beat(step)

func process_frame(delta: float, step: Dictionary) -> void:
	match step.type:
		MiniFaintingFirstAid.StepType.HOLD_CHECK_RESPONSE, MiniFaintingFirstAid.StepType.HOLD_CHECK_BREATHING, MiniFaintingFirstAid.StepType.HOLD_ELEVATE:
			_handle_hold(delta, step)
		MiniFaintingFirstAid.StepType.TIMED_PRESS:
			_handle_timed_press(delta, step)
		MiniFaintingFirstAid.StepType.ECG:
			_handle_ecg(delta, step)
		MiniFaintingFirstAid.StepType.TAP:
			_handle_tap(delta, step)

func _handle_tap(delta: float, _step: Dictionary) -> void:
	tap_timeout += delta
	if tap_timeout >= 4.0:
		tap_timeout = 0.0
		step_failed.emit("¡Tenés que presionar Q!")

func _handle_hold(delta: float, step: Dictionary) -> void:
	var is_pressed = Input.is_action_pressed("Phone") or _touch_pressed
	if is_pressed:
		hold_timer += delta
		var p_val = clamp(hold_timer / step.target * 100.0, 0.0, 100.0)
		progress_updated.emit(p_val)
		if p_val > 50.0:
			action_state_changed.emit("action")
		else:
			action_state_changed.emit("idle")
		if hold_timer >= step.target:
			step_completed.emit()
	else:
		if hold_timer > 0.15 and not hold_penalized:
			hold_penalized = true
			step_failed.emit("¡Soltaste! Tenés que mantener Q presionado.")
		hold_timer = max(0, hold_timer - delta * 0.5)
		progress_updated.emit(clamp(hold_timer / step.target * 100.0, 0.0, 100.0))
		if hold_timer > 0:
			action_state_changed.emit("idle")
			hold_decayed.emit(true)
		else:
			if not hold_penalized:
				hold_decayed.emit(false)

func _on_touch_pressed() -> void:
	_touch_pressed = true
	var step = MiniFaintingFirstAid.STEP_DATA[root._current_step]
	match step.type:
		MiniFaintingFirstAid.StepType.TAP:
			if root._state == "playing":
				tap_timeout = 0.0
				sub_progress += 1
				action_state_changed.emit("action")
				if sub_progress >= step.target:
					step_completed.emit()
				else:
					_play_sound("CorrectSound")
		MiniFaintingFirstAid.StepType.TIMED_PRESS:
			if root._state == "playing" and pulse_active:
				pulse_active = false
				step_completed.emit()
		MiniFaintingFirstAid.StepType.ECG:
			if root._state == "playing" and ecg_waiting:
				ecg_waiting = false
				ecg_timeout = 0.0
				if visual.heart_icon:
					visual.heart_icon.visible = false
				_play_sound("CorrectSound")
				_do_ecg_beat(step)

func _on_touch_released() -> void:
	_touch_pressed = false

func _on_touch_dial_pressed(key: int) -> void:
	var step = MiniFaintingFirstAid.STEP_DATA[root._current_step]
	if step.type != MiniFaintingFirstAid.StepType.DIAL_112:
		return
	if root._state != "playing":
		return
	var expected: int = step.target[dial_index]
	if key == expected:
		dial_index += 1
		_play_sound("CorrectSound")
		dial_updated.emit(step.target, dial_index)
		if dial_index >= step.target.size():
			step_completed.emit()
	else:
		dial_index = 0
		dial_updated.emit(step.target, dial_index)
		step_failed.emit("Ese no es el número correcto.")

func _handle_timed_press(delta: float, _step: Dictionary) -> void:
	pulse_window += delta
	if pulse_window < 2.0 and not pulse_active and not pulse_skipped:
		if visual.pulse_prompt:
			visual.pulse_prompt.text = "Preparate para palpar el pulso..."
	elif pulse_window >= 2.0 and not pulse_active and not pulse_skipped:
		pulse_active = true
		pulse_window = 0.0
		if visual.pulse_prompt:
			visual.pulse_prompt.text = "¡PRESIONÁ Q AHORA!"
		action_state_changed.emit("action")
		anim.play_pulse(visual.pulse_point)
		_pulse_anim_timer = 1.0
	elif pulse_active:
		_pulse_anim_timer -= delta
		pulse_window += delta
		if _pulse_anim_timer <= 0.0:
			pulse_active = false
			pulse_skipped = true
			if visual.pulse_prompt:
				visual.pulse_prompt.text = ""
			if root._lives > 0:
				step_failed.emit("¡Te saltaste el pulso carotídeo! Es obligatorio.")
			_retry_timed_press()
		elif pulse_window > 1.5:
			pulse_active = false
			pulse_skipped = true
			if visual.pulse_prompt:
				visual.pulse_prompt.text = ""
			if root._lives > 0:
				step_failed.emit("¡Te saltaste el pulso carotídeo! Es obligatorio.")
			_retry_timed_press()

func _retry_timed_press() -> void:
	if root._lives <= 0: return
	pulse_skipped = false
	pulse_window = 0.0

func _handle_ecg(delta: float, step: Dictionary) -> void:
	if not ecg_active:
		ecg_active = true
		ecg_beat = 0
		_do_ecg_beat(step)
	elif ecg_waiting:
		ecg_timeout += delta
		if ecg_timeout >= 4.0:
			ecg_waiting = false
			ecg_timeout = 0.0
			if visual.heart_icon:
				visual.heart_icon.scale = Vector2(1.0, 1.0)
				visual.heart_icon.modulate.a = 0.15
			step_failed.emit("¡Presioná Q cuando el corazón parpadee!")
	else:
		_do_ecg_beat(step)

func _do_ecg_beat(step: Dictionary) -> void:
	if ecg_beat >= step.target:
		step_completed.emit()
		return
	ecg_beat += 1
	ecg_waiting = true
	ecg_timeout = 0.0
	action_state_changed.emit("action")
	anim.play_heartbeat(visual.heart_icon)

func _play_sound(sound_name: String) -> void:
	var sound: AudioStreamPlayer = root.get_node_or_null(sound_name)
	if sound: sound.play()
