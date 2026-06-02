extends CanvasLayer

const MINIGAME_PATH: String = "res://src/minigames/mini_fainting_first_aid.tscn"
const MINIGAME_ID: String = "fainting_first_aid"

@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var face_anim: AnimationPlayer = $Phone/FacePlayer
@onready var status_label: Label = $Phone/Status

var is_open: bool = false
var _pending_message: Dictionary = {}
var _pending_scenario: bool = false
var _launching: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	$Phone.position = Vector2(580, 650)
	visible = false
	face_anim.play("talk")

func _unhandled_input(event: InputEvent) -> void:
	if _launching:
		return
	if event.is_action_pressed("Phone"):
		if get_tree().paused and not MiniGameManager.is_minigame_active():
			return
		if _pending_scenario:
			_launch_scenario()
			return
		if _pending_message:
			if is_open:
				close_phone()
			_pending_message = {}
		else:
			toggle_phone()

func notify_scenario() -> void:
	_pending_scenario = true
	show_message("PIXEL v1.0", "¡EMERGENCIA!\nEstudiante desmayado en escaleras.\n\n[Q] Primeros auxilios.")

func _launch_scenario() -> void:
	_launching = true
	_pending_scenario = false
	_pending_message = {}
	is_open = false
	visible = false
	if Global.fainting_approach_pos != Vector2.ZERO:
		var player := get_tree().current_scene.find_child("Player", true, false) as Player
		if player:
			await player.approach_position(Global.fainting_approach_pos)
		Global.fainting_approach_pos = Vector2.ZERO
	_launching = false
	MiniGameManager.launch_minigame(MINIGAME_PATH, MINIGAME_ID)

func show_message(title: String, text: String) -> void:
	_pending_message = {"title": title, "text": text}
	status_label.text = title + "\n" + text
	if not is_open:
		open_phone()

func toggle_phone() -> void:
	if is_open:
		close_phone()
	else:
		open_phone()

func open_phone() -> void:
	is_open = true
	visible = true
	anim.play("slide_in")

func close_phone() -> void:
	if not is_open:
		return
	is_open = false
	anim.play("slide_out")
	await anim.animation_finished
	visible = false
