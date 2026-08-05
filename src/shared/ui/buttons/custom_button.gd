extends Button
class_name CustomButton

@onready var click: AudioStreamPlayer = $Click
@onready var on_hover: AudioStreamPlayer = $OnHover


func _on_pressed() -> void:
	if click and click.stream:
		# Crear un reproductor temporal en la raíz del árbol para que no se destruya al cambiar de escena
		var temp_player := AudioStreamPlayer.new()
		temp_player.stream = click.stream
		temp_player.volume_db = click.volume_db
		temp_player.process_mode = Node.PROCESS_MODE_ALWAYS
		get_tree().root.add_child(temp_player)
		temp_player.play()
		temp_player.finished.connect(temp_player.queue_free)
	else:
		click.play()
	
func _on_mouse_entered() -> void:
	on_hover.play()
