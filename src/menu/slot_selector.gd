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
	if mode == "new":
		title_label.text = "NUEVA PARTIDA"
	else:
		title_label.text = "CARGAR PARTIDA"
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

func _update_slot_buttons() -> void:
	for i in SaveManager.SAVE_SLOT_COUNT:
		var info: Dictionary = SaveManager.get_save_info(i)
		var btn := slot_buttons[i]
		if info.get("empty", true):
			btn.text = "SLOT %d — VACÍO" % (i + 1)
			btn.disabled = (_mode == "load")
		else:
			var scene_path: String = info.get("last_scene", "")
			var scene_name: String = scene_path.get_file().trim_suffix(".tscn").to_upper()
			btn.text = "SLOT %d — %s" % [(i + 1), scene_name]
			btn.disabled = false

func _on_slot_pressed(slot: int) -> void:
	slot_selected.emit(slot, _mode)

func _on_close_pressed() -> void:
	hide_panel()
	panel_closed.emit()
