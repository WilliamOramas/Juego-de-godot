extends MiniGameBase
class_name MiniCPR

enum StepType { SAFETY, COMPRESS, BREATH, CYCLE, DIAL_112 }
enum CompressionQuality { PERFECT, OK, FAIL }
enum CyclePhase { COMPRESSIONS, BREATHS }

const BPM: float = 110.0
const BPM_INTERVAL: float = 60.0 / BPM
const TIME_LIMIT: float = 90.0
const COMPRESSIONS_PER_CYCLE: int = 30
const BREATHS_PER_CYCLE: int = 2
const TOTAL_CYCLES: int = 3
const DEPTH_TARGET: float = 0.8
const DEPTH_MIN_OK: float = 0.4

const STEP_DATA: Array[Dictionary] = [
	{
		"instruction": "Verificá que la escena sea segura",
		"help": "Mirá alrededor. Si hay peligro, no te acerques.\n[Q] Presioná para confirmar.",
		"type": StepType.SAFETY,
		"target": 1,
		"feedback_ok": "Escena segura. Iniciando RCP.",
		"feedback_fail": "¡No te olvides de verificar la escena!",
	},
	{
		"instruction": "30 compresiones torácicas",
		"help": "Presioná [Q] al ritmo del anillo.\nMantené para medir profundidad.\nSoltá para completar.",
		"type": StepType.COMPRESS,
		"target": COMPRESSIONS_PER_CYCLE,
		"cycle_label": "Ciclo 1/3",
		"feedback_ok": "30 compresiones completadas.",
		"feedback_fail": "¡No frenes las compresiones!",
	},
	{
		"instruction": "2 respiraciones de rescate",
		"help": "1: Incliná cabeza [Q]\n2: Sellá boca [Q]\n3: Soplá 1s [Q]",
		"type": StepType.BREATH,
		"target": BREATHS_PER_CYCLE,
		"cycle_label": "Ciclo 1/3",
		"feedback_ok": "Respiraciones completadas.",
		"feedback_fail": "¡No olvides las respiraciones!",
	},
	{
		"instruction": "Ciclo completo 30:2",
		"help": "Repetí compresiones y respiraciones.",
		"type": StepType.CYCLE,
		"target": TOTAL_CYCLES - 1,
		"feedback_ok": "RCP completa. ¡Ritmo restaurado!",
		"feedback_fail": "El paciente no resistió.",
	},
	{
		"instruction": "Llamá al 112",
		"help": "Marcá 1-1-2 en el teclado.\n[_][_][_]",
		"type": StepType.DIAL_112,
		"target": [KEY_1, KEY_1, KEY_2],
		"feedback_ok": "112 notificado. Ayuda en camino.",
		"feedback_fail": "¡Tenés que avisar a emergencias!",
	},
]

@onready var instruction_label: Label = $GameContainer/InstructionLabel
@onready var help_label: Label = $GameContainer/HelpLabel
@onready var timer_label: Label = $GameContainer/TimerLabel
@onready var feedback_label: Label = $GameContainer/FeedbackLabel
@onready var step_label: Label = $GameContainer/StepLabel
@onready var progress_bar: TextureProgressBar = $GameContainer/ProgressBar
@onready var depth_bar: TextureProgressBar = $GameContainer/DepthBar
@onready var rhythm_ring: Control = $GameContainer/RhythmRing
@onready var ecg_line: Control = $GameContainer/ECGLine
@onready var breath_prompt: Label = $GameContainer/BreathPrompt
@onready var patient_sprite: Sprite2D = $GameContainer/PatientSprite
@onready var dial_label: Label = $GameContainer/DialLabel

@onready var correct_sound: AudioStreamPlayer = $CorrectSound
@onready var wrong_sound: AudioStreamPlayer = $WrongSound
@onready var step_sound: AudioStreamPlayer = $StepSound
@onready var success_fanfare: AudioStreamPlayer = $SuccessFanfare
@onready var fail_sound: AudioStreamPlayer = $FailSound
@onready var bgm_player: AudioStreamPlayer = $BgmPlayer
@onready var heartbeat_player: AudioStreamPlayer = $HeartbeatPlayer

