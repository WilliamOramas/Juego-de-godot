extends MiniGameBase

const QUESTION_COUNT: int = 4
const STRIKE_LIMIT: int = 3
const TIME_LIMIT_SEC: float = 120.0
const LOADING_DOTS: Array[String] = ["", ".", "..", "..."]
const P1_MARGIN_X: float = 40.0
const P1_HEADER_HEIGHT: float = 118.0
const P1_STATUS_RESERVE: float = 112.0
const P1_CORRECTION_TOP: float = 108.0
const P1_OPTION_FONT_SIZE: int = 16
const P1_OPTION_SEPARATION: int = 10
const P1_GRID_COLUMNS: int = 2
const P1_LONG_QUESTION_MAX_HEIGHT: float = 72.0
const P1_OPTION_BORDER_WIDTH: int = 2
const P1_OPTION_RADIUS: int = 8
const P1_OPTION_TEXT_COLOR := Color(0.93, 0.98, 1.0)
const P1_OPTION_BORDER_COLOR := Color(0.42, 0.78, 0.92, 0.9)
const P1_OPTION_BG_COLOR := Color(0.10, 0.15, 0.24, 0.84)
const QUESTIONS_LOAD_TIMEOUT_SEC: float = 15.0
const ENRIQUE_CORRECT_CHANCE: float = 0.5
const P1_FEEDBACK_DELAY_SEC: float = 2.0
const P1_WRONG_FEEDBACK_DELAY_SEC: float = 3.5
const EXTREME_DIFFICULTY_STREAK: int = 3

# === UI Nodes ===
var _loading_overlay: Control
var _loading_label: Label
var _loading_dots_label: Label
var _loading_dot_timer: float = 0.0
var _loading_dot_index: int = 0

var p1_container: Control
var p1_question: Label
var p1_options: GridContainer
var _p1_options_use_grid: bool = true
var p1_player_strikes: Label
var p1_enrique_strikes: Label
var p1_correction_panel: PanelContainer
var p1_correction_title: Label
var p1_correction_label: Label
var p1_footer_panel: PanelContainer
var p1_footer_player_label: Label
var p1_footer_enrique_label: Label
var p1_source_label: Label
var _using_fallback_questions: bool = false
var _questions_resolved: bool = false

# === Audio ===
var bgm: AudioStreamPlayer
var correct_sound: AudioStreamPlayer
var wrong_sound: AudioStreamPlayer
var step_sound: AudioStreamPlayer
var success_fanfare: AudioStreamPlayer
var fail_sound: AudioStreamPlayer

# === State Phase 1 ===
var player_strikes: int = 0
var enrique_strikes: int = 0
var questions_asked: int = 0
var question_pool: Array[Dictionary] = []
var _used_question_keys: Array[String] = []
var current_question: Dictionary = {}
var _difficulty_max: int = TriviaQuestionGenerator.DIFFICULTY_MEDIUM
var _consecutive_player_wrongs: int = 0
var _consecutive_player_corrects: int = 0

var _time_elapsed: float = 0.0
var _step_start_time: float = 0.0

func _ready() -> void:
	super._ready()
	if background:
		background.hide()
	_build_ui()

	bgm = _create_audio(preload("res://src/shared/assets/sounds/Quiz_BACKGROUND_MUSIC.mp3"), -8.0)
	bgm.play()
	bgm.finished.connect(bgm.play)

	correct_sound = _create_audio(preload("res://src/shared/assets/sounds/correct.wav"))
	wrong_sound = _create_audio(preload("res://src/shared/assets/sounds/wrong.wav"))
	step_sound = _create_audio(preload("res://src/shared/assets/sounds/step.wav"))
	success_fanfare = _create_audio(preload("res://src/shared/assets/sounds/success_fanfare.wav"))
	fail_sound = _create_audio(preload("res://src/shared/assets/sounds/fail_sound.wav"))

