extends MiniGameBase
class_name MiniFaintingFirstAid

enum StepType { HOLD_3, TIMED_PRESS, DIAL_112, HOLD_ELEVATE, TAP, ECG }

const KEYCAP_NORMAL = preload("res://src/assets/sprites/keycap_q.svg")
const KEYCAP_PRESSED = preload("res://src/assets/sprites/keycap_q_pressed.svg")

const PATIENT = preload("res://src/assets/sprites/patient_lying.png")
const CURACION = preload("res://src/assets/sprites/curacion.png")
const CURACION_HFRAMES = 4
const CURACION_VFRAMES = 2
const PLAYER_ACTION_POS = Vector2(732.0, 620.0)

const STEP_ACTION_FRAMES: Array[Dictionary] = [
	{ "idle": 4, "action": 5 },  # 1: Verificar respuesta
	{ "idle": 4, "action": 6 },  # 2: Verificar respiración
	{ "idle": 4, "action": 5 },  # 3: Pulso carotídeo
	{ "idle": 7, "action": 7 },  # 4: Llamar 112
	{ "idle": 4, "action": 5 },  # 5: Elevar piernas
	{ "idle": 4, "action": 6 },  # 6: Aflojar ropa
	{ "idle": 4, "action": 5 },  # 7: Monitorear ECG
]