var _current_step: int = 0
var _lives: int = 5
var _compression_count: int = 0
var _breath_count: int = 0
var _breath_substep: int = 0
var _cycle_count: int = 0
var _cycle_phase: CyclePhase = CyclePhase.COMPRESSIONS
var _ring_progress: float = 0.0
var _depth_hold: float = 0.0
var _depth_active: bool = false
var _time_remaining: float
var _dial_index: int = 0
var _breath_hold_timer: float = 0.0
var _breath_substep_active: bool = false
var _ecg_time: float = 0.0
var _ecg_freq: float = 1.0
var _combo: int = 0
var _compression_timeout: float = 0.0

var _state: String = "playing"
var _state_timer: float = 0.0


func _ready() -> void:
	super()
	_time_remaining = TIME_LIMIT
	progress_bar.visible = false
	rhythm_ring.draw.connect(_on_rhythm_ring_draw)
	ecg_line.draw.connect(_on_ecg_draw)

	instruction_label.anchor_left = 0.0
	instruction_label.anchor_top = 0.0
	instruction_label.anchor_right = 0.0
	instruction_label.anchor_bottom = 0.0
	instruction_label.offset_left = 80
	instruction_label.offset_top = 80
	instruction_label.offset_right = 580
	instruction_label.offset_bottom = 130

	help_label.anchor_left = 0.0
	help_label.anchor_top = 0.0
	help_label.anchor_right = 0.0
	help_label.anchor_bottom = 0.0
	help_label.offset_left = 80
	help_label.offset_top = 140
	help_label.offset_right = 580
	help_label.offset_bottom = 200

	step_label.set_anchors_preset(Control.PRESET_TOP_LEFT)
	step_label.offset_left = 20
	step_label.offset_top = 20

	timer_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	timer_label.offset_left = -50
	timer_label.offset_top = 15
	timer_label.offset_right = 50

	patient_sprite.position = Vector2(400, 510)
	patient_sprite.scale = Vector2(2.5, 2.5)

	bgm_player.play()
	heartbeat_player.play()
	heartbeat_player.finished.connect(func(): heartbeat_player.play())

	MiniGameTheme.apply_body(instruction_label, 18)
	MiniGameTheme.apply_muted(help_label, 14)
	MiniGameTheme.style_text_panel(instruction_label)
	MiniGameTheme.style_text_panel(help_label)
	MiniGameTheme.apply_body(timer_label, 22)
	MiniGameTheme.apply_body(feedback_label, 22)
	MiniGameTheme.apply_muted(step_label, 14)
	MiniGameTheme.apply_primary(dial_label, 28)
	MiniGameTheme.apply_body(breath_prompt, 20)

	MiniGameTheme.style_progress_bar(progress_bar)
	MiniGameTheme.style_progress_bar(depth_bar)

	_update_ui()


func _update_timer_label() -> void:
	var secs: int = clampi(int(ceil(_time_remaining)), 0, 999)
	var mins: int = int(secs / 60.0)
	var secs_remain: int = secs % 60
	timer_label.text = "%02d:%02d" % [mins, secs_remain]
	if _time_remaining <= 15.0:
		timer_label.modulate = MiniGameTheme.FEEDBACK_BAD
	elif _time_remaining <= 30.0:
		timer_label.modulate = MiniGameTheme.FEEDBACK_WARN
	else:
		timer_label.modulate = MiniGameTheme.TEXT_PRIMARY


func _update_ecg_freq() -> void:
	if _lives >= 4:
		_ecg_freq = 1.0
	elif _lives >= 2:
		_ecg_freq = 1.8
	elif _lives >= 1:
		_ecg_freq = 3.0
	else:
		_ecg_freq = 0.0


