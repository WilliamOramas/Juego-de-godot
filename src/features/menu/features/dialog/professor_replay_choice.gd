extends CanvasLayer
class_name ProfessorReplayChoice

signal option_selected(scenario_id: String)
signal cancelled

const SCENARIO_TRIVIA: String = "trivia"
const SCENARIO_WORDLE: String = "wordle"

static var _active_instance: ProfessorReplayChoice = null

var _did_pause_game: bool = false


static func is_active() -> bool:
	return _active_instance != null and is_instance_valid(_active_instance)


func _init() -> void:
	layer = 85
	process_mode = Node.PROCESS_MODE_ALWAYS


func open() -> void:
	if is_active():
		queue_free()
		return

	_active_instance = self
	_build_ui()
	show()
	_block_world_input(true)


func _block_world_input(blocked: bool) -> void:
	if blocked and not get_tree().paused:
		get_tree().paused = true
		_did_pause_game = true
	elif not blocked and _did_pause_game:
		get_tree().paused = false
		_did_pause_game = false

	var player := get_tree().get_first_node_in_group("player") as Player
	if player:
		player.control_enabled = not blocked


func _build_ui() -> void:
	var backdrop := ColorRect.new()
	backdrop.color = Color(0.0, 0.0, 0.0, 0.72)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)

	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.custom_minimum_size = Vector2(420, 260)
	center.add_child(panel)

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.08, 0.11, 0.17, 0.96)
	panel_style.border_color = Color(0.42, 0.78, 0.92, 0.9)
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(10)
	panel_style.content_margin_left = 20
	panel_style.content_margin_right = 20
	panel_style.content_margin_top = 16
	panel_style.content_margin_bottom = 16
	panel.add_theme_stylebox_override("panel", panel_style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "¿Qué quieres practicar?"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(0.93, 0.98, 1.0))
	vbox.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Trivia y Wordle son modos independientes."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.add_theme_font_size_override("font_size", 14)
	subtitle.add_theme_color_override("font_color", Color(0.75, 0.8, 0.88))
	vbox.add_child(subtitle)

	vbox.add_child(_create_option_button("Trivia de primeros auxilios", SCENARIO_TRIVIA))
	vbox.add_child(_create_option_button("Wordle de términos médicos", SCENARIO_WORDLE))

	var cancel_btn := Button.new()
	cancel_btn.text = "Ahora no"
	cancel_btn.pressed.connect(_on_cancel_pressed)
	vbox.add_child(cancel_btn)


func _create_option_button(label_text: String, scenario_id: String) -> Button:
	var btn := Button.new()
	btn.text = label_text
	btn.custom_minimum_size = Vector2(0, 44)
	btn.add_theme_font_size_override("font_size", 16)
	btn.pressed.connect(_on_option_pressed.bind(scenario_id))
	return btn


func _close_menu() -> void:
	_block_world_input(false)
	if _active_instance == self:
		_active_instance = null
	queue_free()


func _on_option_pressed(scenario_id: String) -> void:
	option_selected.emit(scenario_id)
	_close_menu()


func _on_cancel_pressed() -> void:
	cancelled.emit()
	_close_menu()


func _exit_tree() -> void:
	if _active_instance == self:
		_active_instance = null
	if _did_pause_game and get_tree().paused:
		get_tree().paused = false
		_did_pause_game = false
