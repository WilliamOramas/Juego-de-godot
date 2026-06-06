extends Control
class_name MainMenu

var _active_panel: Control = null
var _pending_slot: int = -1
var _pending_mode: String = ""
var _user_popup: PopupMenu

func _ready() -> void:
	get_tree().paused = false
	$OpcionesPanel.panel_closed.connect(_on_panel_closed)
	$ControlesPanel.panel_closed.connect(_on_panel_closed)
	$CreditosPanel.panel_closed.connect(_on_panel_closed)
	$SlotSelector.panel_closed.connect(_on_panel_closed)
	$SlotSelector.slot_selected.connect(_on_slot_selected)
	
	_user_popup = PopupMenu.new()
	_user_popup.add_item("Cerrar Sesión", 0)
	_user_popup.id_pressed.connect(_on_user_popup_id_pressed)
	add_child(_user_popup)
	
	_update_user_button()

func _update_user_button() -> void:
	if Supabase.is_logged_in():
		$Usuario.text = "👤"
	else:
		$Usuario.text = "USUARIO"

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

func _show_game_buttons(show_submenu: bool) -> void:
	$MarginContainer/VBoxContainer.visible = not show_submenu
	$MarginContainer/SubmenuButtons.visible = show_submenu
	if show_submenu:
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

func _on_borrar_pressed() -> void:
	_active_panel = $SlotSelector
	$SlotSelector.show_panel("delete")

func _on_slot_selected(slot: int, mode: String) -> void:
	_active_panel = null
	match mode:
		"new":
			SaveManager.reset_game(slot)
			SceneManager.change_scene("res://src/levels/school_hallway.tscn")
		"load":
			PhoneHud.reset()
			var last_scene := SaveManager.load_game(slot)
			if last_scene != "":
				SceneManager.change_scene(last_scene)
		"delete":
			_pending_slot = slot
			_pending_mode = mode
			$ConfirmationDialog.dialog_text = "¿Borrar SLOT %d?" % (slot + 1)
			$ConfirmationDialog.popup_centered()

func _on_confirmation_confirmed() -> void:
	if _pending_mode == "delete":
		SaveManager.reset_game(_pending_slot)
		_active_panel = $SlotSelector
		$SlotSelector.show_panel("delete")
	_pending_slot = -1
	_pending_mode = ""

func _on_confirmation_canceled() -> void:
	_pending_slot = -1
	_pending_mode = ""

func _on_opciones_pressed() -> void:
	_active_panel = $OpcionesPanel
	$OpcionesPanel.show_panel()

func _on_controles_pressed() -> void:
	_active_panel = $ControlesPanel
	$ControlesPanel.show_panel()

func _on_creditos_pressed() -> void:
	_active_panel = $CreditosPanel
	$CreditosPanel.show_panel()

func _on_usuario_pressed() -> void:
	if Supabase.is_logged_in():
		var btn_rect = $Usuario.get_global_rect()
		_user_popup.popup(Rect2i(btn_rect.position.x, btn_rect.position.y - 40, 150, 40))
	else:
		SceneManager.change_scene("res://src/menu/login_panel.tscn")

func _on_user_popup_id_pressed(id: int) -> void:
	if id == 0: # Cerrar sesión
		Supabase.logout()
		_update_user_button()

func _on_exit_game_pressed() -> void:
	get_tree().quit()