func _update_ui() -> void:
	var step: Dictionary = STEP_DATA[_current_step]
	instruction_label.text = step.instruction
	var help: String = step.help
	if step.has("cycle_label"):
		help = step.cycle_label + "\n" + help
	elif step.type == StepType.CYCLE:
		var remaining = max(0, step.target - _cycle_count)
		help = "Ciclo %d/%d - Restan %d\n" % [_cycle_count + 1, TOTAL_CYCLES, remaining] + help
	help_label.text = help
	step_label.text = "Paso %d/%d" % [_current_step + 1, STEP_DATA.size()]
	feedback_label.text = ""
	_update_timer_label()

	progress_bar.visible = (step.type == StepType.COMPRESS or step.type == StepType.CYCLE)
	depth_bar.visible = false
	rhythm_ring.visible = (step.type == StepType.COMPRESS or step.type == StepType.CYCLE)
	breath_prompt.visible = (step.type == StepType.BREATH)
	dial_label.visible = (step.type == StepType.DIAL_112)

	if step.type == StepType.COMPRESS or step.type == StepType.CYCLE:
		progress_bar.max_value = COMPRESSIONS_PER_CYCLE
		progress_bar.value = _compression_count

	patient_sprite.modulate = _get_patient_color()


func _get_patient_color() -> Color:
	match _lives:
		5, 4:
			return MiniGameTheme.TEXT_PRIMARY
		3:
			return Color(1, 0.7, 0.7)
		2:
			return Color(1, 0.4, 0.4)
		1:
			return Color(1, 0.2, 0.2)
		_:
			return Color(0.3, 0.1, 0.1)


func _process(delta: float) -> void:
	if not _is_running:
		return

	_ecg_time += delta
	if ecg_line:
		ecg_line.queue_redraw()
	if rhythm_ring and rhythm_ring.visible:
		rhythm_ring.queue_redraw()

	var main_camera: Camera2D = get_viewport().get_camera_2d()
	if main_camera and main_camera.offset.length() > 0.01:
		main_camera.offset = main_camera.offset.lerp(Vector2.ZERO, delta * 5.0)

	if _state == "step_ok_delay":
		_state_timer -= delta
		if _state_timer <= 0:
			_state = "playing"
			feedback_label.text = ""
			step_sound.play()
			_advance_step()
		return

	if _state == "step_fail_delay":
		_state_timer -= delta
		if _state_timer <= 0:
			_state = "playing"
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
		_lose_life("¡Se acabó el tiempo!")
		return

	var step: Dictionary = STEP_DATA[_current_step]
	match step.type:
		StepType.COMPRESS:
			_handle_compressions(delta, step)
		StepType.BREATH:
			_handle_breaths(delta, step)
		StepType.CYCLE:
			_handle_cycle(delta, step)
		StepType.DIAL_112:
			pass


func _input(event: InputEvent) -> void:
	if not _is_running:
		return
	if event.is_action_pressed("Phone"):
		get_viewport().set_input_as_handled()
	if _state != "playing":
		return

	var step: Dictionary = STEP_DATA[_current_step]
	match step.type:
		StepType.SAFETY:
			if event.is_action_pressed("Phone"):
				_on_step_ok()

		StepType.COMPRESS, StepType.CYCLE:
			if event.is_action_pressed("Phone"):
				_depth_active = true
				_depth_hold = 0.0
				depth_bar.visible = true
				depth_bar.value = 0.0

			if event.is_action_released("Phone") and _depth_active:
				_depth_active = false
				depth_bar.visible = false
				_register_compression()

		StepType.BREATH:
			if event.is_action_pressed("Phone"):
				_handle_breath_input()

		StepType.DIAL_112:
			if event is InputEventKey and event.pressed and not event.is_echo():
				var key: int = event.keycode
				var expected: int = step.target[_dial_index]
				if key == expected:
					_dial_index += 1
					correct_sound.play()
					_update_dial_label()
					if _dial_index >= step.target.size():
						_on_step_ok()
				else:
					_dial_index = 0
					_update_dial_label()
					_lose_life("Ese no es el número correcto.")


