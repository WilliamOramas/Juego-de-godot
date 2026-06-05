extends Panel

signal slot_selected(slot: int, mode: String)
signal panel_closed

var _mode: String = "new"

@onready var title_label: Label = $VBoxContainer/Title
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
	_update_slot_buttons()
	modulate.a = 0.0
	visible = true
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.15)

func hide_panel() -> void:
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.1)
	tween.tween_callback(func():
		visible = false
		set_process_input(false)
	)

func _format_timestamp(unix: int) -> String:
	if unix <= 0:
		return ""
	var dt := Time.get_datetime_dict_from_unix_time(unix)
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
	for i in SaveManager.SAVE_SLOT_COUNT:
		var info: Dictionary = SaveManager.get_save_info(i)
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
	slot_selected.emit(slot, _mode)

func _on_close_pressed() -> void:
	hide_panel()
	panel_closed.emit()
