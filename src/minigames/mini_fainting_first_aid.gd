extends MiniGameBase
class_name MiniFaintingFirstAid

enum StepType { HOLD_3, TIMED_PRESS, DIAL_112, HOLD_ELEVATE, TAP, ECG }

const STEP_DATA: Array = [
	{
		"instruction": "La persona está en el suelo.\n¿Qué hacés primero?",
		"help": "Paso 1: Verificar si responde.\nGritale fuerte y tocale el hombro.\n[Q] Mantené 1.5 segundos.",
		"type": StepType.HOLD_3,
		"target": 1.5,
		"feedback_ok": "¡Bien! Verificaste si responde.",
		"feedback_fail": "Tenés que verificar si responde primero.",
	},
	{
		"instruction": "No responde. ¿Qué hacés ahora?",
		"help": "Paso 2: Verificar respiración.\nObservá su pecho.\n[Q] Mantené 3 segundos.",
		"type": StepType.HOLD_3,
		"target": 3.0,
		"feedback_ok": "¡Bien! Verificaste la respiración.",
		"feedback_fail": "Tenés que mantener Q para verificar.",
	},
	{
		"instruction": "¿Y el pulso carotídeo?",
		"help": "Paso 3: Verificar pulso carotídeo.\n[Q] Presioná cuando el punto parpadee.\n¡No te lo saltes!",
		"type": StepType.TIMED_PRESS,
		"target": 1,
		"window": 1.0,
		"feedback_ok": "¡Bien! Pulso detectado.",
		"feedback_fail": "¡No te saltes el pulso carotídeo!",
	},
	{
		"instruction": "No tiene pulso. ¿Qué hacés?",
		"help": "Paso 4: Llamar emergencias.\nMarcá 1-1-2 en el teclado.\n[_][_][_]",
		"type": StepType.DIAL_112,
		"target": [KEY_1, KEY_1, KEY_2],
		"feedback_ok": "¡Bien! Pediste ayuda.",
		"feedback_fail": "El número de emergencias es 112.",
	},
	{
		"instruction": "La ayuda viene en camino.\n¿Cómo ponés al paciente?",
		"help": "Paso 5: Elevar piernas.\n[Q] Mantené para elevarlas.\nEsto mejora la circulación.",
		"type": StepType.HOLD_ELEVATE,
		"target": 2.0,
		"feedback_ok": "¡Bien! Piernas elevadas.",
		"feedback_fail": "Tenés que mantener Q para elevar piernas.",
	},
	{
		"instruction": "¿Qué más podés hacer?",
		"help": "Paso 6: Aflojar ropa ajustada.\n[Q] Presioná para aflojar.",
		"type": StepType.TAP,
		"target": 1,
		"feedback_ok": "¡Bien! Ropa aflojada.",
		"feedback_fail": "Tenés que presionar Q.",
	},
	{
		"instruction": "La persona está mejorando.\nMonitoreala hasta que llegue la ayuda.",
		"help": "Paso 7: Monitorear signos vitales.\n[Q] Presioná cuando el corazón parpadee.\n3 veces.",
		"type": StepType.ECG,
		"target": 3,
		"feedback_ok": "¡Bien! Monitoreaste correctamente.",
		"feedback_fail": "Tenés que presionar Q cuando el corazón parpadee.",
	},
]

@onready var instruction_label: Label = $GameContainer/InstructionLabel
@onready var help_label: Label = $GameContainer/HelpLabel
@onready var timer_label: Label = $GameContainer/TimerLabel
@onready var feedback_label: Label = $GameContainer/FeedbackLabel
@onready var hearts_label: Label = $GameContainer/HeartsLabel
@onready var step_label: Label = $GameContainer/StepLabel
@onready var progress_bar: TextureProgressBar = $GameContainer/ProgressBar
@onready var patient_sprite: Sprite2D = $GameContainer/PatientSprite
@onready var dial_label: Label = $GameContainer/DialLabel

