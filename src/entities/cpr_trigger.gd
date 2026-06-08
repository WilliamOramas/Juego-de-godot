extends Area2D
class_name CPRTrigger

const SCENARIO_ID: String = "cpr"

var _triggered: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	EventBus.minigame_completed.connect(_on_minigame_completed)
	if Global.completed_scenarios.has(SCENARIO_ID):
		_triggered = true


func _on_minigame_completed(game_id: String, _success: bool) -> void:
	if game_id == SCENARIO_ID:
		_triggered = true


func _on_body_entered(body: Node) -> void:
	if body is Player and not _triggered:
		_triggered = true
		PhoneHud.push_notification("PIXEL v1.0", "¡PARO CARDÍACO!\nEstudiante no respira.\n\n[Q] Iniciar RCP", true, SCENARIO_ID)


func _on_body_exited(body: Node) -> void:
	if body is Player and _triggered and PhoneHud.has_pending_scenario():
		PhoneHud.cancel_scenario()
		_triggered = false