func start() -> void:
	if _is_running:
		return
	_is_running = true
	process_mode = Node.PROCESS_MODE_ALWAYS
	show()
	_show_loading(true)
	_questions_resolved = false
	_arm_questions_load_timeout()
	TriviaQuestionGenerator.fetch_session_pool(_on_questions_ready)


func _arm_questions_load_timeout() -> void:
	get_tree().create_timer(QUESTIONS_LOAD_TIMEOUT_SEC).timeout.connect(_on_questions_load_timeout)


func _on_questions_load_timeout() -> void:
	if _questions_resolved or not _is_running:
		return
	if not is_instance_valid(_loading_overlay) or not _loading_overlay.visible:
		return
	_on_questions_ready(TriviaQuestionGenerator.get_fallback_pool(), true)


func _on_questions_ready(questions_data: Array, used_fallback: bool) -> void:
	if not _is_running or _questions_resolved:
		return
	_questions_resolved = true
	_using_fallback_questions = used_fallback
	question_pool.clear()
	for item: Variant in questions_data:
		if typeof(item) == TYPE_DICTIONARY:
			question_pool.append(item as Dictionary)
	_reset_phase1_state()
	_update_source_label()
	_show_loading(false)
	if question_pool.is_empty():
		end(false)
		return
	_enter_paused_play()
	_next_question()


func _enter_paused_play() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	get_tree().paused = true
	if background:
		var tween := create_tween()
		tween.tween_property(background, "modulate:a", 0.5, 0.15)


func _reset_phase1_state() -> void:
	player_strikes = 0
	enrique_strikes = 0
	questions_asked = 0
	_used_question_keys.clear()
	current_question = {}
	_difficulty_max = TriviaQuestionGenerator.DIFFICULTY_MEDIUM
	_consecutive_player_wrongs = 0
	_consecutive_player_corrects = 0
	if is_instance_valid(p1_player_strikes):
		p1_player_strikes.text = "Tus Strikes: 0/%d" % STRIKE_LIMIT
	if is_instance_valid(p1_enrique_strikes):
		p1_enrique_strikes.text = "Strikes de Enrique: 0/%d" % STRIKE_LIMIT
	_clear_round_feedback()


func _update_source_label() -> void:
	if not is_instance_valid(p1_source_label):
		return
	if _using_fallback_questions:
		p1_source_label.text = "Fuente: preguntas predeterminadas"
		p1_source_label.add_theme_color_override("font_color", Color(1.0, 0.72, 0.35))
	else:
		p1_source_label.text = "Fuente: IA (%s)" % AiClient.get_content_model()
		p1_source_label.add_theme_color_override("font_color", Color(0.4, 0.9, 0.9))


func _show_loading(is_loading: bool) -> void:
	if not is_instance_valid(_loading_overlay):
		return
	_loading_overlay.visible = is_loading
	if is_instance_valid(p1_container):
		p1_container.visible = not is_loading
	if is_loading:
		_loading_dot_index = 0
		_loading_dot_timer = 0.0
		if is_instance_valid(_loading_dots_label):
			_loading_dots_label.text = LOADING_DOTS[0]

# === Helpers para Refactorización ===
func _create_audio(stream: AudioStream, volume: float = 0.0) -> AudioStreamPlayer:
	var player = AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = volume
	game_container.add_child(player)
	return player

func _create_label(parent: Node, text: String, font_size: int = -1, color: Color = Color.WHITE, 	align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_CENTER) -> Label:
	var lbl = Label.new()
	lbl.text = text
	lbl.horizontal_alignment = align
	if font_size > 0:
		lbl.add_theme_font_size_override("font_size", font_size)
	if color != Color.WHITE:
		lbl.add_theme_color_override("font_color", color)
	parent.add_child(lbl)
	return lbl

func _set_top_wide(node: Control, top_y: float, height: float) -> void:
	node.set_anchors_preset(Control.PRESET_TOP_WIDE)
	node.offset_top = top_y
	node.offset_bottom = top_y + height