var _current_step: int = 0
var _lives: int = 3
var _sub_progress: int = 0
var _hold_timer: float = 0.0
var _dial_index: int = 0
var _ecg_beat: int = 0
var _ecg_active: bool = false
var _ecg_waiting: bool = false
var _pulse_active: bool = false
var _pulse_window: float = 0.0
var _pulse_skipped: bool = false

const TIME_LIMIT: float = 60.0

var _pulse_tween: Tween
var _ecg_tween: Tween
var _ecg_timeout: float = 0.0
var _time_remaining: float
var _hold_penalized: bool = false
var _tap_timeout: float = 0.0

var _state: String = "playing"
var _state_timer: float = 0.0

func _ready() -> void:
	super()
	_time_remaining = TIME_LIMIT
	progress_bar.visible = false
	_reset_step()

func _reset_step() -> void:
	if _pulse_tween:
		_pulse_tween.kill()
		_pulse_tween = null
	if _ecg_tween:
		_ecg_tween.kill()
		_ecg_tween = null
	_sub_progress = 0
	_hold_timer = 0.0
	_dial_index = 0
	_ecg_beat = 0
	_ecg_active = false
	_ecg_waiting = false
	_ecg_timeout = 0.0
	_pulse_active = false
	_pulse_window = 0.0
	_pulse_skipped = false
	_hold_penalized = false
	_tap_timeout = 0.0
	_state = "playing"
	_state_timer = 0.0
	_update_ui()

func _update_timer_label() -> void:
	var secs: int = clampi(int(ceil(_time_remaining)), 0, 999)
	var mins: int = int(secs / 60.0)
	var secs_remain: int = secs % 60
	timer_label.text = "%02d:%02d" % [mins, secs_remain]
	if _time_remaining <= 10.0:
		timer_label.modulate = Color.RED
	elif _time_remaining <= 30.0:
		timer_label.modulate = Color.YELLOW
	else:
		timer_label.modulate = Color.WHITE

func _update_patient_color() -> void:
	match _lives:
		3:
			patient_sprite.modulate = Color.WHITE
		2:
			patient_sprite.modulate = Color(1, 0.7, 0.7)
		1:
			patient_sprite.modulate = Color(1, 0.3, 0.3)
		_:
			patient_sprite.modulate = Color(0.5, 0.1, 0.1)

func _update_dial_label() -> void:
	var step = STEP_DATA[_current_step]
	if step.type != StepType.DIAL_112:
		dial_label.visible = false
		return
	dial_label.visible = true
	var display := ""
	for i in step.target.size():
		if i < _dial_index:
			display += "[%d] " % step.target[i]
		else:
			display += "[_] "
	dial_label.text = display.strip_edges()

func _update_ui() -> void:
	var step = STEP_DATA[_current_step]
	instruction_label.text = step.instruction
	help_label.text = "[ " + step.help + " ]"
	step_label.text = "Paso %d/%d" % [_current_step + 1, STEP_DATA.size()]
	hearts_label.text = ""
	for i in _lives:
		hearts_label.text += "❤"
	feedback_label.text = ""
	_hold_penalized = false
	progress_bar.visible = (step.type == StepType.HOLD_3 or step.type == StepType.HOLD_ELEVATE)
	_update_timer_label()
	_update_patient_color()
	_update_dial_label()

func _advance_step() -> void:
	_current_step += 1
	if _current_step >= STEP_DATA.size():
		feedback_label.modulate = Color.GREEN
		feedback_label.text = "✓ ¡Completaste los primeros auxilios!"
		var fanfare: AudioStreamPlayer = get_node_or_null("SuccessFanfare")
		if fanfare: fanfare.play()
		_state = "complete_delay"
		_state_timer = 2.0
		return
	_reset_step()

func _lose_life(msg: String) -> void:
	if _pulse_tween:
		_pulse_tween.kill()
		_pulse_tween = null
	if _ecg_tween:
		_ecg_tween.kill()
		_ecg_tween = null
	_lives -= 1
	feedback_label.modulate = Color.RED
	feedback_label.text = "✗ " + msg
	var wrong: AudioStreamPlayer = get_node_or_null("WrongSound")
	if wrong:
		wrong.play()
	if _lives <= 0:
		var fail: AudioStreamPlayer = get_node_or_null("FailSound")
		if fail: fail.play()
		feedback_label.text = "✗ EL ESTUDIANTE HA FALLECIDO"
		Global.student_died = true
		_state = "death_delay"
		_state_timer = 2.5
		return
	_state = "step_fail_delay"
	_state_timer = 1.5