const STEP_DATA: Array[Dictionary] = [
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
		"instruction": "Palpá el pulso carotídeo",
		"help": "Esperá el indicador → Presioná Q cuando parpadee",
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
@onready var dial_label: Label = $GameContainer/DialLabel

var patient_sprite: Sprite2D

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
var _pulse_prompt: Label

var _state: String = "playing"
var _state_timer: float = 0.0

var _keycap_rect: TextureRect
var _hearts_box: HBoxContainer
var _ecg_line: Control

var _shake_timer: float = 0.0
var _action_sprite: Sprite2D
var _real_player: Player
var _minigame_success: bool = false

func _ready() -> void:
	super()
	_time_remaining = TIME_LIMIT
	progress_bar.visible = false
	_shake_timer = 0.5

	# Apply CRT Shader
	var mat = ShaderMaterial.new()
	mat.shader = preload("res://src/minigames/retro_crt.gdshader")
	mat.set_shader_parameter("vignette_intensity", 0.4)
	mat.set_shader_parameter("vignette_opacity", 0.8)
	mat.set_shader_parameter("vignette_color", Color.BLACK)
	background.material = mat

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
	_keycap_rect = TextureRect.new()
	_keycap_rect.texture = load("res://src/assets/sprites/keycap_q.svg")
	_keycap_rect.set_anchors_preset(Control.PRESET_CENTER)
	_keycap_rect.offset_left = -320
	_keycap_rect.offset_top = 50
	_keycap_rect.offset_right = -288
	_keycap_rect.offset_bottom = 82
	_keycap_rect.visible = false
	game_container.add_child(_keycap_rect)
	
	# Progress bar reposition
	progress_bar.set_anchors_preset(Control.PRESET_CENTER)
	progress_bar.offset_left = -270
	progress_bar.offset_top = 50
	progress_bar.offset_bottom = 82

	# Hide the world patient and create a temp copy for the minigame
	var world = get_tree().current_scene
	var world_patient = world.find_child("PatientInWorld", true, false) as Sprite2D if world else null
	if world_patient:
		world_patient.visible = false
		patient_sprite = Sprite2D.new()
		patient_sprite.texture = PATIENT
		patient_sprite.centered = false
		patient_sprite.global_position = world_patient.global_position
		patient_sprite.scale = world_patient.scale
		world.add_child(patient_sprite)
	else:
		patient_sprite = null

	# Hide the real player and create action sprite in the world
	_real_player = get_tree().current_scene.find_child("Player", true, false) as Player
	if _real_player and is_instance_valid(_real_player):
		var real_sprite = _real_player.get_node("Sprite2D")
		if real_sprite:
			real_sprite.visible = false
	if world:
		_action_sprite = Sprite2D.new()
		_action_sprite.texture = CURACION
		_action_sprite.hframes = CURACION_HFRAMES
		_action_sprite.vframes = CURACION_VFRAMES
		_action_sprite.frame = 7
		_action_sprite.centered = true
		_action_sprite.scale = Vector2(1.25, 1.25)
		world.add_child(_action_sprite)
		_action_sprite.global_position = PLAYER_ACTION_POS
		var kneel_tween = create_tween().set_trans(Tween.TRANS_QUINT)
		kneel_tween.tween_property(_action_sprite, "frame", float(STEP_ACTION_FRAMES[0].idle), 0.4)

	# Hearts Box
	hearts_label.visible = false
	_hearts_box = HBoxContainer.new()
	_hearts_box.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_hearts_box.offset_left = -150
	_hearts_box.offset_top = 15
	_hearts_box.offset_right = -30
	_hearts_box.offset_bottom = 47
	_hearts_box.alignment = BoxContainer.ALIGNMENT_END
	game_container.add_child(_hearts_box)
	for i in range(3):
		var heart_rect = TextureRect.new()
		heart_rect.texture = load("res://src/assets/sprites/heart_pixel.svg")
		heart_rect.custom_minimum_size = Vector2(32, 32)
		heart_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		heart_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_hearts_box.add_child(heart_rect)

	# ECG Line Control
	_ecg_line = Control.new()
	_ecg_line.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ecg_line.offset_left = 0
	_ecg_line.offset_top = 0
	_ecg_line.offset_right = 0
	_ecg_line.offset_bottom = 0
	_ecg_line.draw.connect(_on_ecg_draw)
	game_container.add_child(_ecg_line)

	# Audio Setup
	var bgm_player = AudioStreamPlayer.new()
	bgm_player.stream = load("res://src/assets/sounds/Waiting_For_The_Lock.mp3")
	bgm_player.volume_db = -8.0
	game_container.add_child(bgm_player)
	bgm_player.play(109.0) # Start from 1:49
	bgm_player.finished.connect(func(): bgm_player.play(109.0))
	
	var heart_player = AudioStreamPlayer.new()
	heart_player.stream = load("res://src/assets/sounds/freesound_community-corazon-66362.mp3")
	heart_player.volume_db = 0.0
	game_container.add_child(heart_player)
	heart_player.play()
	heart_player.finished.connect(func(): heart_player.play())

	# Custom style for PulsePoint (pulsing carotid target ring)
	var pulse = get_node_or_null("GameContainer/PulsePoint")
	if pulse:
		pulse.custom_minimum_size = Vector2(48, 48)
		pulse.size = Vector2(48, 48)
		pulse.position = Vector2(326, 426)
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.0, 0.75, 1.0, 0.25) # Semi-transparent Cyan
		style.border_width_left = 4
		style.border_width_top = 4
		style.border_width_right = 4
		style.border_width_bottom = 4
		style.border_color = Color(0.0, 0.9, 1.0, 1.0) # Glowing Bright Cyan border
		style.corner_radius_top_left = 24
		style.corner_radius_top_right = 24
		style.corner_radius_bottom_left = 24
		style.corner_radius_bottom_right = 24
		style.anti_aliasing = true
		style.anti_aliasing_size = 1.0
		pulse.add_theme_stylebox_override("panel", style)
		pulse.pivot_offset = Vector2(24, 24) # Centered for scale animations

	# Prompt label for Step 3 (pulse check)
	_pulse_prompt = Label.new()
	_pulse_prompt.add_theme_font_size_override("font_size", 18)
	_pulse_prompt.add_theme_color_override("font_color", Color(0.65, 0.1, 0.08, 1))
	_pulse_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_pulse_prompt.visible = false
	game_container.add_child(_pulse_prompt)

	# Set texture and pivot for HeartIcon (Step 7)
	var heart_icon_node = get_node_or_null("GameContainer/HeartIcon")
	if heart_icon_node:
		heart_icon_node.custom_minimum_size = Vector2(32, 32)
		heart_icon_node.size = Vector2(32, 32)
		heart_icon_node.position = Vector2(378, 458)
		heart_icon_node.texture = load("res://src/assets/sprites/heart_pixel.svg")
		heart_icon_node.pivot_offset = Vector2(16, 16) # Centered for scale animations

	_reset_step()