func _create_footer_result_box(parent: HBoxContainer, title: String, accent: Color) -> Label:
	var box := PanelContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.custom_minimum_size = Vector2(0, 52)

	var box_style := StyleBoxFlat.new()
	box_style.bg_color = Color(0.12, 0.14, 0.18, 1.0)
	box_style.border_color = accent.darkened(0.25)
	box_style.set_border_width_all(1)
	box_style.set_corner_radius_all(6)
	box_style.content_margin_left = 10
	box_style.content_margin_right = 10
	box_style.content_margin_top = 6
	box_style.content_margin_bottom = 6
	box.add_theme_stylebox_override("panel", box_style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	box.add_child(vbox)

	_create_label(vbox, title, 12, accent, HORIZONTAL_ALIGNMENT_CENTER)
	var result_label := _create_label(vbox, "—", 15, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	parent.add_child(box)
	return result_label


func _build_loading_overlay() -> void:
	_loading_overlay = Control.new()
	game_container.add_child(_loading_overlay)
	_loading_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_loading_overlay.visible = false

	var loading_bg := ColorRect.new()
	loading_bg.color = Color(0, 0, 0, 0.9)
	loading_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_loading_overlay.add_child(loading_bg)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_loading_overlay.add_child(center)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 12)
	center.add_child(vbox)

	_loading_label = _create_label(vbox, "GENERANDO PREGUNTAS", 24, Color(0.227, 0.886, 0.886))

	var dots_row := HBoxContainer.new()
	dots_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(dots_row)

	_loading_dots_label = _create_label(dots_row, "...", 24, Color(0.227, 0.886, 0.886))

	var hint := _create_label(vbox, "La IA está preparando tu trivia de primeros auxilios", 16, Color(0.7, 0.7, 0.7))
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD


func _build_ui() -> void:
	_build_loading_overlay()

	# ================= PHASE 1 UI =================
	p1_container = Control.new()
	game_container.add_child(p1_container)
	p1_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	p1_container.visible = false

	var panel_bg = ColorRect.new()
	p1_container.add_child(panel_bg)
	panel_bg.color = Color(0, 0, 0, 0.8)
	panel_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	var title = _create_label(p1_container, "TRIVIA MÉDICA: TÚ VS ENRIQUE", 24)
	_set_top_wide(title, 20, 40)
	
	p1_player_strikes = _create_label(p1_container, "Tus Strikes: 0/%d" % STRIKE_LIMIT, -1, Color.AQUA, HORIZONTAL_ALIGNMENT_LEFT)
	p1_player_strikes.set_anchors_preset(Control.PRESET_TOP_LEFT)
	p1_player_strikes.position = Vector2(48, 66)
	p1_player_strikes.size = Vector2(320, 42)
	
	p1_enrique_strikes = _create_label(p1_container, "Strikes de Enrique: 0/%d" % STRIKE_LIMIT, -1, Color.ORANGE, HORIZONTAL_ALIGNMENT_RIGHT)
	p1_enrique_strikes.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	p1_enrique_strikes.position = Vector2(-368, 66)
	p1_enrique_strikes.size = Vector2(320, 42)
	
	p1_correction_panel = PanelContainer.new()
	p1_correction_panel.visible = false
	p1_correction_panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	p1_container.add_child(p1_correction_panel)

	var correction_style := StyleBoxFlat.new()
	correction_style.bg_color = Color(0.18, 0.1, 0.1, 0.95)
	correction_style.border_color = Color(0.95, 0.45, 0.35)
	correction_style.set_border_width_all(2)
	correction_style.set_corner_radius_all(8)
	correction_style.content_margin_left = 14
	correction_style.content_margin_right = 14
	correction_style.content_margin_top = 8
	correction_style.content_margin_bottom = 10
	p1_correction_panel.add_theme_stylebox_override("panel", correction_style)

	var correction_vbox := VBoxContainer.new()
	correction_vbox.add_theme_constant_override("separation", 4)
	p1_correction_panel.add_child(correction_vbox)

	p1_correction_title = _create_label(correction_vbox, "¡Incorrecto!", 17, Color(1.0, 0.55, 0.45), HORIZONTAL_ALIGNMENT_LEFT)
	p1_correction_label = _create_label(correction_vbox, "", 15, Color(0.95, 0.95, 0.95), HORIZONTAL_ALIGNMENT_LEFT)
	p1_correction_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	p1_question = _create_label(p1_container, "Pregunta...", 20)
	p1_question.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	p1_question.set_anchors_preset(Control.PRESET_TOP_WIDE)

	p1_footer_panel = PanelContainer.new()
	p1_footer_panel.visible = false
	p1_footer_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	p1_footer_panel.offset_left = P1_MARGIN_X
	p1_footer_panel.offset_right = -P1_MARGIN_X
	p1_footer_panel.offset_top = -P1_STATUS_RESERVE
	p1_footer_panel.offset_bottom = -28
	p1_container.add_child(p1_footer_panel)

	var footer_style := StyleBoxFlat.new()
	footer_style.bg_color = Color(0.07, 0.09, 0.14, 0.96)
	footer_style.border_color = Color(0.35, 0.42, 0.55)
	footer_style.set_border_width_all(2)
	footer_style.set_corner_radius_all(10)
	footer_style.content_margin_left = 12
	footer_style.content_margin_right = 12
	footer_style.content_margin_top = 10
	footer_style.content_margin_bottom = 10
	p1_footer_panel.add_theme_stylebox_override("panel", footer_style)

	var footer_row := HBoxContainer.new()
	footer_row.add_theme_constant_override("separation", 16)
	footer_row.alignment = BoxContainer.ALIGNMENT_CENTER
	p1_footer_panel.add_child(footer_row)

	var player_box := _create_footer_result_box(footer_row, "TÚ", Color.AQUA)
	p1_footer_player_label = player_box

	var enrique_box := _create_footer_result_box(footer_row, "ENRIQUE", Color.ORANGE)
	p1_footer_enrique_label = enrique_box

	p1_source_label = _create_label(p1_container, "", 13, Color(0.7, 0.7, 0.7), HORIZONTAL_ALIGNMENT_LEFT)
	p1_source_label.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	p1_source_label.offset_left = P1_MARGIN_X
	p1_source_label.offset_top = -22
	p1_source_label.offset_right = 420
	p1_source_label.offset_bottom = -4

	p1_options = GridContainer.new()
	p1_options.z_index = 1
	p1_options.columns = P1_GRID_COLUMNS
	p1_options.add_theme_constant_override("h_separation", P1_OPTION_SEPARATION)
	p1_options.add_theme_constant_override("v_separation", P1_OPTION_SEPARATION)
	p1_container.add_child(p1_options)

func _next_question() -> void:
	if player_strikes >= STRIKE_LIMIT:
		_finish_trivia_outcome("loss", false, 0)
		return
	if enrique_strikes >= STRIKE_LIMIT:
		_finish_trivia_outcome("win", true, STRIKE_LIMIT - player_strikes)
		return

	if questions_asked >= QUESTION_COUNT:
		_finish_trivia_outcome("tie", false, STRIKE_LIMIT - player_strikes)
		return
		
	current_question = TriviaQuestionGenerator.pick_question(
		question_pool,
		_used_question_keys,
		_get_pick_difficulty_max(),
		_allows_extreme_questions()
	)
	if current_question.is_empty():
		end(false)
		return

	var question_key := TriviaQuestionGenerator.question_key(current_question)
	if not question_key.is_empty():
		_used_question_keys.append(question_key)

	var q := current_question
	_clear_round_feedback()
	p1_question.text = "Pregunta %d: %s" % [(questions_asked + 1), q["q"]]
	_step_start_time = _time_elapsed

	var content_width := _get_p1_content_width()
	_p1_options_use_grid = _measure_label_height(p1_question, content_width) <= P1_LONG_QUESTION_MAX_HEIGHT
	p1_options.columns = P1_GRID_COLUMNS if _p1_options_use_grid else 1

	var option_width := content_width
	if _p1_options_use_grid:
		option_width = (content_width - float(P1_OPTION_SEPARATION)) / float(P1_GRID_COLUMNS)

	for child in p1_options.get_children():
		child.queue_free()

	var ops: Array = q.get("ops", [])
	for i in range(ops.size()):
		p1_options.add_child(_create_option_button(String(ops[i]), i, option_width))

	call_deferred("_layout_phase1_ui")

func _get_p1_content_width() -> float:
	var viewport_width := get_viewport().get_visible_rect().size.x
	return maxf(280.0, viewport_width - P1_MARGIN_X * 2.0)


func _measure_label_height(label: Label, width: float) -> float:
	var font := label.get_theme_font("font")
	var font_size := label.get_theme_font_size("font_size")
	if font == null:
		return 48.0
	return font.get_multiline_string_size(
		label.text,
		label.horizontal_alignment,
		width,
		font_size
	).y


func _layout_phase1_ui() -> void:
	if not is_instance_valid(p1_container) or not p1_container.visible:
		return

	var vp_size := get_viewport().get_visible_rect().size
	var content_width := _get_p1_content_width()

	if is_instance_valid(p1_correction_panel) and p1_correction_panel.visible:
		p1_correction_panel.offset_left = P1_MARGIN_X
		p1_correction_panel.offset_right = -P1_MARGIN_X
		p1_correction_panel.offset_top = P1_CORRECTION_TOP
		var correction_height := _measure_label_height(p1_correction_label, content_width - 28.0) + 40.0
		p1_correction_panel.offset_bottom = P1_CORRECTION_TOP + correction_height

	var options_height := _measure_options_block_height(content_width)
	var question_height := _measure_label_height(p1_question, content_width)
	var block_height := question_height + 16.0 + options_height
	var area_top := P1_HEADER_HEIGHT
	if is_instance_valid(p1_correction_panel) and p1_correction_panel.visible:
		area_top = p1_correction_panel.offset_bottom + 12.0
	var area_bottom := vp_size.y - P1_STATUS_RESERVE - 16.0
	var block_top := area_top + maxf(0.0, (area_bottom - area_top - block_height) * 0.5)

	p1_question.set_anchors_preset(Control.PRESET_TOP_LEFT)
	p1_question.position = Vector2(P1_MARGIN_X, block_top)
	p1_question.size = Vector2(content_width, question_height)

	p1_options.position = Vector2(P1_MARGIN_X, block_top + question_height + 16.0)
	p1_options.size = Vector2(content_width, maxf(options_height, 48.0))


func _measure_options_block_height(content_width: float) -> float:
	var buttons: Array[Button] = []
	for child in p1_options.get_children():
		if child is Button:
			buttons.append(child as Button)

	if buttons.is_empty():
		return 0.0

	var button_width := content_width
	if _p1_options_use_grid:
		button_width = (content_width - float(P1_OPTION_SEPARATION)) / float(P1_GRID_COLUMNS)

	if not _p1_options_use_grid:
		var total_height := 0.0
		var is_first := true
		for btn: Button in buttons:
			if not is_first:
				total_height += P1_OPTION_SEPARATION
			is_first = false
			_resize_option_button(btn, button_width)
			total_height += btn.custom_minimum_size.y
		return total_height

	var row_count := ceili(float(buttons.size()) / float(P1_GRID_COLUMNS))
	var total_grid_height := 0.0
	for row in range(row_count):
		var row_height := 0.0
		for col in range(P1_GRID_COLUMNS):
			var index := row * P1_GRID_COLUMNS + col
			if index >= buttons.size():
				break
			var btn := buttons[index]
			_resize_option_button(btn, button_width)
			row_height = maxf(row_height, btn.custom_minimum_size.y)
		if row > 0:
			total_grid_height += P1_OPTION_SEPARATION
		total_grid_height += row_height
	return total_grid_height


func _measure_option_text_height(text: String, width: float) -> float:
	var font := ThemeDB.fallback_font
	if font == null:
		return 24.0
	return font.get_multiline_string_size(
		text,
		HORIZONTAL_ALIGNMENT_LEFT,
		width,
		P1_OPTION_FONT_SIZE
	).y


func _build_option_stylebox(bg_color: Color, border_color: Color, border_width: int = P1_OPTION_BORDER_WIDTH) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(P1_OPTION_RADIUS)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.45)
	style.shadow_size = 5
	style.shadow_offset = Vector2(0, 2)
	return style