func _on_step_ok() -> void:
	var step = STEP_DATA[_current_step]
	feedback_label.modulate = Color.GREEN
	feedback_label.text = "✓ " + step.feedback_ok
	var correct: AudioStreamPlayer = get_node_or_null("CorrectSound")
	if correct:
		correct.play()
	_state = "step_ok_delay"
	_state_timer = 0.8

func _process(delta: float) -> void:
	if not _is_running:
		return
	if _state == "step_ok_delay":
		_state_timer -= delta
		if _state_timer <= 0:
			_state = "playing"
			feedback_label.modulate = Color.WHITE
			feedback_label.text = ""
			var step_sound: AudioStreamPlayer = get_node_or_null("StepSound")
			if step_sound:
				step_sound.play()
			_advance_step()
		return
	if _state == "step_fail_delay":
		_state_timer -= delta
		if _state_timer <= 0:
			_state = "playing"
			feedback_label.modulate = Color.WHITE
			feedback_label.text = ""
			_update_ui()
		return
	if _state == "death_delay":
		_state_timer -= delta
		if _state_timer <= 0:
			_state = "playing"
			end(false)
		return
	if _state == "complete_delay":
		_state_timer -= delta
		if _state_timer <= 0:
			_state = "playing"
			end(true)
		return
	_time_remaining -= delta
	_update_timer_label()
	if _time_remaining <= 0:
		_time_remaining = 0
		_lives = 1
		_lose_life("¡Se acabó el tiempo!")
		return
	var step = STEP_DATA[_current_step]
	match step.type:
		StepType.HOLD_3, StepType.HOLD_ELEVATE:
			_handle_hold(delta, step)
		StepType.TIMED_PRESS:
			_handle_timed_press(delta, step)
		StepType.ECG:
			_handle_ecg(delta, step)
		StepType.TAP:
			_handle_tap(delta, step)

func _input(event: InputEvent) -> void:
	if not _is_running:
		return
	if event.is_action_pressed("Phone"):
		get_viewport().set_input_as_handled()
	if _state != "playing":
		return
	var step = STEP_DATA[_current_step]
	match step.type:
		StepType.TAP:
			if event.is_action_pressed("Phone"):
				_tap_timeout = 0.0
				_sub_progress += 1
				if _sub_progress >= step.target:
					_on_step_ok()
				else:
					var correct: AudioStreamPlayer = get_node_or_null("CorrectSound")
					if correct:
						correct.play()
		StepType.DIAL_112:
			if event is InputEventKey and event.pressed and not event.is_echo():
				var key = event.keycode
				var expected = step.target[_dial_index]
				if key == expected:
					_dial_index += 1
					var correct: AudioStreamPlayer = get_node_or_null("CorrectSound")
					if correct:
						correct.play()
					_update_dial_label()
					if _dial_index >= step.target.size():
						_on_step_ok()
				else:
					_dial_index = 0
					_update_dial_label()
					_lose_life("Ese no es el número correcto.")
		StepType.TIMED_PRESS:
			if event.is_action_pressed("Phone") and _pulse_active:
				_pulse_active = false
				_on_step_ok()
		StepType.ECG:
			if event.is_action_pressed("Phone") and _ecg_waiting:
				_ecg_waiting = false
				_ecg_timeout = 0.0
				var heart = get_node_or_null("GameContainer/HeartIcon")
				if heart:
					heart.visible = false
				var correct: AudioStreamPlayer = get_node_or_null("CorrectSound")
				if correct:
					correct.play()
				_do_ecg_beat(step)

func _handle_tap(delta: float, _step: Dictionary) -> void:
	_tap_timeout += delta
	if _tap_timeout >= 4.0:
		_tap_timeout = 0.0
		_lose_life("¡Tenés que presionar Q!")