func _set_step_action_frame(frame_type: String = "idle") -> void:
	if not _action_sprite or not is_instance_valid(_action_sprite):
		return
	var frames: Dictionary = STEP_ACTION_FRAMES[_current_step]
	match frame_type:
		"idle":
			_action_sprite.frame = frames.idle
		"action":
			_action_sprite.frame = frames.action

func _shake_action_sprite() -> void:
	if not _action_sprite or not is_instance_valid(_action_sprite):
		return
	var orig_pos = _action_sprite.position
	var shake = create_tween().set_trans(Tween.TRANS_QUINT)
	shake.tween_property(_action_sprite, "position", orig_pos + Vector2(4, 0), 0.05)
	shake.tween_property(_action_sprite, "position", orig_pos + Vector2(-4, 0), 0.05)
	shake.tween_property(_action_sprite, "position", orig_pos + Vector2(2, 0), 0.05)
	shake.tween_property(_action_sprite, "position", orig_pos, 0.05)

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
	if _pulse_prompt:
		_pulse_prompt.text = ""
		_pulse_prompt.visible = false
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
	var colors = {3: Color.WHITE, 2: Color(1, 0.7, 0.7), 1: Color(1, 0.3, 0.3)}
	patient_sprite.modulate = colors.get(_lives, Color(0.5, 0.1, 0.1))

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

func _update_ui() -> void:
	var step: Dictionary = STEP_DATA[_current_step]
	instruction_label.text = step.instruction
	help_label.text = step.help.replace("[Q] ", "").replace("[Q]", "")
	step_label.text = "Paso %d/%d" % [_current_step + 1, STEP_DATA.size()]
	if _hearts_box:
		for i in range(_hearts_box.get_child_count()):
			var child = _hearts_box.get_child(i)
			if i < _lives:
				child.modulate.a = 1.0
			else:
				child.modulate.a = 0.2
	feedback_label.text = ""
	_hold_penalized = false
	progress_bar.visible = (step.type == StepType.HOLD_3 or step.type == StepType.HOLD_ELEVATE)
	if _keycap_rect:
		var needs_keycap = (step.type == StepType.HOLD_3 or step.type == StepType.HOLD_ELEVATE or step.type == StepType.TAP or step.type == StepType.TIMED_PRESS or step.type == StepType.ECG)
		_keycap_rect.visible = needs_keycap
	_update_timer_label()
	_update_patient_color()
	_update_dial_label()

	# Controlar visibilidad y estado de reposo de los puntos táctiles sobre el paciente
	var pulse = get_node_or_null("GameContainer/PulsePoint")
	if pulse:
		pulse.visible = (step.type == StepType.TIMED_PRESS)
		pulse.modulate.a = 0.2
		pulse.scale = Vector2(1.0, 1.0)
		
	var heart = get_node_or_null("GameContainer/HeartIcon")
	if heart:
		heart.visible = (step.type == StepType.ECG)
		heart.modulate.a = 0.15
		heart.scale = Vector2(1.0, 1.0)

	_set_step_action_frame("idle")

func end(success: bool) -> void:
	if not _is_running:
		return
	_is_running = false
	_minigame_success = success
	process_mode = PROCESS_MODE_INHERIT
	ScoreManager.record_minigame_result("fainting_first_aid", success, _lives, _time_remaining)
	if success:
		JournalManager.add_system_entry("Minijuego completado", "Se realizaron todos los pasos de primeros auxilios correctamente.")
	else:
		JournalManager.add_system_entry("Minijuego fallido", "No se pudieron completar los primeros auxilios.")

	if SceneManager and SceneManager.has_method("play_time_passage"):
		SceneManager.play_time_passage(1.5, func():
			show_end_screen(success)
		)
	else:
		show_end_screen(success)

func show_end_screen(success: bool) -> void:
	var screen := EndScreen.new()
	screen.setup(success)
	screen.continue_pressed.connect(_on_end_screen_continue.bind(success))
	add_child(screen)


