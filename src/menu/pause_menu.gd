extends Control
class_name PauseMenu

func _ready() -> void:
	# Nos conectamos a la señal del SceneManager que trae el bool de pausa
	SceneManager.game_paused.connect(_on_game_paused)

func _on_game_paused(paused: bool) -> void:
	visible = paused

func _on_resume_pressed() -> void:
	SceneManager.pause_game(false)

func _on_exit_game_pressed() -> void:
	SceneManager.change_scene("res://src/menu/main_menu.tscn")
