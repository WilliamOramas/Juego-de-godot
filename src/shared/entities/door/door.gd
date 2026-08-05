extends Area2D
class_name Door

@export_file("*.tscn") var target_scene_path: String
@export var target_spawn_name: String = ""
@export var return_spawn_name: String = ""
@export var use_dynamic_return: bool = false
@export var prompt_offset: Vector2 = Vector2(-14, -35)

var _prompt_instance: Control = null

func _ready() -> void:
	collision_mask = 2
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		if target_scene_path != "":
			_show_prompt()
		else:
			push_warning("La puerta '%s' no tiene una escena destino configurada en el inspector." % name)

func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		_remove_prompt()

func _show_prompt() -> void:
	_remove_prompt()
	var prompt_scene = load(Global.INTERACT_PROMPT_PATH)
	if not prompt_scene:
		return
	_prompt_instance = prompt_scene.instantiate()
	add_child(_prompt_instance)
	_prompt_instance.position = prompt_offset
	_prompt_instance.setup(_on_interact_pressed)

func _remove_prompt() -> void:
	if _prompt_instance and is_instance_valid(_prompt_instance):
		_prompt_instance.queue_free()
	_prompt_instance = null

func _on_interact_pressed() -> void:
	if DialogBox.is_open:
		return
	_remove_prompt()
	SceneManager.change_scene(target_scene_path, target_spawn_name, return_spawn_name, use_dynamic_return)
