extends Control
class_name MainMenu

func _ready() -> void:
	# El menú principal NO pausa el árbol. El juego aún no ha comenzado.
	get_tree().paused = false

func _on_start_game_pressed() -> void:
	SceneManager.change_scene("res://src/levels/school_hallway.tscn")

func _on_exit_game_pressed() -> void:
	get_tree().quit()