func _apply_option_button_styles(btn: Button) -> void:
	var normal := _build_option_stylebox(P1_OPTION_BG_COLOR, P1_OPTION_BORDER_COLOR)
	var hover := _build_option_stylebox(
		Color(0.14, 0.21, 0.32, 0.92),
		Color(0.58, 0.88, 1.0, 0.98)
	)
	var pressed := _build_option_stylebox(
		Color(0.08, 0.24, 0.30, 0.94),
		Color(0.70, 0.96, 1.0, 1.0)
	)
	var disabled := _build_option_stylebox(
		Color(0.08, 0.11, 0.16, 0.62),
		Color(0.30, 0.38, 0.48, 0.55),
		1
	)
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_stylebox_override("disabled", disabled)
	btn.add_theme_stylebox_override("focus", normal)
	btn.add_theme_color_override("font_color", P1_OPTION_TEXT_COLOR)
	btn.add_theme_color_override("font_hover_color", Color.WHITE)
	btn.add_theme_color_override("font_pressed_color", Color.WHITE)
	btn.add_theme_color_override("font_disabled_color", Color(0.72, 0.78, 0.86))


func _resize_option_button(btn: Button, content_width: float) -> void:
	var text_height := _measure_option_text_height(btn.text, content_width - 32.0)
	var option_height := maxf(52.0, text_height + 28.0)
	btn.custom_minimum_size = Vector2(content_width, option_height)


