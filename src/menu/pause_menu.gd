extends Control
class_name PauseMenu

func _ready() -> void:
	SceneManager.game_paused.connect(_on_game_paused)

func _on_game_paused(paused: bool) -> void:
	visible = paused

func _on_resume_pressed() -> void:
	SceneManager.pause_game(false)

func _on_opciones_pressed() -> void:
	$OpcionesPanel.show_panel()

func _on_controles_pressed() -> void:
	$ControlesPanel.show_panel()

func _on_exit_game_pressed() -> void:
	SceneManager.change_scene("res://src/menu/main_menu.tscn")
