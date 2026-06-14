extends CanvasLayer

enum PhoneMode {HOME, MESSAGE, SCENARIO, LAUNCHING}
enum Mood {NORMAL, HAPPY, SAD, ANGRY, TALK}

const SCENARIO_TIMEOUT: float = 30.0

@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var face_anim: AnimationPlayer = $Phone/FacePlayer
@onready var status_label: Label = $Phone/Status
@onready var notification_sound: AudioStreamPlayer = $NotificationSound
@onready var slide_sound: AudioStreamPlayer = $SlideSound

var _mode: PhoneMode = PhoneMode.HOME
var _message_queue: Array[Dictionary] = []
var _scenario_timer: float = 0.0
var _dialog_active: bool = false
var _was_visible_before_dialog: bool = false
var _current_mood: Mood = Mood.TALK
var _pending_mood: int = -1
var _quest_log_panel: QuestLogPanel = null
var _journal_panel: JournalPanel = null
var _stats_panel: StatsPanel = null
var _hint_labels: Array[Label] = []
var _close_anim_done: bool = false
var _closing: bool = false
var _saved_camera_zoom: Vector2 = Vector2.ONE
var _camera_zoom_modified: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	$Phone.position = Vector2(948, 800)
	visible = false
	face_anim.play("talk")
	EventBus.scene_changing.connect(_on_scene_changing)
	EventBus.scene_changed.connect(_on_scene_loaded)
	EventBus.minigame_completed.connect(_on_minigame_completed)
	SceneManager.game_paused.connect(_on_game_paused)
	EventBus.dialog_started.connect(_on_dialog_started)
	EventBus.dialog_finished.connect(_on_dialog_finished)
	EventBus.quest_started.connect(_on_quest_event)
	EventBus.objective_advanced.connect(_on_quest_event)
	EventBus.quest_completed.connect(_on_quest_event)
	EventBus.journal_entry_added.connect(_on_journal_entry_added)

	_add_hint_label(18, 220, "[J] Bit\u00e1cora")
	_add_hint_label(18, 248, "[K] Stats")


func _on_scene_loaded(_scene_path: String) -> void:
	if _pending_mood >= 0:
		set_mood(_pending_mood as Mood)
		_pending_mood = -1
	else:
		set_mood(Mood.TALK)


func _add_hint_label(x: int, y: int, text: String) -> void:
	var lbl := Label.new()
	lbl.position = Vector2(x, y)
	lbl.text = text
	lbl.add_theme_font_override("font", load("res://src/shared/fonts/coolvetica/Coolvetica Rg.otf") as Font)
	lbl.add_theme_font_size_override("font_size", 9)
	lbl.add_theme_color_override("font_color", Color(0.227451, 0.886275, 0.886275, 1))
	_hint_labels.append(lbl)
	$Phone.add_child(lbl)


func open_journal() -> void:
	if _journal_panel != null and is_instance_valid(_journal_panel):
		return
	_journal_panel = JournalPanel.new()
	_journal_panel.closed.connect(_on_journal_closed)
	get_tree().current_scene.add_child(_journal_panel)


func _on_journal_closed() -> void:
	_journal_panel = null


func open_stats() -> void:
	if _stats_panel != null and is_instance_valid(_stats_panel):
		return
	_stats_panel = StatsPanel.new()
	_stats_panel.closed.connect(_on_stats_closed)
	get_tree().current_scene.add_child(_stats_panel)


func _on_stats_closed() -> void:
	_stats_panel = null


func _on_journal_entry_added(_entry: Resource) -> void:
	if visible and _mode == PhoneMode.HOME:
		_update_status_label()


func _process(delta: float) -> void:
	if _mode == PhoneMode.SCENARIO and not _dialog_active:
		_scenario_timer -= delta
		if _scenario_timer <= 0:
			_dismiss_message()
	for lbl in _hint_labels:
		lbl.visible = (_mode == PhoneMode.HOME)


func _unhandled_input(event: InputEvent) -> void:
	if _mode == PhoneMode.LAUNCHING:
		return
	if _dialog_active:
		return
	if get_tree().current_scene is MainMenu:
		return
	if get_tree().paused:
		return

	if event.is_action_pressed("open_journal"):
		if visible and _mode == PhoneMode.HOME:
			open_journal()
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("open_stats"):
		if visible and _mode == PhoneMode.HOME:
			open_stats()
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("quest_log"):
		if _quest_log_panel != null and is_instance_valid(_quest_log_panel):
			_close_quest_log()
		else:
			_open_quest_log()
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("Phone"):
		match _mode:
			PhoneMode.SCENARIO:
				_launch_scenario()
			PhoneMode.MESSAGE:
				if visible:
					_dismiss_message()
				else:
					open_phone()
			PhoneMode.HOME:
				toggle_phone()


# ─── Public API ────────────────────────────────────────