func _create_option_button(option_text: String, index: int, width: float) -> Button:
	var text_height := _measure_option_text_height(option_text, width - 32.0)
	var option_height := maxf(52.0, text_height + 28.0)

	var btn := Button.new()
	btn.text = option_text
	btn.alignment = HORIZONTAL_ALIGNMENT_CENTER
	btn.add_theme_font_size_override("font_size", P1_OPTION_FONT_SIZE)
	btn.custom_minimum_size = Vector2(width, option_height)
	_apply_option_button_styles(btn)
	btn.pressed.connect(_on_option_selected.bind(index))
	return btn


func _lower_difficulty_if_struggling() -> void:
	var answered := maxi(questions_asked, 1)
	var wrong_rate := float(player_strikes) / float(answered)
	var is_struggling := player_strikes >= 2
	is_struggling = is_struggling or _consecutive_player_wrongs >= 2
	is_struggling = is_struggling or (questions_asked >= 1 and wrong_rate >= 0.5)
	if not is_struggling:
		return

	_difficulty_max = maxi(TriviaQuestionGenerator.DIFFICULTY_MIN, _difficulty_max - 1)


func _get_pick_difficulty_max() -> int:
	if _allows_extreme_questions():
		return TriviaQuestionGenerator.DIFFICULTY_EXTREME
	return _difficulty_max


