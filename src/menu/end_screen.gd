extends CanvasLayer
class_name EndScreen

signal continue_pressed

const STEP_LABELS := [
	"Verificar si responde",
	"Verificar respiración",
	"Verificar pulso carotídeo",
	"Llamar al 112",
	"Elevar piernas",
	"Aflojar ropa ajustada",
	"Monitorear signos",
]

var _success: bool
var _journal_entries: Array[JournalEntry]
var _panel: Panel


func _ready() -> void:
	layer = 80
	process_mode = PROCESS_MODE_WHEN_PAUSED
	build_ui()


func setup(success: bool) -> void:
	_success = success
	_journal_entries = JournalManager.get_filtered(JournalEntry.Category.MINIGAME)


func build_ui() -> void:
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.75)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)

	var font := load("res://src/fonts/coolvetica/Coolvetica Rg.otf") as Font

	_panel = Panel.new()
	_panel.set_size(Vector2(500, 450))
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.117647, 0.117647, 0.137255, 0.95)
	panel_style.border_width_left = 2
	panel_style.border_width_top = 2
	panel_style.border_width_right = 2
	panel_style.border_width_bottom = 2
	panel_style.border_color = Color(0.294118, 0.294118, 0.352941, 1)
	panel_style.corner_radius_top_left = 8
	panel_style.corner_radius_top_right = 8
	panel_style.corner_radius_bottom_right = 8
	panel_style.corner_radius_bottom_left = 8
	_panel.add_theme_stylebox_override("panel", panel_style)
	add_child(_panel)
	call_deferred(&"_center_panel")

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	_panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 6)
	margin.add_child(vbox)

	var result_label := Label.new()
	var stats := ScoreManager.get_stats()
	if _success:
		result_label.text = "✓ ESTUDIANTE ESTABILIZADO"
		result_label.add_theme_color_override("font_color", Color(0.2, 1.0, 0.2))
	else:
		result_label.text = "✗ ESTUDIANTE FALLECIDO"
		result_label.add_theme_color_override("font_color", Color.RED)
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_label.add_theme_font_override("font", font)
	result_label.add_theme_font_size_override("font_size", 16)
	vbox.add_child(result_label)

	var grade_row := HBoxContainer.new()
	grade_row.alignment = BoxContainer.ALIGNMENT_CENTER

	var score_label := Label.new()
	score_label.text = "Puntaje: %d" % stats.score
	score_label.add_theme_color_override("font_color", Color.GOLD)
	score_label.add_theme_font_override("font", font)
	score_label.add_theme_font_size_override("font_size", 12)
	grade_row.add_child(score_label)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(20, 0)
	grade_row.add_child(spacer)

	var grade_val := Label.new()
	grade_val.text = "Rango: %s" % stats.grade
	grade_val.add_theme_color_override("font_color", Color(0.227451, 0.886275, 0.886275, 1))
	grade_val.add_theme_font_override("font", font)
	grade_val.add_theme_font_size_override("font_size", 12)
	grade_row.add_child(grade_val)

	vbox.add_child(grade_row)

	vbox.add_child(HSeparator.new())

	var checklist_title := Label.new()
	checklist_title.text = "Pasos de primeros auxilios:"
	checklist_title.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1))
	checklist_title.add_theme_font_override("font", font)
	checklist_title.add_theme_font_size_override("font_size", 11)
	vbox.add_child(checklist_title)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	var check_vbox := VBoxContainer.new()
	check_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(check_vbox)

	for i in range(STEP_LABELS.size()):
		_add_step_row(check_vbox, i, font)

	vbox.add_child(HSeparator.new())

	var continue_btn := Button.new()
	continue_btn.text = "Continuar"
	continue_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	continue_btn.add_theme_font_override("font", font)
	continue_btn.add_theme_font_size_override("font_size", 12)
	continue_btn.pressed.connect(_on_continue)
	vbox.add_child(continue_btn)


func _add_step_row(parent: VBoxContainer, index: int, font: Font) -> void:
	var step_num := index + 1
	var step_done := _is_step_done(step_num)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)

	var check := Label.new()
	check.text = "✓" if step_done else "✗"
	check.add_theme_color_override("font_color", Color.GREEN if step_done else Color(0.4, 0.2, 0.2))
	check.add_theme_font_size_override("font_size", 11)
	check.custom_minimum_size = Vector2(16, 0)
	row.add_child(check)

	var lbl := Label.new()
	var txt := "Paso %d: %s" % [step_num, STEP_LABELS[index]]
	lbl.text = txt
	lbl.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 1) if step_done else Color(0.4, 0.4, 0.4, 1))
	lbl.add_theme_font_override("font", font)
	lbl.add_theme_font_size_override("font_size", 10)
	row.add_child(lbl)

	parent.add_child(row)


func _is_step_done(step_num: int) -> bool:
	var prefix := "Paso %d" % step_num
	for entry in _journal_entries:
		if entry.title.begins_with(prefix) and not entry.description.begins_with("✗"):
			return true
	return false


func _center_panel() -> void:
	var vs := get_viewport().get_visible_rect().size
	_panel.position = vs / 2 - _panel.size / 2

func _on_continue() -> void:
	continue_pressed.emit()
	queue_free()