func _on_end_screen_continue(success: bool) -> void:
	get_tree().paused = false
	if success:
		var wp = get_tree().current_scene.find_child("PatientInWorld", true, false) as Sprite2D
		if wp:
			var fade = create_tween().set_trans(Tween.TRANS_QUINT)
			fade.tween_property(wp, "modulate:a", 0.0, 0.6)
			hide()
			await fade.finished
			wp.visible = false
			wp.modulate.a = 1.0
	else:
		hide()
	game_completed.emit(game_id, success)

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
	if _hearts_box:
		for i in range(_hearts_box.get_child_count()):
			var child = _hearts_box.get_child(i)
			if i < _lives:
				child.modulate.a = 1.0
			else:
				child.modulate.a = 0.2
	feedback_label.modulate = Color.RED
	feedback_label.text = "✗ " + msg
	var wrong: AudioStreamPlayer = get_node_or_null("WrongSound")
	if wrong:
		wrong.play()
	ScoreManager.record_minigame_step(false)
	JournalManager.add_minigame_entry(
		"Error en paso %d" % (_current_step + 1),
		msg
	)
	_shake_action_sprite()
	if _lives <= 0:
		var fail: AudioStreamPlayer = get_node_or_null("FailSound")
		if fail: fail.play()
		feedback_label.text = "✗ EL ESTUDIANTE HA FALLECIDO"
		if _action_sprite and is_instance_valid(_action_sprite):
			_action_sprite.frame = 7
		Global.student_died = true
		_state = "death_delay"
		_state_timer = 2.5
		JournalManager.add_system_entry("Estudiante fallecido", "No se pudieron completar los primeros auxilios a tiempo.")
		return
	_state = "step_fail_delay"
	_state_timer = 1.5

func _on_step_ok() -> void:
	var step: Dictionary = STEP_DATA[_current_step]
	feedback_label.modulate = Color.GREEN
	feedback_label.text = "✓ " + step.feedback_ok
	var correct: AudioStreamPlayer = get_node_or_null("CorrectSound")
	if correct:
		correct.play()
	ScoreManager.record_minigame_step(true)
	JournalManager.add_minigame_entry(
		"Paso %d superado" % (_current_step + 1),
		step.feedback_ok
	)
	_set_step_action_frame("idle")
	_state = "step_ok_delay"
	_state_timer = 0.8

var _ecg_time: float = 0.0

func _process(delta: float) -> void:
	if not _is_running:
		return

	var trauma: float = 0.0
	if _shake_timer > 0:
		_shake_timer -= delta
		trauma = (_shake_timer / 0.5) * 15.0
	
	var main_camera: Camera2D = get_viewport().get_camera_2d()
	if main_camera:
		var time: float = Time.get_ticks_msec() / 1000.0
		var wobble_x = sin(time * 2.5) * 1.5 + cos(time * 1.7) * 2.0
		var wobble_y = cos(time * 3.1) * 1.5 + sin(time * 1.3) * 2.0
		main_camera.offset = Vector2(wobble_x, wobble_y) + Vector2(randf_range(-trauma, trauma), randf_range(-trauma, trauma))

	_ecg_time += delta
	if _ecg_line:
		_ecg_line.queue_redraw()

	if Input.is_action_pressed("Phone"):
		if _keycap_rect and _keycap_rect.texture != KEYCAP_PRESSED:
			_keycap_rect.texture = KEYCAP_PRESSED
	else:
		if _keycap_rect and _keycap_rect.texture != KEYCAP_NORMAL:
			_keycap_rect.texture = KEYCAP_NORMAL

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
	var step: Dictionary = STEP_DATA[_current_step]
	match step.type:
		StepType.HOLD_3, StepType.HOLD_ELEVATE:
			_handle_hold(delta, step)
		StepType.TIMED_PRESS:
			_handle_timed_press(delta, step)
		StepType.ECG:
			_handle_ecg(delta, step)
		StepType.TAP:
			_handle_tap(delta, step)

	# Alinear dinámicamente los indicadores sobre el cuerpo del paciente en la pantalla
	if patient_sprite and is_instance_valid(patient_sprite) and patient_sprite.texture:
		var texture_size = patient_sprite.texture.get_size()
		
		var pulse = get_node_or_null("GameContainer/PulsePoint")
		if pulse and pulse.visible:
			var local_pos_pulse = Vector2(23.6, 33.2) - (texture_size / 2.0)
			var screen_pos_pulse = patient_sprite.get_global_transform_with_canvas() * local_pos_pulse
			pulse.position = screen_pos_pulse - pulse.size / 2.0
			if _pulse_prompt:
				_pulse_prompt.position = screen_pos_pulse + Vector2(-60, 40)
				_pulse_prompt.visible = _pulse_prompt.text != ""
		elif _pulse_prompt:
			_pulse_prompt.visible = false
			
		var heart = get_node_or_null("GameContainer/HeartIcon")
		if heart and heart.visible:
			var local_pos_heart = Vector2(41.2, 42.8) - (texture_size / 2.0)
			var screen_pos_heart = patient_sprite.get_global_transform_with_canvas() * local_pos_heart
			heart.position = screen_pos_heart - heart.size / 2.0