func _allows_extreme_questions() -> bool:
	return _consecutive_player_corrects >= EXTREME_DIFFICULTY_STREAK


func _raise_difficulty_on_correct() -> void:
	_consecutive_player_corrects += 1
	_difficulty_max = mini(TriviaQuestionGenerator.DIFFICULTY_HARD, _difficulty_max + 1)


func _get_correct_answer_text(q: Dictionary) -> String:
	var ops: Array = q.get("ops", [])
	var correct_idx := int(q.get("ans", -1))
	if correct_idx < 0 or correct_idx >= ops.size():
		return ""
	return String(ops[correct_idx])


func _clear_round_feedback() -> void:
	if is_instance_valid(p1_correction_panel):
		p1_correction_panel.visible = false
	if is_instance_valid(p1_correction_label):
		p1_correction_label.text = ""
	if is_instance_valid(p1_footer_panel):
		p1_footer_panel.visible = false
	if is_instance_valid(p1_footer_player_label):
		p1_footer_player_label.text = "—"
	if is_instance_valid(p1_footer_enrique_label):
		p1_footer_enrique_label.text = "—"


func _show_correction_banner(correct_text: String) -> void:
	if correct_text.is_empty():
		p1_correction_label.text = "No se pudo determinar la respuesta correcta."
	else:
		p1_correction_label.text = "Respuesta correcta: %s" % correct_text
	p1_correction_panel.visible = true
	call_deferred("_layout_phase1_ui")


