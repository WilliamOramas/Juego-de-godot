extends Area2D
class_name FaintingTrigger

var _triggered: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node) -> void:
	if body is Player and not _triggered:
		_triggered = true
		body.z_index = 1
		Global.fainting_approach_pos = Vector2(690, 615)
		PhoneHud.push_notification("PIXEL v1.0", "¡EMERGENCIA!\nEstudiante desmayado en escaleras.\n\n[Q] Primeros auxilios.", true, "fainting_first_aid")


func _on_body_exited(body: Node) -> void:
	if body is Player and _triggered and PhoneHud.has_pending_scenario():
		body.z_index = 0
		PhoneHud.cancel_scenario()
		_triggered = false