func _register_compression() -> void:
	var step: Dictionary = STEP_DATA[_current_step]
	var zone: String = _get_ring_zone(_ring_progress)
	var depth_ratio: float = _depth_hold / DEPTH_TARGET

	var quality: CompressionQuality
	if zone == "green" and depth_ratio >= DEPTH_MIN_OK:
		quality = CompressionQuality.PERFECT
		_combo += 1
	elif zone == "yellow" or (zone == "green" and depth_ratio < DEPTH_MIN_OK):
		quality = CompressionQuality.OK
		_combo = 0
	else:
		quality = CompressionQuality.FAIL
		_combo = 0

	if quality == CompressionQuality.FAIL:
		_lose_life("Compresión fuera de ritmo.")
		return

	_compression_count += 1
	ScoreManager.record_minigame_step(true)

	if quality == CompressionQuality.PERFECT:
		correct_sound.play()
		feedback_label.modulate = MiniGameTheme.FEEDBACK_GOOD
		feedback_label.text = "PERFECT"
	else:
		step_sound.play()
		feedback_label.modulate = MiniGameTheme.FEEDBACK_WARN
		feedback_label.text = "OK"

	progress_bar.value = _compression_count
	patient_sprite.scale.y = 2.5 * 0.85

	var tw = create_tween()
	tw.tween_property(patient_sprite, "scale:y", 2.5, 0.15)

	if _compression_count >= step.target:
		if step.type == StepType.CYCLE:
			_cycle_phase = CyclePhase.BREATHS
			_breath_count = 0
			_compression_count = 0
			_update_cycle_ui()
		else:
			_on_step_ok()


func _get_ring_zone(progress: float) -> String:
	if progress >= 0.2 and progress < 0.5:
		return "green"
	elif progress >= 0.5 and progress < 0.7:
		return "yellow"
	else:
		return "red"


func _handle_compressions(delta: float, _step: Dictionary) -> void:
	_ring_progress += delta / BPM_INTERVAL
	if _ring_progress >= 1.0:
		_ring_progress -= 1.0

	_compression_timeout += delta
	if _compression_timeout >= 4.0:
		_compression_timeout = 0.0
		_lose_life("¡Presioná Q al ritmo!")

	if _depth_active:
		_depth_hold += delta
		if _depth_hold >= DEPTH_TARGET:
			_depth_hold = DEPTH_TARGET
		depth_bar.value = clamp(_depth_hold / DEPTH_TARGET * 100.0, 0.0, 100.0)


func _handle_cycle(delta: float, step: Dictionary) -> void:
	match _cycle_phase:
		CyclePhase.COMPRESSIONS:
			_handle_compressions(delta, step)
		CyclePhase.BREATHS:
			_handle_breaths(delta, step)


func _update_cycle_ui() -> void:
	help_label.text = "Respiración %d/%d" % [_breath_count + 1, BREATHS_PER_CYCLE]
	feedback_label.text = ""
	progress_bar.visible = false
	rhythm_ring.visible = false
	breath_prompt.visible = true
	depth_bar.visible = false
	instruction_label.text = "Respiraciones - Ciclo %d/%d" % [_cycle_count + 1, TOTAL_CYCLES]
	_breath_substep = 0
	_breath_substep_active = false
	_update_breath_prompt()


func _update_breath_prompt() -> void:
	match _breath_substep:
		0:
			breath_prompt.text = "Paso 1: Incliná la cabeza\n[Q] para inclinar"
		1:
			breath_prompt.text = "Paso 2: Sellá la boca\n[Q] para sellar"
		2:
			breath_prompt.text = "Paso 3: Soplá 1 segundo\n[Q] mantené 1s"


