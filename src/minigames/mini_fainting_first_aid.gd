extends MiniGameBase
class_name MiniFaintingFirstAid

enum StepType { HOLD_CHECK_RESPONSE, HOLD_CHECK_BREATHING, TIMED_PRESS, DIAL_112, HOLD_ELEVATE, TAP, ECG }

const CURACION_HFRAMES = 4
const CURACION_VFRAMES = 2

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
		"type": StepType.HOLD_CHECK_RESPONSE,
		"target": 1.5,
		"feedback_ok": "¡Bien! Verificaste si responde.",
		"feedback_fail": "Tenés que verificar si responde primero.",
	},
	{
		"instruction": "No responde. ¿Qué hacés ahora?",
		"help": "Paso 2: Verificar respiración.\nObservá su pecho.\n[Q] Mantené 3 segundos.",
		"type": StepType.HOLD_CHECK_BREATHING,
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

const TIME_LIMIT: float = 60.0

var _current_step: int = 0
var _lives: int = 3
var _time_remaining: float

var _state: String = "playing"
var _state_timer: float = 0.0

var ui: FaintingUIController
var visual: FaintingVisualController
var input: FaintingInputController

@onready var bgm_player: AudioStreamPlayer = $BgmPlayer
@onready var heartbeat_player: AudioStreamPlayer = $HeartbeatPlayer

func _ready() -> void:
	super()
	_time_remaining = TIME_LIMIT
	
	visual = FaintingVisualController.new()
	add_child(visual)
	visual.setup(self)
	
	ui = FaintingUIController.new()
	add_child(ui)
	ui.setup(self)
	
	input = FaintingInputController.new()
	add_child(input)
	input.setup(self, visual)
	
	input.step_completed.connect(_on_step_completed)
	input.step_failed.connect(_lose_life)
	input.progress_updated.connect(ui.update_progress)
	input.dial_updated.connect(ui.update_dial)
	input.action_state_changed.connect(func(state): visual.set_action_frame(_current_step, state))
	input.hold_decayed.connect(func(show: bool):
		if show:
			ui.show_feedback("¡Soltaste! Seguí manteniendo Q.", MiniGameTheme.FEEDBACK_BAD)
		else:
			ui.clear_feedback()
	)
	
	bgm_player.play(109.0)
	bgm_player.finished.connect(func(): bgm_player.play(109.0))
	heartbeat_player.play()
	heartbeat_player.finished.connect(func(): heartbeat_player.play())

	_reset_step()

func _reset_step() -> void:
	input.reset_step()
	_state = "playing"
	_state_timer = 0.0
	ui.update_ui(STEP_DATA[_current_step], _current_step, STEP_DATA.size(), _lives)
	ui.update_timer(_time_remaining)
	visual.update_patient_color(_lives)
	visual.toggle_indicators(STEP_DATA[_current_step].type)
	visual.set_action_frame(_current_step, "idle")

func _process(delta: float) -> void:
	if not _is_running: return
	
	_time_remaining -= delta
	ui.update_timer(_time_remaining)
	
	if _state == "step_ok_delay":
		_state_timer -= delta
		if _state_timer <= 0:
			_state = "playing"
			ui.clear_feedback()
			var s = get_node_or_null("StepSound")
			if s: s.play()
			_advance_step()
		return
	elif _state == "step_fail_delay":
		_state_timer -= delta
		if _state_timer <= 0:
			_state = "playing"
			ui.clear_feedback()
			ui.update_ui(STEP_DATA[_current_step], _current_step, STEP_DATA.size(), _lives)
		return
	elif _state == "death_delay":
		_state_timer -= delta
		if _state_timer <= 0:
			_state = "playing"
			end(false)
		return
	elif _state == "complete_delay":
		_state_timer -= delta
		if _state_timer <= 0:
			_state = "playing"
			end(true)
		return

	if _time_remaining <= 0:
		_time_remaining = 0
		_lives = 1
		_lose_life("¡Se acabó el tiempo!")
		return

	input.process_frame(delta, STEP_DATA[_current_step])

func _input(event: InputEvent) -> void:
	if not _is_running: return
	if event.is_action_pressed("Phone"):
		get_viewport().set_input_as_handled()
	if _state != "playing": return
	input.process_input(event, STEP_DATA[_current_step])

func _on_step_completed() -> void:
	var step = STEP_DATA[_current_step]
	ui.show_feedback("✓ " + step.feedback_ok, MiniGameTheme.FEEDBACK_GOOD)
	var s = get_node_or_null("CorrectSound")
	if s: s.play()
	ScoreManager.record_minigame_step(true)
	JournalManager.add_minigame_entry("Paso %d superado" % (_current_step + 1), step.feedback_ok)
	visual.set_action_frame(_current_step, "idle")
	_state = "step_ok_delay"
	_state_timer = 0.8

func _advance_step() -> void:
	_current_step += 1
	if _current_step >= STEP_DATA.size():
		ui.show_feedback("✓ ¡Completaste los primeros auxilios!", MiniGameTheme.FEEDBACK_GOOD)
		var s = get_node_or_null("SuccessFanfare")
		if s: s.play()
		_state = "complete_delay"
		_state_timer = 2.0
		return
	_reset_step()

func _lose_life(msg: String) -> void:
	_lives -= 1
	ui.show_feedback("✗ " + msg, MiniGameTheme.FEEDBACK_BAD)
	var wrong = get_node_or_null("WrongSound")
	if wrong: wrong.play()
	ScoreManager.record_minigame_step(false)
	JournalManager.add_minigame_entry("Error en paso %d" % (_current_step + 1), msg)
	visual.trigger_shake()
	visual.update_patient_color(_lives)
	
	if _lives <= 0:
		var fail = get_node_or_null("FailSound")
		if fail: fail.play()
		ui.show_feedback("✗ EL ESTUDIANTE HA FALLECIDO", MiniGameTheme.FEEDBACK_BAD)
		if visual.action_sprite: visual.action_sprite.frame = 7
		Global.student_died = true
		EventBus.student_died.emit()
		_state = "death_delay"
		_state_timer = 2.5
		JournalManager.add_system_entry("Estudiante fallecido", "No se pudieron completar los primeros auxilios a tiempo.")
		return
	
	_state = "step_fail_delay"
	_state_timer = 1.5

func end(success: bool) -> void:
	if not _is_running: return
	_is_running = false
	visual.cleanup(success)
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