func _show_round_footer(player_won: bool, enrique_won: bool) -> void:
	p1_footer_player_label.text = "Acierto" if player_won else "Error"
	p1_footer_player_label.add_theme_color_override(
		"font_color",
		Color(0.45, 1.0, 0.55) if player_won else Color(1.0, 0.45, 0.45)
	)
	p1_footer_enrique_label.text = "Acierto" if enrique_won else "Error"
	p1_footer_enrique_label.add_theme_color_override(
		"font_color",
		Color(0.45, 1.0, 0.55) if enrique_won else Color(1.0, 0.45, 0.45)
	)
	p1_footer_panel.visible = true


func _highlight_option_buttons(selected_idx: int, correct_idx: int) -> void:
	var dim_style := _build_option_stylebox(
		Color(0.07, 0.09, 0.13, 0.5),
		Color(0.22, 0.28, 0.36, 0.4),
		1
	)
	var correct_style := _build_option_stylebox(
		Color(0.10, 0.28, 0.17, 0.92),
		Color(0.45, 1.0, 0.55, 0.95)
	)
	var wrong_style := _build_option_stylebox(
		Color(0.28, 0.11, 0.11, 0.92),
		Color(1.0, 0.45, 0.45, 0.95)
	)

	for i in range(p1_options.get_child_count()):
		var child := p1_options.get_child(i)
		if not child is Button:
			continue
		var btn := child as Button
		if i == correct_idx:
			btn.add_theme_stylebox_override("disabled", correct_style)
			btn.add_theme_color_override("font_disabled_color", Color(0.88, 1.0, 0.9))
		elif i == selected_idx:
			btn.add_theme_stylebox_override("disabled", wrong_style)
			btn.add_theme_color_override("font_disabled_color", Color(1.0, 0.82, 0.82))
		else:
			btn.add_theme_stylebox_override("disabled", dim_style)
			btn.add_theme_color_override("font_disabled_color", Color(0.58, 0.62, 0.68))


func _on_option_selected(idx: int) -> void:
	for child in p1_options.get_children():
		if child is BaseButton:
			(child as BaseButton).disabled = true

	var q := current_question
	if q.is_empty():
		return
	var correct_idx := int(q.get("ans", -1))
	var player_correct = idx == correct_idx
	var correct_text := _get_correct_answer_text(q)

	var time_taken = _time_elapsed - _step_start_time
	_step_start_time = _time_elapsed
	var feedback_delay := P1_FEEDBACK_DELAY_SEC

	if not player_correct:
		player_strikes += 1
		_consecutive_player_wrongs += 1
		_consecutive_player_corrects = 0
		p1_player_strikes.text = "Tus Strikes: %d/%d" % [player_strikes, STRIKE_LIMIT]
		_highlight_option_buttons(idx, correct_idx)
		_show_correction_banner(correct_text)
		_lower_difficulty_if_struggling()
		wrong_sound.play()
		feedback_delay = P1_WRONG_FEEDBACK_DELAY_SEC
		ScoreManager.record_minigame_step(false, "Respuesta incorrecta a la trivia", time_taken)
	else:
		_consecutive_player_wrongs = 0
		_raise_difficulty_on_correct()
		correct_sound.play()
		ScoreManager.record_minigame_step(true, "Respuesta correcta a la trivia", time_taken)

	var enrique_correct := randf() < ENRIQUE_CORRECT_CHANCE
	if not enrique_correct:
		enrique_strikes += 1
		p1_enrique_strikes.text = "Strikes de Enrique: %d/%d" % [enrique_strikes, STRIKE_LIMIT]

	_show_round_footer(player_correct, enrique_correct)

	questions_asked += 1

	await get_tree().create_timer(feedback_delay).timeout
	if _is_running:
		_next_question()


