extends PhonePanel
class_name JournalPanel

const CATEGORIES := [
	{"name": "Todo", "value": -1},
	{"name": "Minijuego", "value": JournalEntry.Category.MINIGAME},
	{"name": "Diálogo", "value": JournalEntry.Category.DIALOG},
	{"name": "Misión", "value": JournalEntry.Category.QUEST},
	{"name": "Sistema", "value": JournalEntry.Category.SYSTEM},
]

var _container: VBoxContainer
var _tab_buttons: Array[Button] = []
var _current_filter: int = -1


func build_ui() -> void:
	super()
	_main_panel.set_size(Vector2(500, 450))
	call_deferred(&"_center_panel")

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	_main_panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(vbox)

	var title := Label.new()
	title.text = "— BITÁCORA —"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color(0.227451, 0.886275, 0.886275, 1))
	title.add_theme_font_override("font", _font)
	title.add_theme_font_size_override("font_size", 14)
	vbox.add_child(title)

	var tab_bar := HBoxContainer.new()
	tab_bar.alignment = BoxContainer.ALIGNMENT_CENTER
	tab_bar.add_theme_constant_override("separation", 4)
	vbox.add_child(tab_bar)

	for i in range(CATEGORIES.size()):
		var btn := Button.new()
		btn.text = CATEGORIES[i].name
		btn.toggle_mode = true
		btn.button_pressed = (i == 0)
		btn.add_theme_font_override("font", _font)
		btn.add_theme_font_size_override("font_size", 9)
		btn.pressed.connect(_on_tab_pressed.bind(i))
		tab_bar.add_child(btn)
		_tab_buttons.append(btn)

	vbox.add_child(HSeparator.new())

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	_container = VBoxContainer.new()
	_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_container)

	var hint := Label.new()
	hint.text = "[J] / [Esc] — Cerrar"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 1))
	hint.add_theme_font_override("font", _font)
	hint.add_theme_font_size_override("font_size", 9)
	vbox.add_child(hint)

	populate()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("open_journal") or event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


func _on_tab_pressed(index: int) -> void:
	for i in _tab_buttons.size():
		_tab_buttons[i].button_pressed = (i == index)
	_current_filter = CATEGORIES[index].value
	populate()


func populate() -> void:
	for child in _container.get_children():
		child.queue_free()

	var entries: Array[JournalEntry]
	if _current_filter == -1:
		entries = JournalManager.get_entries()
	else:
		entries = JournalManager.get_filtered(_current_filter as JournalEntry.Category)

	if entries.is_empty():
		var empty_label := Label.new()
		empty_label.text = "(sin entradas)"
		empty_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 1))
		empty_label.add_theme_font_size_override("font_size", 10)
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_container.add_child(empty_label)
		return

	for entry in entries:
		var card := VBoxContainer.new()
		card.add_theme_constant_override("separation", 1)

		var card_bg := ColorRect.new()
		card_bg.color = Color(0.15, 0.15, 0.18, 1)
		card_bg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card_bg.custom_minimum_size = Vector2(0, 2)

		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)

		var cat_color := _get_category_color(entry.category)
		var dot := ColorRect.new()
		dot.color = cat_color
		dot.custom_minimum_size = Vector2(6, 6)
		dot.size = Vector2(6, 6)
		row.add_child(dot)

		var title_lbl := Label.new()
		title_lbl.text = entry.title
		title_lbl.add_theme_color_override("font_color", cat_color)
		title_lbl.add_theme_font_size_override("font_size", 10)
		title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(title_lbl)

		var time_lbl := Label.new()
		time_lbl.text = _format_time(entry.timestamp)
		time_lbl.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4, 1))
		time_lbl.add_theme_font_size_override("font_size", 8)
		time_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(time_lbl)

		card.add_child(row)

		if entry.description != "":
			var desc := Label.new()
			desc.text = entry.description
			desc.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1))
			desc.add_theme_font_size_override("font_size", 9)
			desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			card.add_child(desc)

		card.add_child(card_bg)
		_container.add_child(card)


func _get_category_color(cat: JournalEntry.Category) -> Color:
	match cat:
		JournalEntry.Category.MINIGAME:
			return Color(0.2, 1.0, 0.2)
		JournalEntry.Category.DIALOG:
			return Color(0.227451, 0.886275, 0.886275)
		JournalEntry.Category.QUEST:
			return Color.GOLD
		JournalEntry.Category.SYSTEM:
			return Color(1.0, 0.6, 0.8)
	return Color.WHITE


func _format_time(timestamp: float) -> String:
	var elapsed := Time.get_ticks_msec() / 1000.0 - timestamp
	if elapsed < 60:
		return "ahora"
	if elapsed < 3600:
		var m := int(elapsed / 60)
		return "hace %dm" % m
	var h := int(elapsed / 3600)
	return "hace %dh" % h
