extends Node
class_name InteractableComponent

var prompt_instance: Control = null
var interact_callback: Callable
var parent_node: Node
var prompt_offset: Vector2

func setup(parent: Node, offset: Vector2, on_interact: Callable) -> void:
	if not EventBus:
		push_error("InteractableComponent: EventBus no disponible")
		return
	parent_node = parent
	prompt_offset = offset
	interact_callback = on_interact
	if not EventBus.dialog_finished.is_connected(_on_dialog_finished):
		EventBus.dialog_finished.connect(_on_dialog_finished)

func show_prompt() -> void:
	remove_prompt()
	var prompt_scene = load(Global.INTERACT_PROMPT_PATH)
	if prompt_scene:
		prompt_instance = prompt_scene.instantiate()
		parent_node.add_child(prompt_instance)
		prompt_instance.position = prompt_offset
		prompt_instance.setup(_on_interact_pressed)

func remove_prompt() -> void:
	if prompt_instance and is_instance_valid(prompt_instance):
		prompt_instance.queue_free()
	prompt_instance = null

func set_button_visible(is_shown: bool) -> void:
	if prompt_instance and is_instance_valid(prompt_instance) and prompt_instance.has_method("set_button_visible"):
		prompt_instance.set_button_visible(is_shown)

func _on_interact_pressed() -> void:
	if interact_callback.is_valid():
		interact_callback.call()

func _on_dialog_finished() -> void:
	if prompt_instance and is_instance_valid(prompt_instance) and prompt_instance.has_method("set_button_visible"):
		prompt_instance.set_button_visible(true)

func _exit_tree() -> void:
	if EventBus and EventBus.dialog_finished.is_connected(_on_dialog_finished):
		EventBus.dialog_finished.disconnect(_on_dialog_finished)
