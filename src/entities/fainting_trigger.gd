extends Area2D
class_name FaintingTrigger

const SCENARIO_ID: String = "fainting_first_aid"

var _triggered: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	EventBus.minigame_completed.connect(_on_minigame_completed)


func _on_minigame_completed(game_id: String, _success: bool) -> void:
	if game_id == SCENARIO_ID:
		_triggered = true


func _on_body_entered(body: Node) -> void:
	if body is Player and not _triggered:
		_triggered = true
		body.z_index = 1
		Global.fainting_approach_pos = Vector2(720, 615)
		PhoneHud.push_notification("PIXEL v1.0", "¡EMERGENCIA!\nEstudiante desmayado en escaleras.\n\n[Q] Primeros auxilios.", true, SCENARIO_ID)


func _on_body_exited(body: Node) -> void:
	if body is Player and _triggered and PhoneHud.has_pending_scenario():
		body.z_index = 0
		PhoneHud.cancel_scenario()
		_triggered = false
