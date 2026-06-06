extends Area2D
class_name CPRTrigger

const SCENARIO_ID: String = "cpr"

var _triggered: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node) -> void:
	if body is Player and not _triggered:
		_triggered = true
		PhoneHud.push_notification("PIXEL v1.0", "¡PARO CARDÍACO!\nEstudiante no respira.\n\n[Q] Iniciar RCP", true, SCENARIO_ID)


func _on_body_exited(body: Node) -> void:
	if body is Player and _triggered and PhoneHud.has_pending_scenario():
		PhoneHud.cancel_scenario()
		_triggered = false
