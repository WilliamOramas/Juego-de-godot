extends StaticBody2D
class_name ObjetoInteractivo

@export var sprite_texture: Texture2D
@export var dialog_lines: Array[String] = []
@export var npc_name: String = ""
@export var sprite_scale: Vector2 = Vector2(0.1, 0.1)

@onready var sprite: Sprite2D = $Sprite2D
@onready var detection_area: Area2D = $DetectionArea

var _player_in_range: Player = null
var _prompt_instance: Control = null

func _ready() -> void:
	if sprite_texture:
		sprite.texture = sprite_texture
		sprite.scale = sprite_scale

	detection_area.body_entered.connect(_on_body_entered)
	detection_area.body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		_player_in_range = body
		_show_prompt()

func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		if _player_in_range == body:
			_player_in_range = null
		_remove_prompt()
		DialogBox.hide_dialog()

func _show_prompt() -> void:
	_remove_prompt()
	var prompt_scene = load(Global.INTERACT_PROMPT_PATH)
	if prompt_scene:
		_prompt_instance = prompt_scene.instantiate()
		add_child(_prompt_instance)
		_prompt_instance.position = Vector2(14, -40)
		_prompt_instance.setup(_on_interact_pressed)

func _remove_prompt() -> void:
	if _prompt_instance and is_instance_valid(_prompt_instance):
		_prompt_instance.queue_free()
	_prompt_instance = null

func _on_interact_pressed() -> void:
	if DialogBox.is_open:
		return

	if _prompt_instance and _prompt_instance.has_method("set_button_visible"):
		_prompt_instance.set_button_visible(false)

	if DialogBox.dialog_finished.is_connected(_on_dialog_finished):
		DialogBox.dialog_finished.disconnect(_on_dialog_finished)
	DialogBox.dialog_finished.connect(_on_dialog_finished)
	DialogBox.show_dialog(npc_name, dialog_lines)

func _on_dialog_finished() -> void:
	DialogBox.dialog_finished.disconnect(_on_dialog_finished)
	if _prompt_instance and is_instance_valid(_prompt_instance) and _prompt_instance.has_method("set_button_visible"):
		_prompt_instance.set_button_visible(true)
