extends Control
class_name MainMenu

func _ready() -> void:
	get_tree().paused = false

func _on_start_game_pressed() -> void:
	SceneManager.change_scene("res://src/levels/school_hallway.tscn")

func _on_opciones_pressed() -> void:
	$OpcionesPanel.show_panel()

func _on_controles_pressed() -> void:
	$ControlesPanel.show_panel()

func _on_creditos_pressed() -> void:
	$CreditosPanel.show_panel()

func _on_exit_game_pressed() -> void:
	get_tree().quit()
