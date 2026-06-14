extends CanvasLayer
class_name QuestLogPanel

signal closed

var _overlay: ColorRect
var _main_panel: Panel
var _active_container: VBoxContainer
var _completed_container: VBoxContainer

func _ready() -> void:
	layer = 51
	process_mode = PROCESS_MODE_ALWAYS
	build_ui()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("quest_log") or event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()

func build_ui() -> void:
	_overlay = ColorRect.new()
	_overlay.color = Color(0, 0, 0, 0.6)
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(_overlay)

	_main_panel = Panel.new()
	_main_panel.set_anchors_preset(Control.PRESET_CENTER, false)
	_main_panel.set_size(Vector2(500, 450))
	_main_panel.position = Vector2(-250, -225)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.117647, 0.117647, 0.137255, 0.95)
	panel_style.border_width_left = 2
	panel_style.border_width_top = 2
	panel_style.border_width_right = 2
	panel_style.border_width_bottom = 2
	panel_style.border_color = Color(0.294118, 0.294118, 0.352941, 1)
	panel_style.corner_radius_top_left = 4
	panel_style.corner_radius_top_right = 4
	panel_style.corner_radius_bottom_right = 4
	panel_style.corner_radius_bottom_left = 4
	_main_panel.add_theme_stylebox_override("panel", panel_style)
	add_child(_main_panel)

	var font := load("res://src/fonts/coolvetica/Coolvetica Rg.otf") as Font

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	_main_panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_child(vbox)

	var title := Label.new()
	title.text = "\u2501 MISIONES \u2501"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color(0.227451, 0.886275, 0.886275, 1))
	title.add_theme_font_override("font", font)
	title.add_theme_font_size_override("font_size", 14)
	vbox.add_child(title)

	vbox.add_child(HSeparator.new())

	var active_header := Label.new()
	active_header.text = "\u25C6 ACTIVAS:"
	active_header.add_theme_color_override("font_color", Color.GREEN_YELLOW)
	active_header.add_theme_font_override("font", font)
	active_header.add_theme_font_size_override("font_size", 11)
	vbox.add_child(active_header)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	_active_container = VBoxContainer.new()
	_active_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_active_container)

	vbox.add_child(HSeparator.new())

	var completed_header := Label.new()
	completed_header.text = "\u25C6 COMPLETADAS:"
	completed_header.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6, 1))
	completed_header.add_theme_font_override("font", font)
	completed_header.add_theme_font_size_override("font_size", 11)
	vbox.add_child(completed_header)

	var scroll_completed := ScrollContainer.new()
	scroll_completed.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	scroll_completed.custom_minimum_size = Vector2(0, 80)
	vbox.add_child(scroll_completed)

	_completed_container = VBoxContainer.new()
	_completed_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll_completed.add_child(_completed_container)

	var hint := Label.new()
	hint.text = "[M] / [Esc] — Cerrar"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 1))
	hint.add_theme_font_override("font", font)
	hint.add_theme_font_size_override("font_size", 9)
	vbox.add_child(hint)

func populate(active: Dictionary, completed: Dictionary) -> void:
	for child in _active_container.get_children():
		child.queue_free()
	for child in _completed_container.get_children():
		child.queue_free()

	if active.is_empty():
		var empty_label := Label.new()
		empty_label.text = "(ninguna misi\u00f3n activa)"
		empty_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 1))
		empty_label.add_theme_font_size_override("font_size", 10)
		_active_container.add_child(empty_label)
	else:
		for qid in active:
			var entry: Dictionary = active[qid]
			var qdata = entry.get("quest_data")
			if not qdata:
				continue
			var quest_label := Label.new()
			quest_label.text = "\u25B6 " + qdata.quest_name
			quest_label.add_theme_color_override("font_color", Color.GOLD)
			quest_label.add_theme_font_size_override("font_size", 11)
			_active_container.add_child(quest_label)

			for obj in qdata.objectives:
				var done: bool = entry.objectives.get(obj.objective_id, false)
				var row := HBoxContainer.new()
				var check := Label.new()
				check.text = "\u2713" if done else "\u25CB"
				check.add_theme_color_override("font_color", Color.GREEN_YELLOW if done else Color(0.5, 0.5, 0.5, 1))
				check.add_theme_font_size_override("font_size", 11)
				check.custom_minimum_size = Vector2(18, 0)
				row.add_child(check)

				var obj_label := Label.new()
				obj_label.text = obj.description
				obj_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 1) if done else Color(0.6, 0.6, 0.6, 1))
				obj_label.add_theme_font_size_override("font_size", 10)
				row.add_child(obj_label)
				_active_container.add_child(row)

	if completed.is_empty():
		var empty_label := Label.new()
		empty_label.text = "(ninguna)"
		empty_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 1))
		empty_label.add_theme_font_size_override("font_size", 10)
		_completed_container.add_child(empty_label)
	else:
		for qid in completed:
			var qname := _get_quest_name(qid)
			var quest_label := Label.new()
			quest_label.text = "\u2713 " + qname
			quest_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6, 1))
			quest_label.add_theme_font_size_override("font_size", 10)
			_completed_container.add_child(quest_label)

func _get_quest_name(quest_id: String) -> String:
	var path := "res://src/quests/%s.tres" % quest_id
	if ResourceLoader.exists(path):
		var data = load(path) as QuestData
		if data:
			return data.quest_name
	return quest_id

func close() -> void:
	var tw := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw.tween_property(_overlay, "modulate", Color.TRANSPARENT, 0.15)
	tw.parallel().tween_property(_main_panel, "modulate", Color.TRANSPARENT, 0.15)
	await tw.finished
	closed.emit()
	queue_free()
