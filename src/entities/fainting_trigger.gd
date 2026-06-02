extends Area2D
class_name FaintingTrigger

const MINIGAME_PATH: String = "res://src/minigames/mini_fainting_first_aid.tscn"
const MINIGAME_ID: String = "fainting_first_aid"

var _triggered: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body is Player and not _triggered:
		_triggered = true
		Global.fainting_approach_pos = Vector2(680, 610)
		PhoneHud.notify_scenario()
