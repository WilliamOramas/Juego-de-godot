extends PhonePanel
class_name StatsPanel


func build_ui() -> void:
	super()
	_main_panel.set_size(Vector2(380, 420))
	call_deferred(&"_center_panel")

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	_main_panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 6)
	margin.add_child(vbox)

	var title := Label.new()
	title.text = "— ESTADÍSTICAS —"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color(0.227451, 0.886275, 0.886275, 1))
	title.add_theme_font_override("font", _font)
	title.add_theme_font_size_override("font_size", 14)
	vbox.add_child(title)

	vbox.add_child(HSeparator.new())

	_populate(vbox)

	var hint := Label.new()
	hint.text = "[K] / [Esc] — Cerrar"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 1))
	hint.add_theme_font_override("font", _font)
	hint.add_theme_font_size_override("font_size", 9)
	vbox.add_child(hint)


func _populate(vbox: VBoxContainer) -> void:
	var stats := ScoreManager.get_stats()
	var results := ScoreManager.get_minigame_results()

	_add_stat_row(vbox, "Puntaje total", str(stats.score), Color.GOLD)
	_add_stat_row(vbox, "Rango", stats.grade, _grade_color(stats.grade))

	vbox.add_child(HSeparator.new())

	for id in results:
		var r := results[id] as Dictionary
		var label: String
		match id:
			"cpr": label = "RCP"
			"fainting_first_aid": label = "Primeros Auxilios"
			_: label = id
		_add_stat_row(vbox, label + " — Superado", _yes_no(r.passed), _bool_color(r.passed))
		_add_stat_row(vbox, label + " — Vidas", str(r.lives), Color.WHITE)
		_add_stat_row(vbox, label + " — Tiempo", "%.1fs" % r.time, Color.WHITE)
		_add_stat_row(vbox, label + " — Errores", str(r.errors), _error_color(r.errors))
		vbox.add_child(HSeparator.new())

	_add_stat_row(vbox, "Total vidas restantes", str(stats.lives_remaining), Color.WHITE)
	_add_stat_row(vbox, "Total tiempo restante", "%.1fs" % stats.time_remaining, Color.WHITE)
	_add_stat_row(vbox, "Total errores", str(stats.errors_count), _error_color(stats.errors_count))
	_add_stat_row(vbox, "Intentos de minijuego", str(stats.minigame_attempts), Color.WHITE)

	vbox.add_child(HSeparator.new())

	_add_stat_row(vbox, "Misiones completadas", str(stats.quests_completed), Color.GREEN_YELLOW)
	_add_stat_row(vbox, "NPCs conocidos", str(stats.npcs_talked), Color(0.227451, 0.886275, 0.886275, 1))
	_add_stat_row(vbox, "Errores totales", str(stats.total_errors), _error_color(stats.total_errors))


func _add_stat_row(parent: VBoxContainer, label: String, value: String, value_color: Color) -> void:
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var lbl := Label.new()
	lbl.text = label
	lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1))
	lbl.add_theme_font_override("font", _font)
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(lbl)

	var val := Label.new()
	val.text = value
	val.add_theme_color_override("font_color", value_color)
	val.add_theme_font_override("font", _font)
	val.add_theme_font_size_override("font_size", 11)
	val.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(val)

	parent.add_child(row)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("open_stats") or event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


func _yes_no(v: bool) -> String:
	return "Sí" if v else "No"


func _bool_color(v: bool) -> Color:
	return Color.GREEN if v else Color.RED


func _error_color(count: int) -> Color:
	if count == 0:
		return Color.GREEN
	if count <= 3:
		return Color.YELLOW
	return Color.RED


func _grade_color(grade: String) -> Color:
	match grade:
		"S":
			return Color(1, 0.84, 0)
		"A":
			return Color.GREEN
		"B":
			return Color.YELLOW
		"C":
			return Color.ORANGE
		_:
			return Color.RED
