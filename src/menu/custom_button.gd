extends Button
class_name CustomButton

@onready var click: AudioStreamPlayer = $Click
@onready var on_hover: AudioStreamPlayer = $OnHover


func _on_pressed() -> void:
	click.play()
	
func _on_mouse_entered() -> void:
	on_hover.play()