func _input(event: InputEvent) -> void:
	if not _is_running:
		return
	if event.is_action_pressed("Phone"):
		get_viewport().set_input_as_handled()
	if _state != "playing":
		return
	var step: Dictionary = STEP_DATA[_current_step]
	match step.type:
		StepType.TAP:
			if event.is_action_pressed("Phone"):
				_tap_timeout = 0.0
				_sub_progress += 1
				_set_step_action_frame("action")
				if _sub_progress >= step.target:
					_on_step_ok()
				else:
					var correct: AudioStreamPlayer = get_node_or_null("CorrectSound")
					if correct:
						correct.play()
		StepType.DIAL_112:
			if event is InputEventKey and event.pressed and not event.is_echo():
				var key: int = event.keycode
				var expected: int = step.target[_dial_index]
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
		# Animar frame según progreso
		if _action_sprite and is_instance_valid(_action_sprite):
			var frames: Dictionary = STEP_ACTION_FRAMES[_current_step]
			_action_sprite.frame = frames.action if progress_bar.value > 50.0 else frames.idle
		if _hold_timer >= step.target:
			_on_step_ok()
	else:
		if _hold_timer > 0.15 and not _hold_penalized:
			_hold_penalized = true
			_lose_life("¡Soltaste! Tenés que mantener Q presionado.")
		_hold_timer = max(0, _hold_timer - delta * 0.5)
		progress_bar.value = clamp(_hold_timer / step.target * 100.0, 0.0, 100.0)
		if _hold_timer > 0:
			_set_step_action_frame("idle")
			feedback_label.modulate = Color.RED
			feedback_label.text = "¡Soltaste! Seguí manteniendo Q."
		else:
			feedback_label.text = ""

