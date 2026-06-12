extends StaticBody2D
class_name ObjetoInteractivo

@export var sprite_texture: Texture2D
@export var dialog_lines: Array[String] = []
@export var npc_name: String = ""
@export var sprite_scale: Vector2 = Vector2(0.1, 0.1)

@onready var sprite: Sprite2D = $Sprite2D
@onready var detection_area: Area2D = $DetectionArea

var _player_in_range: Player = null
var _interact: InteractableComponent

func _ready() -> void:
	if sprite_texture:
		sprite.texture = sprite_texture
		sprite.scale = sprite_scale

	detection_area.body_entered.connect(_on_body_entered)
	detection_area.body_exited.connect(_on_body_exited)

	_interact = InteractableComponent.new()
	add_child(_interact)
	_interact.setup(self, Vector2(14, -40), _on_interact_pressed)

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		_player_in_range = body
		_interact.show_prompt()

func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		if _player_in_range == body:
			_player_in_range = null
		_interact.remove_prompt()
		DialogBox.hide_dialog()

func _on_interact_pressed() -> void:
	if DialogBox.is_open:
		return

	_interact.set_button_visible(false)
	DialogBox.show_dialog(npc_name, dialog_lines)
