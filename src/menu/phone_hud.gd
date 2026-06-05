extends CanvasLayer

enum PhoneMode {HOME, MESSAGE, SCENARIO, LAUNCHING}
enum Mood {NORMAL, HAPPY, SAD, ANGRY, TALK}

const MINIGAME_PATH: String = "res://src/minigames/mini_fainting_first_aid.tscn"
const MINIGAME_ID: String = "fainting_first_aid"
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
var _quest_log_panel: QuestLogPanel = null
var _journal_panel: JournalPanel = null
var _stats_panel: StatsPanel = null
var _hint_labels: Array[Label] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	$Phone.position = Vector2(580, 650)
	visible = false
	face_anim.play("talk")
	EventBus.scene_changing.connect(_on_scene_changing)
	EventBus.scene_changed.connect(_on_scene_loaded)
	EventBus.minigame_completed.connect(_on_minigame_completed)
	EventBus.dialog_started.connect(_on_dialog_started)
	EventBus.dialog_finished.connect(_on_dialog_finished)
	EventBus.quest_started.connect(_on_quest_event)
	EventBus.objective_advanced.connect(_on_quest_event)
	EventBus.quest_completed.connect(_on_quest_event)
	EventBus.journal_entry_added.connect(_on_journal_entry_added)

	_add_hint_label(25, 215, "[J] Bit\u00e1cora")
	_add_hint_label(25, 240, "[K] Stats")


func _on_scene_loaded(_scene_path: String) -> void:
	if ScoreManager.student_saved:
		set_mood(Mood.HAPPY)
	elif ScoreManager.minigame_attempts > 0 and not ScoreManager.student_saved:
		set_mood(Mood.SAD)
	else:
		set_mood(Mood.TALK)


func _add_hint_label(x: int, y: int, text: String) -> void:
	var lbl := Label.new()
	lbl.position = Vector2(x, y)
	lbl.text = text
	lbl.add_theme_font_override("font", load("res://src/fonts/coolvetica/Coolvetica Rg.otf") as Font)
	lbl.add_theme_font_size_override("font_size", 11)
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
	if get_tree().paused and not MiniGameManager.is_minigame_active():
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
	match mood:
		Mood.NORMAL:
			face_anim.play("normal")
		Mood.HAPPY:
			face_anim.play("happy")
		Mood.SAD:
			face_anim.play("sad")
		Mood.ANGRY:
			face_anim.play("angry")
		Mood.TALK:
			face_anim.play("talk")


func push_notification(title: String, body: String, sound: bool = false, scenario_id: String = "") -> void:
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
		close_phone()
	else:
		_show_next_message()


func _on_scene_changing(_scene_path: String) -> void:
	reset()


func _on_minigame_completed(game_id: String, success: bool) -> void:
	if game_id != MINIGAME_ID:
		return
	var text := "Emergencia resuelta.\nEstudiante estabilizado." if success else "Falleció el estudiante."
	push_notification("PIXEL v1.0", text, false, "")
	set_mood(Mood.HAPPY if success else Mood.SAD)


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
	if msg.get("scenario_id", "") == "":
		return
	_message_queue.pop_front()
	_scenario_timer = 0.0
	_mode = PhoneMode.LAUNCHING
	visible = false
	if Global.fainting_approach_pos != Vector2.ZERO:
		var player := get_tree().current_scene.find_child("Player", true, false) as Player
		if player:
			await player.approach_position(Global.fainting_approach_pos)
		Global.fainting_approach_pos = Vector2.ZERO
	if msg.get("scenario_id", "") == MINIGAME_ID:
		await _play_fainting_cinematic()
		
	_mode = PhoneMode.HOME
	MiniGameManager.launch_minigame(MINIGAME_PATH, MINIGAME_ID)

func _play_fainting_cinematic() -> void:
	var tree := get_tree()
	var canvas := CanvasLayer.new()
	canvas.layer = 100
	tree.current_scene.add_child(canvas)

	var blur_shader := load("res://src/singleton/time_blur.gdshader")
	var mat := ShaderMaterial.new()
	mat.shader = blur_shader
	mat.set_shader_parameter("wipe_progress", 0.0)

	var overlay := ColorRect.new()
	overlay.material = mat
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(overlay)

	var tw1 := tree.create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw1.tween_property(mat, "shader_parameter/wipe_progress", 1.0, 0.6)
	await tw1.finished

	await tree.create_timer(0.3).timeout

	var tw2 := tree.create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw2.tween_property(mat, "shader_parameter/wipe_progress", 2.0, 0.6)
	await tw2.finished

	canvas.queue_free()


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
	if not visible:
		return
	anim.play("slide_out")
	slide_sound.play()
	await anim.animation_finished
	visible = false

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