func set_mood(mood: Mood) -> void:
	_current_mood = mood
	face_anim.play(Mood.keys()[mood].to_lower())


func push_notification(title: String, body: String, sound: bool = false, scenario_id: String = "") -> void:
	if scenario_id != "":
		for msg in _message_queue:
			if msg.get("scenario_id") == scenario_id:
				return
	var msg: Dictionary = {
		"title": title,
		"body": body,
		"sound": sound,
		"scenario_id": scenario_id,
	}
	_message_queue.append(msg)
	if _mode == PhoneMode.HOME:
		_show_next_message()


func reset() -> void:
	if _quest_log_panel != null and is_instance_valid(_quest_log_panel):
		_quest_log_panel.queue_free()
	_quest_log_panel = null
	if _journal_panel != null and is_instance_valid(_journal_panel):
		_journal_panel.queue_free()
	_journal_panel = null
	if _stats_panel != null and is_instance_valid(_stats_panel):
		_stats_panel.queue_free()
	_stats_panel = null
	_mode = PhoneMode.HOME
	_message_queue.clear()
	_scenario_timer = 0.0
	visible = false
	status_label.text = ""
	anim.stop()


func has_pending_scenario() -> bool:
	return _mode == PhoneMode.SCENARIO


func cancel_scenario() -> void:
	if _mode == PhoneMode.SCENARIO:
		_dismiss_message()


# ─── Internal ──────────────────────────────────────────

func _show_next_message() -> void:
	if _message_queue.is_empty():
		_mode = PhoneMode.HOME
		_update_status_label()
		if not visible:
			return
		open_phone()
		return

	var msg: Dictionary = _message_queue[0]
	var is_scenario: bool = msg.get("scenario_id", "") != ""

	_mode = PhoneMode.SCENARIO if is_scenario else PhoneMode.MESSAGE
	if is_scenario:
		_scenario_timer = SCENARIO_TIMEOUT

	status_label.text = msg.title + "\n" + msg.body

	if msg.get("sound", false):
		notification_sound.play()

	if not visible:
		open_phone()


func _dismiss_message() -> void:
	if _message_queue.is_empty():
		return
	_message_queue.pop_front()
	_scenario_timer = 0.0
	if _message_queue.is_empty():
		_mode = PhoneMode.HOME
		set_mood(Mood.TALK)
		close_phone()
	else:
		_show_next_message()


func _on_scene_changing(_scene_path: String) -> void:
	set_process_input(true)
	set_process_unhandled_input(true)
	reset()


func _on_game_paused(paused: bool) -> void:
	if not paused:
		return
	_hide_for_pause()


func _hide_for_pause() -> void:
	if _mode == PhoneMode.MESSAGE or _mode == PhoneMode.SCENARIO:
		_message_queue.clear()
		_scenario_timer = 0.0
		_mode = PhoneMode.HOME
	if visible:
		visible = false
		_closing = false


func _on_minigame_completed(game_id: String, success: bool) -> void:
	if not MiniGameManager.has_scenario(game_id):
		return
	if _camera_zoom_modified:
		var player := get_tree().current_scene.find_child("Player", true, false) as Player
		if player:
			var cam := player.get_node("Camera2D") as Camera2D
			if cam:
				var zoom_tween := create_tween().set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
				zoom_tween.tween_property(cam, "zoom", _saved_camera_zoom, 0.6)
		_camera_zoom_modified = false

	var text := _get_minigame_completion_text(game_id, success)
	var mood := _get_minigame_completion_mood(game_id, success)
	push_notification("PIXEL v1.0", text, false, "")
	set_mood(mood)
	_pending_mood = mood


func _get_minigame_completion_text(game_id: String, success: bool) -> String:
	var save_hint := "\n[ESC] Guardar partida"
	match game_id:
		"trivia":
			var outcome := String(Global.last_minigame_outcome.get("result", ""))
			match outcome:
				"win":
					return "¡Ganaste la trivia!%s" % save_hint
				"loss":
					return "Perdiste la trivia.%s" % save_hint
				"tie":
					return "Empataste con Enrique.\nHabla con el profesor para el desempate.%s" % save_hint
			return (
				"¡Ganaste la trivia!%s" % save_hint if success
				else "Perdiste la trivia.%s" % save_hint
			)
		"wordle":
			return (
				"¡Ganaste el Wordle!\nDesempate a tu favor.%s" % save_hint if success
				else "Perdiste el Wordle.\nPuedes volver a intentarlo.%s" % save_hint
			)
		"fainting_first_aid":
			return (
				"Emergencia resuelta.\nEstudiante estabilizado.%s" % save_hint if success
				else "Falleció el estudiante.%s" % save_hint
			)
		"cpr":
			return (
				"RCP completada.\nPaciente reanimado.%s" % save_hint if success
				else "RCP fallida.\nPaciente fallecido.%s" % save_hint
			)
		_:
			return (
				"Minijuego completado.%s" % save_hint if success
				else "Minijuego fallido.%s" % save_hint
			)


