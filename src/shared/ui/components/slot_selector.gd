extends Panel

signal slot_selected(slot: int, mode: String, is_cloud: bool)
signal panel_closed

var _mode: String = "new"
var _is_cloud_view: bool = false
var _pending_save_slot: int = -1

@onready var title_label: Label = $VBoxContainer/Title
@onready var tab_local: Button = $VBoxContainer/Tabs/TabLocal
@onready var tab_cloud: Button = $VBoxContainer/Tabs/TabCloud
@onready var cloud_confirm_dialog: ConfirmationDialog = $CloudConfirmDialog
@onready var slot_buttons: Array[Button] = [
	$VBoxContainer/Slot1 as Button,
	$VBoxContainer/Slot2 as Button,
	$VBoxContainer/Slot3 as Button,
]

func _ready() -> void:
	visible = false
	modulate.a = 0.0
	set_process_input(false)
	for i in SaveManager.SAVE_SLOT_COUNT:
		slot_buttons[i].pressed.connect(_on_slot_pressed.bind(i))
	tab_local.pressed.connect(func(): _set_cloud_view(false))
	tab_cloud.pressed.connect(func(): _set_cloud_view(true))
	cloud_confirm_dialog.confirmed.connect(_on_cloud_confirm_confirmed)
	cloud_confirm_dialog.canceled.connect(_on_cloud_confirm_canceled)

func _set_cloud_view(cloud: bool) -> void:
	_is_cloud_view = cloud
	_update_slot_buttons()

func show_panel(mode: String) -> void:
	_mode = mode
	set_process_input(true)
	match mode:
		"new":
			title_label.text = "NUEVA PARTIDA"
		"load":
			title_label.text = "CARGAR PARTIDA"
		"save":
			title_label.text = "GUARDAR PARTIDA"
		"delete":
			title_label.text = "BORRAR PARTIDA"
			
	$VBoxContainer/Tabs.visible = true
	if not Supabase.is_logged_in():
		_is_cloud_view = false
		tab_cloud.disabled = true
	else:
		tab_cloud.disabled = false
		
	_update_slot_buttons()
	modulate.a = 0.0
	AnimHelper.fade_in(self)

func hide_panel() -> void:
	AnimHelper.fade_out(self, AnimHelper.FADE_OUT_DURATION, func():
		visible = false
		set_process_input(false)
	)

func _format_timestamp(unix: int) -> String:
	if unix <= 0:
		return ""
	var tz := Time.get_time_zone_from_system()
	var local_unix = unix + (tz.get("bias", 0) * 60)
	var dt := Time.get_datetime_dict_from_unix_time(local_unix)
	return "%02d/%02d/%d %02d:%02d" % [dt["day"], dt["month"], dt["year"], dt["hour"], dt["minute"]]

func _scene_display_name(scene_path: String) -> String:
	var name_map := {
		"school_hallway": "PASILLO",
		"infirmary": "ENFERMERÍA",
		"classroom_1": "AULA 1",
		"classroom_2": "AULA 2",
	}
	var key := scene_path.get_file().trim_suffix(".tscn")
	return name_map.get(key, key.to_upper())

func _update_slot_buttons() -> void:
	tab_local.modulate.a = 0.5 if _is_cloud_view else 1.0
	tab_cloud.modulate.a = 1.0 if _is_cloud_view else 0.5
	for i in SaveManager.SAVE_SLOT_COUNT:
		var info: Dictionary = SaveManager.get_save_info(i, _is_cloud_view)
		var btn := slot_buttons[i]
		if info.get("empty", true):
			btn.text = "SLOT %d — VACÍO" % (i + 1)
			btn.disabled = ((_mode == "load" or _mode == "delete") and info.get("empty", true))
		else:
			var scene_path: String = info.get("last_scene", "")
			var scene_name: String = _scene_display_name(scene_path)
			var time_str: String = _format_timestamp(info.get("timestamp", 0))
			var score_val: int = info.get("score", 0)
			var grade_val: String = info.get("grade", "?")
			if time_str != "":
				btn.text = "SLOT %d — %s  |  %d pts [%s]\n%s" % [(i + 1), scene_name, score_val, grade_val, time_str]
			else:
				btn.text = "SLOT %d — %s  |  %d pts [%s]" % [(i + 1), scene_name, score_val, grade_val]
			btn.disabled = false

func show_save_feedback(slot: int) -> void:
	var btn := slot_buttons[slot]
	var original := btn.text
	btn.text = "✓ PARTIDA GUARDADA"
	var tween = create_tween()
	tween.tween_callback(func():
		btn.text = original
	).set_delay(1.0)

func _on_slot_pressed(slot: int) -> void:
	if _mode == "save" and not _is_cloud_view and Supabase.is_logged_in():
		_pending_save_slot = slot
		cloud_confirm_dialog.popup_centered()
		return
	slot_selected.emit(slot, _mode, _is_cloud_view)

func _on_cloud_confirm_confirmed() -> void:
	if _pending_save_slot != -1:
		slot_selected.emit(_pending_save_slot, "save_cloud_and_local", false)
		_pending_save_slot = -1

func _on_cloud_confirm_canceled() -> void:
	if _pending_save_slot != -1:
		slot_selected.emit(_pending_save_slot, "save", false)
		_pending_save_slot = -1

func _on_close_pressed() -> void:
	hide_panel()
	panel_closed.emit()
