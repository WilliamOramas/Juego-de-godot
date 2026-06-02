extends Control
class_name MainMenu

var _active_panel: Panel = null

func _ready() -> void:
	get_tree().paused = false
	$OpcionesPanel.panel_closed.connect(_on_panel_closed)
	$ControlesPanel.panel_closed.connect(_on_panel_closed)
	$CreditosPanel.panel_closed.connect(_on_panel_closed)
	$SlotSelector.panel_closed.connect(_on_panel_closed)
	$SlotSelector.slot_selected.connect(_on_slot_selected)

func _on_panel_closed() -> void:
	_active_panel = null

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("Pause") and _active_panel != null:
		_active_panel.hide_panel()
		_active_panel = null
		get_viewport().set_input_as_handled()

func _has_any_save() -> bool:
	for i in SaveManager.SAVE_SLOT_COUNT:
		if SaveManager.has_game_save(i):
			return true
	return false

func _show_game_buttons(show: bool) -> void:
	$MarginContainer/VBoxContainer.visible = not show
	$MarginContainer/SubmenuButtons.visible = show
	if show:
		$MarginContainer/SubmenuButtons/Cargar_Partida.disabled = not _has_any_save()

func _on_jugar_pressed() -> void:
	_show_game_buttons(true)

func _on_volver_pressed() -> void:
	_show_game_buttons(false)

func _on_new_game_pressed() -> void:
	_active_panel = $SlotSelector
	$SlotSelector.show_panel("new")

func _on_continue_pressed() -> void:
	_active_panel = $SlotSelector
	$SlotSelector.show_panel("load")

func _on_slot_selected(slot: int, mode: String) -> void:
	_active_panel = null
	if mode == "new":
		SaveManager.reset_game(slot)
		SceneManager.change_scene("res://src/levels/school_hallway.tscn")
	else:
		var last_scene := SaveManager.load_game(slot)
		if last_scene != "":
			SceneManager.change_scene(last_scene)

func _on_opciones_pressed() -> void:
	_active_panel = $OpcionesPanel
	$OpcionesPanel.show_panel()

func _on_controles_pressed() -> void:
	_active_panel = $ControlesPanel
	$ControlesPanel.show_panel()

func _on_creditos_pressed() -> void:
	_active_panel = $CreditosPanel
	$CreditosPanel.show_panel()

func _on_exit_game_pressed() -> void:
	get_tree().quit()