func _get_minigame_completion_mood(game_id: String, success: bool) -> Mood:
	if game_id == "trivia" and Global.last_minigame_outcome.get("result") == "tie":
		return Mood.TALK
	return Mood.HAPPY if success else Mood.SAD


func _on_dialog_started() -> void:
	_dialog_active = true
	_was_visible_before_dialog = visible
	if visible:
		close_phone()


func _on_dialog_finished() -> void:
	_dialog_active = false
	if _was_visible_before_dialog or not _message_queue.is_empty():
		_was_visible_before_dialog = false
		open_phone()
	else:
		_was_visible_before_dialog = false


func _launch_scenario() -> void:
	if _message_queue.is_empty():
		return
	var msg: Dictionary = _message_queue[0]
	var sid: String = msg.get("scenario_id", "")
	if sid == "" or not MiniGameManager.has_scenario(sid):
		return
	var scenario: Dictionary = MiniGameManager.get_scenario(sid)
	_message_queue.pop_front()
	_scenario_timer = 0.0
	_mode = PhoneMode.LAUNCHING
	visible = false
	
	var player := get_tree().current_scene.find_child("Player", true, false) as Player
	if player:
		var cam := player.get_node("Camera2D") as Camera2D
		if cam:
			_saved_camera_zoom = cam.zoom
	
	var bg_img: Image = null
	if Global.fainting_approach_pos != Vector2.ZERO:
		if player:
			var wp = get_tree().current_scene.find_child("PatientInWorld", true, false) as Sprite2D
			if wp:
				wp.modulate = Color.WHITE
				wp.visible = true
				await player.walk_to(Global.fainting_approach_pos)
			bg_img = get_viewport().get_texture().get_image()
			var cam := player.get_node("Camera2D") as Camera2D
			if cam:
				_camera_zoom_modified = true
				var zoom_tween := create_tween().set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
				zoom_tween.tween_property(cam, "zoom", _saved_camera_zoom * 2.0, 0.6)
				await zoom_tween.finished
		Global.fainting_approach_pos = Vector2.ZERO
	if scenario.get("cinematic", false):
		await _play_fainting_cinematic()
		
	_mode = PhoneMode.HOME
	reset()
	MiniGameManager.launch_minigame(scenario.path, scenario.id, bg_img)

func _play_fainting_cinematic() -> void:
	await SceneManager.play_wipe()


func _update_status_label() -> void:
	var active_count := QuestManager.active_quests.size()
	var lines := "PIXEL v1.0"
	if active_count > 0:
		lines += "\nMisiones: " + str(active_count) + " activas"
	var stats := ScoreManager.get_stats()
	if stats.score > 0:
		lines += "\nPts: %d [%s]" % [stats.score, stats.grade]
	status_label.text = lines

func _on_quest_event(_a: String = "", _b: String = "", _c: String = "") -> void:
	if _quest_log_panel != null and is_instance_valid(_quest_log_panel):
		_quest_log_panel.populate(QuestManager.active_quests, QuestManager.completed_quests)
	if visible and _mode == PhoneMode.HOME:
		_update_status_label()


# ─── Phone UI ──────────────────────────────────────────

func toggle_phone() -> void:
	if visible:
		close_phone()
	else:
		open_phone()


func open_phone() -> void:
	visible = true
	anim.play("slide_in")
	slide_sound.play()
	if _mode == PhoneMode.HOME:
		_update_status_label()


func close_phone() -> void:
	if not visible or _closing:
		return
	_closing = true
	anim.play("slide_out")
	slide_sound.play()
	_close_anim_done = false
	anim.animation_finished.connect(_on_close_anim_finished, CONNECT_ONE_SHOT)
	await get_tree().create_timer(1.0).timeout
	if not _close_anim_done:
		push_warning("close_phone: slide_out animation timed out")
	visible = false
	_closing = false

func _on_close_anim_finished(_anim_name: String) -> void:
	_close_anim_done = true

func _open_quest_log() -> void:
	if _quest_log_panel == null or not is_instance_valid(_quest_log_panel):
		_quest_log_panel = QuestLogPanel.new()
		_quest_log_panel.closed.connect(_on_quest_log_closed)
		get_tree().current_scene.add_child(_quest_log_panel)
	_quest_log_panel.populate(QuestManager.active_quests, QuestManager.completed_quests)

func _close_quest_log() -> void:
	if _quest_log_panel != null and is_instance_valid(_quest_log_panel):
		_quest_log_panel.close()
		await _quest_log_panel.closed
	_quest_log_panel = null

func _on_quest_log_closed() -> void:
	_quest_log_panel = null