func _handle_breath_input() -> void:
	if _breath_substep == 0:
		_breath_substep = 1
		correct_sound.play()
		_update_breath_prompt()
	elif _breath_substep == 1:
		_breath_substep = 2
		correct_sound.play()
		_update_breath_prompt()
	elif _breath_substep == 2:
		_breath_substep_active = true
		_breath_hold_timer = 0.0
		breath_prompt.text = "Soplando..."


func _handle_breaths(delta: float, _step: Dictionary) -> void:
	if _breath_substep_active:
		_breath_hold_timer += delta
		if _breath_hold_timer >= 1.0:
			_breath_substep_active = false
			_breath_count += 1
			correct_sound.play()
			feedback_label.modulate = MiniGameTheme.FEEDBACK_GOOD
			feedback_label.text = "Respiración %d/%d" % [_breath_count, BREATHS_PER_CYCLE]

			if _breath_count >= BREATHS_PER_CYCLE:
				var step: Dictionary = STEP_DATA[_current_step]
				if step.type == StepType.BREATH:
					_on_step_ok()
				elif step.type == StepType.CYCLE:
					_cycle_count += 1
					if _cycle_count >= step.target:
						ScoreManager.record_minigame_step(true)
						_on_step_ok()
					else:
						_cycle_phase = CyclePhase.COMPRESSIONS
						_compression_count = 0
						_breath_count = 0
						_breath_substep = 0
						_ring_progress = 0.0
						progress_bar.visible = true
						progress_bar.max_value = COMPRESSIONS_PER_CYCLE
						progress_bar.value = 0
						rhythm_ring.visible = true
						breath_prompt.visible = false
						instruction_label.text = "30 compresiones - Ciclo %d/%d" % [_cycle_count + 1, TOTAL_CYCLES]
						help_label.text = "Presioná [Q] al ritmo del anillo."
						feedback_label.text = ""
				else:
					_on_step_ok()
			else:
				_breath_substep = 0
				_update_breath_prompt()


func _update_dial_label() -> void:
	var step: Dictionary = STEP_DATA[_current_step]
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


func _advance_step() -> void:
	_current_step += 1
	if _current_step >= STEP_DATA.size():
		feedback_label.modulate = MiniGameTheme.FEEDBACK_GOOD
		feedback_label.text = "✓ RCP exitosa. Ritmo restaurado."
		_state = "complete_delay"
		_state_timer = 2.0
		return

	if STEP_DATA[_current_step].type == StepType.CYCLE:
		_cycle_count = 0
		_cycle_phase = CyclePhase.COMPRESSIONS
		_compression_count = 0
		_breath_count = 0
		_ring_progress = 0.0
	elif STEP_DATA[_current_step].type == StepType.COMPRESS:
		_compression_count = 0
		_ring_progress = 0.0
	elif STEP_DATA[_current_step].type == StepType.BREATH:
		_breath_count = 0
		_breath_substep = 0
		_breath_substep_active = false

	_compression_timeout = 0.0
	_update_ui()


func _lose_life(msg: String) -> void:
	_lives -= 1
	ScoreManager.record_minigame_step(false)
	feedback_label.modulate = MiniGameTheme.FEEDBACK_BAD
	feedback_label.text = "✗ " + msg
	wrong_sound.play()

	_update_ecg_freq()
	patient_sprite.modulate = _get_patient_color()

	if _lives <= 0:
		fail_sound.play()
		feedback_label.text = "✗ EL PACIENTE HA FALLECIDO"
		Global.student_died = true
		EventBus.student_died.emit()
		_state = "death_delay"
		_state_timer = 2.5
		return

	_state = "step_fail_delay"
	_state_timer = 1.5


func _on_step_ok() -> void:
	var step: Dictionary = STEP_DATA[_current_step]
	feedback_label.modulate = MiniGameTheme.FEEDBACK_GOOD
	feedback_label.text = "✓ " + step.feedback_ok
	correct_sound.play()
	ScoreManager.record_minigame_step(true)
	_state = "step_ok_delay"
	_state_timer = 0.8