func _finish_trivia_outcome(result: String, success: bool, lives: int) -> void:
	_outcome_sequence(result, success, lives)


func _outcome_sequence(result: String, success: bool, lives: int) -> void:
	Global.last_minigame_outcome = {"game_id": "trivia", "result": result}
	Global.professor_challenge["last_trivia_result"] = result
	Global.professor_challenge["trivia_tied"] = result == "tie"
	if result != "tie":
		Global.professor_challenge["first_arc_complete"] = true
	Global.professor_challenge["show_enrique"] = true
	SaveManager.mark_dirty()

	var title := "Resultado"
	var subtitle := ""
	var accent := Color.WHITE
	match result:
		"win":
			title = "¡Victoria!"
			subtitle = "Ganaste la trivia contra Enrique."
			accent = Color(0.45, 1.0, 0.55)
		"loss":
			title = "Derrota"
			subtitle = "Enrique ganó la trivia esta vez."
			accent = Color(1.0, 0.45, 0.45)
		"tie":
			title = "¡Empate!"
			subtitle = "Nadie llegó a 3 strikes. Habla con el profesor para el desempate."
			accent = Color(1.0, 0.85, 0.35)

	await _present_trivia_outcome(title, subtitle, accent)
	if not _is_running:
		return

	var time_remaining := maxf(0.0, TIME_LIMIT_SEC - _time_elapsed)
	ScoreManager.record_minigame_result("trivia", success, lives, time_remaining)
	end(success)


func _present_trivia_outcome(title: String, subtitle: String, accent: Color) -> void:
	_clear_round_feedback()
	for child in p1_options.get_children():
		child.queue_free()

	p1_question.text = title
	p1_correction_title.text = "Fin de la trivia"
	p1_correction_title.add_theme_color_override("font_color", accent)
	p1_correction_label.text = subtitle
	p1_correction_panel.visible = true
	call_deferred("_layout_phase1_ui")
	await get_tree().create_timer(3.0).timeout


func _process(delta: float) -> void:
	if _is_running:
		_time_elapsed += delta

	if is_instance_valid(_loading_overlay) and _loading_overlay.visible:
		_loading_dot_timer += delta
		if _loading_dot_timer >= 0.35:
			_loading_dot_timer = 0.0
			_loading_dot_index = (_loading_dot_index + 1) % LOADING_DOTS.size()
			if is_instance_valid(_loading_dots_label):
				_loading_dots_label.text = LOADING_DOTS[_loading_dot_index]

	var vp_size := get_viewport().get_visible_rect().size

	if is_instance_valid(game_container):
		game_container.size = vp_size

	var is_active := func(c: Control) -> bool: return is_instance_valid(c) and c.visible
	var resize_container := func(c: Control) -> void:
		c.size = vp_size
		if c.get_child_count() > 0 and c.get_child(0) is ColorRect:
			(c.get_child(0) as ColorRect).size = vp_size

	[p1_container, _loading_overlay].filter(is_active).map(resize_container)

	if is_instance_valid(p1_container) and p1_container.visible:
		_layout_phase1_ui()