func _handle_hold(delta: float, step: Dictionary) -> void:
	if Input.is_action_pressed("Phone"):
		_hold_timer += delta
		progress_bar.value = clamp(_hold_timer / step.target * 100.0, 0.0, 100.0)
		if _hold_timer >= step.target:
			_on_step_ok()
	else:
		if _hold_timer > 0.15 and not _hold_penalized:
			_hold_penalized = true
			_lose_life("¡Soltaste! Tenés que mantener Q presionado.")
		_hold_timer = max(0, _hold_timer - delta * 0.5)
		progress_bar.value = clamp(_hold_timer / step.target * 100.0, 0.0, 100.0)
		if _hold_timer > 0:
			feedback_label.modulate = Color.RED
			feedback_label.text = "¡Soltaste! Seguí manteniendo Q."
		else:
			feedback_label.text = ""

func _handle_timed_press(delta: float, _step: Dictionary) -> void:
	_pulse_window += delta
	if _pulse_window >= 2.0 and not _pulse_active and not _pulse_skipped:
		_pulse_active = true
		_pulse_window = 0.0
		var pulse = get_node_or_null("GameContainer/PulsePoint")
		if pulse:
			pulse.visible = true
			pulse.modulate.a = 0.3
			if _pulse_tween:
				_pulse_tween.kill()
			_pulse_tween = create_tween()
			_pulse_tween.tween_property(pulse, "modulate:a", 1.0, 0.4)
			_pulse_tween.tween_property(pulse, "modulate:a", 0.3, 0.5)
			_pulse_tween.tween_callback(func():
				pulse.visible = false
				pulse.modulate.a = 0.3
				if _pulse_active:
					_pulse_active = false
					_pulse_skipped = true
					_lose_life("¡Te saltaste el pulso carotídeo! Es obligatorio.")
				_retry_timed_press()
				_pulse_tween = null
			)
	elif _pulse_active:
		if _pulse_window > 1.5:
			_pulse_active = false
			_pulse_skipped = true
			_lose_life("¡Te saltaste el pulso carotídeo! Es obligatorio.")
			_retry_timed_press()

func _retry_timed_press() -> void:
	if _lives <= 0:
		return
	_pulse_skipped = false
	_pulse_window = 0.0

func _handle_ecg(delta: float, step: Dictionary) -> void:
	if not _ecg_active:
		_ecg_active = true
		_ecg_beat = 0
		_do_ecg_beat(step)
	elif _ecg_waiting:
		_ecg_timeout += delta
		if _ecg_timeout >= 4.0:
			_ecg_waiting = false
			_ecg_timeout = 0.0
			if _ecg_tween:
				_ecg_tween.kill()
				_ecg_tween = null
			var heart = get_node_or_null("GameContainer/HeartIcon")
			if heart:
				heart.visible = false
				heart.modulate.a = 0.0
			_lose_life("¡Presioná Q cuando el corazón parpadee!")
	else:
		if _ecg_tween:
			_ecg_tween.kill()
			_ecg_tween = null
		_do_ecg_beat(step)

func _do_ecg_beat(step: Dictionary) -> void:
	if _ecg_beat >= step.target:
		_on_step_ok()
		return
	_ecg_beat += 1
	_ecg_waiting = true
	_ecg_timeout = 0.0
	var heart = get_node_or_null("GameContainer/HeartIcon")
	if heart:
		heart.visible = true
		heart.scale = Vector2(1, 1)
		if _ecg_tween:
			_ecg_tween.kill()
		_ecg_tween = create_tween().set_parallel(true)
		_ecg_tween.tween_property(heart, "modulate:a", 1.0, 0.25)
		_ecg_tween.tween_property(heart, "scale", Vector2(1.15, 1.15), 0.25)
		_ecg_tween.tween_property(heart, "modulate:a", 0.0, 0.8).set_delay(0.3)
		_ecg_tween.tween_property(heart, "scale", Vector2(1, 1), 0.8).set_delay(0.3)
		_ecg_tween.finished.connect(func():
			_ecg_tween = null
		)
