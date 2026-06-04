extends CanvasLayer

enum PhoneMode { HOME, MESSAGE, SCENARIO, LAUNCHING }

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


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	$Phone.position = Vector2(580, 650)
	visible = false
	face_anim.play("talk")
	EventBus.scene_changing.connect(_on_scene_changing)
	EventBus.minigame_completed.connect(_on_minigame_completed)
	EventBus.dialog_started.connect(_on_dialog_started)
	EventBus.dialog_finished.connect(_on_dialog_finished)


func _process(delta: float) -> void:
	if _mode == PhoneMode.SCENARIO and not _dialog_active:
		_scenario_timer -= delta
		if _scenario_timer <= 0:
			_dismiss_message()


func _unhandled_input(event: InputEvent) -> void:
	if _mode == PhoneMode.LAUNCHING:
		return
	if _dialog_active:
		return
	if get_tree().current_scene is MainMenu:
		return
	if event.is_action_pressed("Phone"):
		if get_tree().paused and not MiniGameManager.is_minigame_active():
			return
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
		status_label.text = "PIXEL v1.0"
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
	
	var black := ColorRect.new()
	black.color = Color.BLACK
	black.modulate.a = 0.0
	black.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(black)
	
	# Fade to black
	var tw1 = tree.create_tween()
	tw1.tween_property(black, "modulate:a", 1.0, 0.5)
	await tw1.finished
	
	# Move camera
	var camera: Camera2D = tree.current_scene.get_viewport().get_camera_2d()
	var old_cam_pos = Vector2.ZERO
	if camera:
		old_cam_pos = camera.global_position
		camera.global_position = Vector2(700, 600)
		
	# Create animated sprite
	var falling_sprite := AnimatedSprite2D.new()
	var frames := SpriteFrames.new()
	frames.add_animation("fall")
	frames.set_animation_speed("fall", 5.0)
	frames.set_animation_loop("fall", false)
	
	for i in range(1, 5):
		var path = "res://src/assets/sprites/patient_fall_%d" % i
		if i == 4:
			path = "res://src/assets/sprites/patient_fall_4_lying.svg"
		else:
			path += ".svg"
		frames.add_frame("fall", load(path))
		
	falling_sprite.sprite_frames = frames
	falling_sprite.scale = Vector2(2.5, 2.5)
	falling_sprite.global_position = Vector2(850, 450)
	tree.current_scene.add_child(falling_sprite)
	
	# Fade in from black
	var tw2 = tree.create_tween()
	tw2.tween_property(black, "modulate:a", 0.0, 0.5)
	await tw2.finished
	
	# Play falling
	falling_sprite.play("fall")
	var tw3 = tree.create_tween()
	tw3.tween_property(falling_sprite, "global_position", Vector2(700, 600), 0.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await falling_sprite.animation_finished
	await tree.create_timer(1.0).timeout
	
	# Fade to black again
	var tw4 = tree.create_tween()
	tw4.tween_property(black, "modulate:a", 1.0, 0.5)
	await tw4.finished
	
	if camera:
		camera.global_position = old_cam_pos
	falling_sprite.queue_free()
	canvas.queue_free()


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
		status_label.text = "PIXEL v1.0"


func close_phone() -> void:
	if not visible:
		return
	anim.play("slide_out")
	slide_sound.play()
	await anim.animation_finished
	visible = false
