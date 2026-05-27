extends Control
class_name DoorPrompt

signal confirmed
signal canceled

@onready var yes_button: Button = %YesButton
@onready var no_button: Button = %NoButton

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func setup(on_confirm: Callable, on_cancel: Callable) -> void:
	if not is_inside_tree():
		await ready
	confirmed.connect(on_confirm)
	canceled.connect(on_cancel)

func _on_yes_pressed() -> void:
	confirmed.emit()

func _on_no_pressed() -> void:
	canceled.emit()

func _input(event: InputEvent) -> void:
	# Solo respondemos si el prompt está en pantalla
	if not is_inside_tree():
		return
		
	if event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		_on_yes_pressed()
	elif event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_on_no_pressed()
