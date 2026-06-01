extends Control
class_name PauseMenu

var _active_panel: Panel = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	SceneManager.game_paused.connect(_on_game_paused)
	$OpcionesPanel.panel_closed.connect(_on_panel_closed)
	$ControlesPanel.panel_closed.connect(_on_panel_closed)

func _on_panel_closed() -> void:
	_active_panel = null

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("Pause") and _active_panel != null:
		_active_panel.hide_panel()
		_active_panel = null
		get_viewport().set_input_as_handled()

func _on_game_paused(paused: bool) -> void:
	visible = paused
	if not paused and _active_panel != null:
		_active_panel.hide_panel()
		_active_panel = null

func _on_resume_pressed() -> void:
	SceneManager.pause_game(false)

func _on_opciones_pressed() -> void:
	_active_panel = $OpcionesPanel
	$OpcionesPanel.show_panel()

func _on_controles_pressed() -> void:
	_active_panel = $ControlesPanel
	$ControlesPanel.show_panel()

func _on_exit_game_pressed() -> void:
	SceneManager.change_scene("res://src/menu/main_menu.tscn")
