extends CanvasLayer

@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var face_anim: AnimationPlayer = $Phone/FacePlayer

var is_open: bool = false

func _ready() -> void:
	# Asegurarnos de que el teléfono empiece escondido y desactivado
	$Phone.position = Vector2(580, 650)
	visible = false
	face_anim.play("talk")

func _unhandled_input(event: InputEvent) -> void:
	if get_tree().paused:
		return
	if event.is_action_pressed("Phone"):
		toggle_phone()

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
	is_open = false
	anim.play("slide_out")
	await anim.animation_finished
	if not is_open:
		visible = false