func _handle_timed_press(delta: float, _step: Dictionary) -> void:
	_pulse_window += delta
	if _pulse_window < 2.0 and not _pulse_active and not _pulse_skipped:
		if _pulse_prompt:
			_pulse_prompt.text = "Preparate para palpar el pulso..."
	elif _pulse_window >= 2.0 and not _pulse_active and not _pulse_skipped:
		_pulse_active = true
		_pulse_window = 0.0
		if _pulse_prompt:
			_pulse_prompt.text = "¡PRESIONÁ Q AHORA!"
		_set_step_action_frame("action")
		var pulse = get_node_or_null("GameContainer/PulsePoint")
		if pulse:
			if _pulse_tween:
				_pulse_tween.kill()
			_pulse_tween = create_tween().set_parallel(true)
			
			# First beat: quick expansion and bright fade in from resting state (1.0 scale, 0.2 alpha)
			_pulse_tween.tween_property(pulse, "modulate:a", 1.0, 0.15)
			_pulse_tween.tween_property(pulse, "scale", Vector2(1.25, 1.25), 0.15)
			
			# Contraction
			var chain1 = _pulse_tween.chain().set_parallel(true)
			chain1.tween_property(pulse, "modulate:a", 0.4, 0.15)
			chain1.tween_property(pulse, "scale", Vector2(0.9, 0.9), 0.15)
			
			# Second beat: surge
			var chain2 = chain1.chain().set_parallel(true)
			chain2.tween_property(pulse, "modulate:a", 1.0, 0.15)
			chain2.tween_property(pulse, "scale", Vector2(1.4, 1.4), 0.15)
			
			# Return to resting state (1.0 scale, 0.2 alpha)
			var chain3 = chain2.chain().set_parallel(true)
			chain3.tween_property(pulse, "modulate:a", 0.2, 0.55)
			chain3.tween_property(pulse, "scale", Vector2(1.0, 1.0), 0.55)
			
			# End callback
			chain3.chain().tween_callback(func():
				if _pulse_active:
					_pulse_active = false
					_pulse_skipped = true
					if _pulse_prompt:
						_pulse_prompt.text = ""
					_lose_life("¡Te saltaste el pulso carotídeo! Es obligatorio.")
				_retry_timed_press()
				_pulse_tween = null
			)
	elif _pulse_active:
		if _pulse_window > 1.5:
			_pulse_active = false
			_pulse_skipped = true
			if _pulse_prompt:
				_pulse_prompt.text = ""
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
				heart.scale = Vector2(1.0, 1.0)
				heart.modulate.a = 0.15
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
	_set_step_action_frame("action")
	var heart = get_node_or_null("GameContainer/HeartIcon")
	if heart:
		if _ecg_tween:
			_ecg_tween.kill()
		_ecg_tween = create_tween().set_parallel(true)
		
		# First beat: quick expansion and bright fade in from resting state (1.0 scale, 0.15 alpha)
		_ecg_tween.tween_property(heart, "modulate:a", 1.0, 0.15)
		_ecg_tween.tween_property(heart, "scale", Vector2(1.2, 1.2), 0.15)
		
		# Contraction
		var chain1 = _ecg_tween.chain().set_parallel(true)
		chain1.tween_property(heart, "modulate:a", 0.4, 0.1)
		chain1.tween_property(heart, "scale", Vector2(0.95, 0.95), 0.1)
		
		# Second beat: surge
		var chain2 = chain1.chain().set_parallel(true)
		chain2.tween_property(heart, "modulate:a", 1.0, 0.15)
		chain2.tween_property(heart, "scale", Vector2(1.35, 1.35), 0.15)
		
		# Return to resting state (1.0 scale, 0.15 alpha)
		var chain3 = chain2.chain().set_parallel(true)
		chain3.tween_property(heart, "modulate:a", 0.15, 0.5)
		chain3.tween_property(heart, "scale", Vector2(1.0, 1.0), 0.5)
		
		chain3.chain().tween_callback(func():
			_ecg_tween = null
		)

func _on_ecg_draw() -> void:
	if not _ecg_line: return
	var points = PackedVector2Array()
	var w = _ecg_line.size.x
	var base_y = 90.0

	var freq = 1.0
	if _lives == 2: freq = 1.5
	elif _lives == 1: freq = 2.5
	elif _lives <= 0: freq = 0.0

	var color = Color(0.2, 1.0, 0.2)
	if _lives == 2: color = Color(1.0, 0.8, 0.2)
	elif _lives <= 1: color = Color(1.0, 0.2, 0.2)

	for x in range(0, int(w), 4):
		var nx = x / w
		var y = base_y
		if freq > 0.0:
			var phase = fmod(nx * 5.0 - _ecg_time * freq, 1.0)
			if phase > 0.4 and phase < 0.6:
				var spike = sin((phase - 0.4) * 5.0 * PI)
				y += spike * 30.0
		points.append(Vector2(x, y))

	if points.size() > 1:
		for i in range(points.size() - 1):
			_ecg_line.draw_line(points[i], points[i+1], color, 2.0, true)

func _exit_tree() -> void:
	# Restaurar sprite del player real
	if _real_player and is_instance_valid(_real_player):
		_real_player.z_index = 0
		var real_sprite = _real_player.get_node("Sprite2D")
		if real_sprite:
			real_sprite.visible = true
	# Limpiar sprite de acción
	if _action_sprite and is_instance_valid(_action_sprite):
		_action_sprite.queue_free()
	# Restaurar paciente del mundo
	var world = get_tree().current_scene
	if world:
		var wp = world.find_child("PatientInWorld", true, false) as Sprite2D
		if wp:
			wp.modulate = Color.WHITE
			if _minigame_success:
				wp.visible = false
			else:
				wp.visible = true
				wp.modulate = Color(0.5, 0.1, 0.1)
	# Eliminar paciente temporal del minijuego
	if patient_sprite and is_instance_valid(patient_sprite):
		patient_sprite.queue_free()
	var main_camera = get_viewport().get_camera_2d()
	if main_camera:
		main_camera.offset = Vector2.ZERO
