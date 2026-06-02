extends Control
class_name PauseMenu

var _active_panel: Panel = null
var _pending_slot: int = -1
var _pending_mode: String = ""

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	SceneManager.game_paused.connect(_on_game_paused)
	$OpcionesPanel.panel_closed.connect(_on_panel_closed)
	$ControlesPanel.panel_closed.connect(_on_panel_closed)
	$SlotSelector.panel_closed.connect(_on_panel_closed)
	$SlotSelector.slot_selected.connect(_on_slot_selected)

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

func _on_save_pressed() -> void:
	_active_panel = $SlotSelector
	$SlotSelector.show_panel("save")

func _on_load_pressed() -> void:
	_active_panel = $SlotSelector
	$SlotSelector.show_panel("load")

func _on_slot_selected(slot: int, mode: String) -> void:
	_pending_slot = slot
	_pending_mode = mode
	if mode == "save":
		var info: Dictionary = SaveManager.get_save_info(slot)
		if info.get("empty", true):
			SaveManager.save_to_slot(slot)
			$SlotSelector.hide_panel()
			_active_panel = null
		else:
			$ConfirmationDialog.dialog_text = "¿Sobrescribir SLOT %d?" % (slot + 1)
			$ConfirmationDialog.popup_centered()
	else:
		$ConfirmationDialog.dialog_text = "¿Cargar SLOT %d? Se perderá el progreso no guardado." % (slot + 1)
		$ConfirmationDialog.popup_centered()

func _on_confirmation_confirmed() -> void:
	if _pending_mode == "save":
		SaveManager.save_to_slot(_pending_slot)
		$SlotSelector.hide_panel()
		_active_panel = null
	elif _pending_mode == "load":
		$SlotSelector.hide_panel()
		_active_panel = null
		var last_scene := SaveManager.load_game(_pending_slot)
		if last_scene != "":
			SceneManager.change_scene(last_scene)
	_pending_slot = -1
	_pending_mode = ""

func _on_confirmation_canceled() -> void:
	_pending_slot = -1
	_pending_mode = ""

func _on_exit_game_pressed() -> void:
	SceneManager.change_scene("res://src/menu/main_menu.tscn")
