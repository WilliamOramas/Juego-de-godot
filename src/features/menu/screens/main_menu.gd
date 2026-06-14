extends Control
class_name MainMenu

var _active_panel: Control = null
var _pending_slot: int = -1
var _pending_mode: String = ""
var _pending_is_cloud: bool = false
var _user_popup: PopupMenu

func _ready() -> void:
	add_to_group("main_menu_root")
	get_tree().paused = false
	$OpcionesPanel.panel_closed.connect(_on_panel_closed)
	$ControlesPanel.panel_closed.connect(_on_panel_closed)
	$CreditosPanel.panel_closed.connect(_on_panel_closed)
	$SlotSelector.panel_closed.connect(_on_panel_closed)
	$SlotSelector.slot_selected.connect(_on_slot_selected)
	$LoginPanel.panel_closed.connect(_on_panel_closed)
	$LoginPanel.login_completed.connect(_on_login_completed)
	
	_user_popup = PopupMenu.new()
	_user_popup.add_item("Cerrar Sesión", 0)
	_user_popup.id_pressed.connect(_on_user_popup_id_pressed)
	add_child(_user_popup)
	
	$LoginPanel.visible = false
	$LoginPanel.set_process_input(false)
	_update_user_button()
	_fade_in()


func _fade_in() -> void:
	var fade_rect: ColorRect = $FadeRect
	fade_rect.modulate.a = 1.0
	var tween = create_tween()
	tween.tween_property(fade_rect, "modulate:a", 0.0, 0.8).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	await tween.finished
	fade_rect.queue_free()

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
		if SaveManager.has_game_save(i, false):
			return true
		if Supabase.is_logged_in() and SaveManager.has_game_save(i, true):
			return true
	return false

func _show_game_buttons(show_submenu: bool) -> void:
	$MarginContainer/VBoxContainer.visible = not show_submenu
	$MarginContainer/SubmenuButtons.visible = show_submenu
	if show_submenu:
		var has_save = _has_any_save()
		$MarginContainer/SubmenuButtons/Cargar_Partida.disabled = not has_save
		$MarginContainer/SubmenuButtons/Borrar_Partida.disabled = not has_save

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

func _on_slot_selected(slot: int, mode: String, is_cloud: bool = false) -> void:
	_active_panel = null
	match mode:
		"new":
			SaveManager.reset_game(slot, is_cloud)
			SceneManager.change_scene("res://src/features/levels/school_hallway.tscn")
		"load":
			PhoneHud.reset()
			var last_scene := SaveManager.load_game(slot, is_cloud)
			if last_scene != "":
				SceneManager.change_scene(last_scene)
		"delete":
			_pending_slot = slot
			_pending_mode = mode
			_pending_is_cloud = is_cloud
			$ConfirmationDialog.dialog_text = "¿Borrar SLOT %d?" % (slot + 1)
			$ConfirmationDialog.popup_centered()
		"save":
			SaveManager.save_to_slot(slot, is_cloud)
			_active_panel = $SlotSelector
			$SlotSelector.show_save_feedback(slot)
		"save_cloud_and_local":
			SaveManager.save_to_slot(slot, false)
			SaveManager.save_to_slot(slot, true)
			_active_panel = $SlotSelector
			$SlotSelector.show_save_feedback(slot)

func _on_confirmation_confirmed() -> void:
	if _pending_mode == "delete":
		SaveManager.reset_game(_pending_slot, _pending_is_cloud)
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
		var btn_rect: Rect2 = $Usuario.get_global_rect()
		_user_popup.popup(Rect2i(int(btn_rect.position.x), int(btn_rect.position.y - 40), 150, 40))
	else:
		_active_panel = $LoginPanel
		$LoginPanel.show_panel()


func _on_login_completed(_success: bool) -> void:
	_update_user_button()

func _on_user_popup_id_pressed(id: int) -> void:
	if id == 0: # Cerrar sesión
		Supabase.logout()
		_update_user_button()

func _on_exit_game_pressed() -> void:
	get_tree().quit()