func _on_before_end(success: bool) -> void:
	ScoreManager.record_minigame_result("cpr", success, _lives, _time_remaining)
	if success:
		JournalManager.add_system_entry("RCP completada", "Se completaron 3 ciclos de RCP correctamente.")
	else:
		JournalManager.add_system_entry("RCP fallida", "No se pudo reanimar al paciente.")


func _on_rhythm_ring_draw() -> void:
	if not rhythm_ring:
		return
	var center = rhythm_ring.size / 2
	var radius = min(rhythm_ring.size.x, rhythm_ring.size.y) * 0.4
	var phase = _ring_progress

	var green_start: float = 0.2 * TAU
	var green_end: float = 0.5 * TAU
	var yellow_start: float = 0.5 * TAU
	var yellow_end: float = 0.7 * TAU
	var red_start: float = 0.7 * TAU
	var red_end: float = 1.0 * TAU
	var blue_start: float = 0.0 * TAU
	var blue_end: float = 0.2 * TAU

	rhythm_ring.draw_arc(center, radius, blue_start, blue_end, 32, Color(0.2, 0.4, 0.8, 0.8), 4.0, true)
	rhythm_ring.draw_arc(center, radius, green_start, green_end, 32, Color(0.0, 0.8, 0.2, 0.9), 5.0, true)
	rhythm_ring.draw_arc(center, radius, yellow_start, yellow_end, 32, Color(1.0, 0.8, 0.0, 0.8), 4.0, true)
	rhythm_ring.draw_arc(center, radius, red_start, red_end, 32, Color(1.0, 0.2, 0.2, 0.6), 3.0, true)

	var angle: float = phase * TAU - PI / 2.0
	var tip: Vector2 = center + Vector2(cos(angle), sin(angle)) * radius
	rhythm_ring.draw_circle(tip, 6.0, Color.WHITE)

	var inner_radius: float = radius * 0.65
	rhythm_ring.draw_arc(center, inner_radius, 0, TAU, 32, Color(1, 1, 1, 0.15), 1.0, true)


func _on_ecg_draw() -> void:
	if not ecg_line:
		return
	var w = ecg_line.size.x
	var h = ecg_line.size.y
	var base_y = h / 2.0

	var color = Color(0.2, 1.0, 0.2)
	if _lives <= 3:
		color = Color(1.0, 0.8, 0.2)
	if _lives <= 1:
		color = Color(1.0, 0.2, 0.2)

	var amplitude = 20.0
	if _lives <= 1:
		amplitude = 5.0

	var points = PackedVector2Array()
	var step_px = max(2, int(w / 120))

	for x in range(0, int(w), step_px):
		var nx = float(x) / float(w)
		var y = base_y

		if _ecg_freq > 0.0:
			var t = nx * 8.0 - _ecg_time * _ecg_freq
			var phase = fmod(t, 1.0)

			if phase > 0.38 and phase < 0.42:
				var spike = sin((phase - 0.38) / 0.04 * PI)
				y += spike * amplitude * 1.5
			elif phase > 0.42 and phase < 0.48:
				var spike = sin((phase - 0.42) / 0.06 * PI)
				y -= spike * amplitude * 0.8
			elif phase > 0.7 and phase < 0.75:
				var spike = sin((phase - 0.7) / 0.05 * PI)
				y += spike * amplitude * 0.3
			else:
				var noise_val = sin(t * 2.0) * 0.5
				y += noise_val

		points.append(Vector2(x, y))

	if points.size() > 1:
		for i in range(points.size() - 1):
			ecg_line.draw_line(points[i], points[i + 1], color, 2.0, true)


func _exit_tree() -> void:
	var main_camera = get_viewport().get_camera_2d()
	if main_camera:
		main_camera.offset = Vector2.ZERO
