extends MiniGameBase

const QUESTION_COUNT: int = 4
const STRIKE_LIMIT: int = 3
const TIME_LIMIT_SEC: float = 120.0
const LOADING_DOTS: Array[String] = ["", ".", "..", "..."]
const P1_MARGIN_X: float = 40.0
const P1_HEADER_HEIGHT: float = 118.0
const P1_STATUS_RESERVE: float = 100.0
const P1_OPTION_FONT_SIZE: int = 16
const P1_OPTION_SEPARATION: int = 10
const QUESTIONS_LOAD_TIMEOUT_SEC: float = 15.0

# === UI Nodes ===
var _loading_overlay: Control
var _loading_label: Label
var _loading_dots_label: Label
var _loading_dot_timer: float = 0.0
var _loading_dot_index: int = 0

var p1_container: Control
var p1_question: Label
var p1_options: VBoxContainer
var p1_player_strikes: Label
var p1_enrique_strikes: Label
var p1_status: Label
var p1_source_label: Label
var _using_fallback_questions: bool = false
var _questions_resolved: bool = false

var p2_container: Control
var p2_title: Label
var p2_status: Label
var p2_grid: GridContainer
var wordle_labels: Array = []

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
var current_q_index: int = -1

# === State Phase 2 (Wordle) ===
var is_phase_2: bool = false
var wordle_words: Array = ["VENDA", "SALUD", "DOLOR", "GOLPE", "CURAR", "PULSO", "CORTE", "SANAR", "VIRUS", "HUESO", "TOSER", "DOSIS", "SUDOR", "GRIPE", "VITAL", "CIEGO", "SORDO", "AGUJA", "VENAS", "RENAL", "GOTAS", "SUERO", "PARTO", "MUELA", "CALOR", "CREMA", "VISTA", "TACTO"]
var target_word: String = ""
var current_guess: String = ""
var current_attempt: int = 0
var p2_round: int = 1
var player_w_wins: int = 0
var enrique_w_wins: int = 0

var _time_elapsed: float = 0.0
var _step_start_time: float = 0.0

var questions: Array[Dictionary] = []

func _ready() -> void:
	super._ready()
	if background:
		background.hide()
	_build_ui()
	wordle_words.shuffle()

	bgm = _create_audio(preload("res://src/assets/sounds/Quiz_BACKGROUND_MUSIC.mp3"), -8.0)
	bgm.play()
	bgm.finished.connect(bgm.play)

	correct_sound = _create_audio(preload("res://src/assets/sounds/correct.wav"))
	wrong_sound = _create_audio(preload("res://src/assets/sounds/wrong.wav"))
	step_sound = _create_audio(preload("res://src/assets/sounds/step.wav"))
	success_fanfare = _create_audio(preload("res://src/assets/sounds/success_fanfare.wav"))
	fail_sound = _create_audio(preload("res://src/assets/sounds/fail_sound.wav"))

func start() -> void:
	if _is_running:
		return
	_is_running = true
	process_mode = Node.PROCESS_MODE_ALWAYS
	show()
	_show_loading(true)
	_questions_resolved = false
	_arm_questions_load_timeout()
	TriviaQuestionGenerator.fetch_questions(QUESTION_COUNT, _on_questions_ready)


func _arm_questions_load_timeout() -> void:
	get_tree().create_timer(QUESTIONS_LOAD_TIMEOUT_SEC).timeout.connect(_on_questions_load_timeout)


func _on_questions_load_timeout() -> void:
	if _questions_resolved or not _is_running:
		return
	if not is_instance_valid(_loading_overlay) or not _loading_overlay.visible:
		return
	_on_questions_ready(TriviaQuestionGenerator.get_fallback_questions(QUESTION_COUNT), true)


func _on_questions_ready(questions_data: Array, used_fallback: bool) -> void:
	if not _is_running or _questions_resolved:
		return
	_questions_resolved = true
	_using_fallback_questions = used_fallback
	questions.clear()
	for item: Variant in questions_data:
		if typeof(item) == TYPE_DICTIONARY:
			questions.append(item as Dictionary)
	_reset_phase1_state()
	_update_source_label()
	_show_loading(false)
	if questions.is_empty():
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
	current_q_index = -1
	if is_instance_valid(p1_player_strikes):
		p1_player_strikes.text = "Tus Strikes: 0/%d" % STRIKE_LIMIT
	if is_instance_valid(p1_enrique_strikes):
		p1_enrique_strikes.text = "Strikes de Enrique: 0/%d" % STRIKE_LIMIT
	if is_instance_valid(p1_status):
		p1_status.text = ""


func _update_source_label() -> void:
	if not is_instance_valid(p1_source_label):
		return
	if _using_fallback_questions:
		p1_source_label.text = "Fuente: preguntas predeterminadas"
		p1_source_label.add_theme_color_override("font_color", Color(1.0, 0.72, 0.35))
	else:
		p1_source_label.text = "Fuente: preguntas generadas por IA"
		p1_source_label.add_theme_color_override("font_color", Color(0.4, 0.9, 0.9))


func _show_loading(is_loading: bool) -> void:
	if not is_instance_valid(_loading_overlay):
		return
	_loading_overlay.visible = is_loading
	if is_instance_valid(p1_container):
		p1_container.visible = not is_loading
	if is_instance_valid(p2_container):
		p2_container.visible = false
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

func _create_label(parent: Node, text: String, font_size: int = -1, color: Color = Color.WHITE, align: int = HORIZONTAL_ALIGNMENT_CENTER) -> Label:
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
	
	p1_question = _create_label(p1_container, "Pregunta...", 20)
	p1_question.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	p1_question.set_anchors_preset(Control.PRESET_TOP_WIDE)

	p1_status = _create_label(p1_container, "", -1)
	p1_status.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	p1_status.offset_top = -100
	p1_status.offset_bottom = -50

	p1_source_label = _create_label(p1_container, "", 13, Color(0.7, 0.7, 0.7), HORIZONTAL_ALIGNMENT_LEFT)
	p1_source_label.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	p1_source_label.offset_left = P1_MARGIN_X
	p1_source_label.offset_top = -52
	p1_source_label.offset_right = 420
	p1_source_label.offset_bottom = -24

	p1_options = VBoxContainer.new()
	p1_options.z_index = 1
	p1_options.add_theme_constant_override("separation", P1_OPTION_SEPARATION)
	p1_container.add_child(p1_options)

	# ================= PHASE 2 UI =================
	p2_container = Control.new()
	game_container.add_child(p2_container)
	p2_container.visible = false
	p2_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	var p2_bg = ColorRect.new()
	p2_container.add_child(p2_bg)
	p2_bg.color = Color(0.1, 0.1, 0.2, 0.95)
	p2_bg.set_anchors_preset(Control.PRESET_FULL_RECT)

	var p2_center := CenterContainer.new()
	p2_center.set_anchors_preset(Control.PRESET_FULL_RECT)
	p2_container.add_child(p2_center)

	var p2_content := VBoxContainer.new()
	p2_content.alignment = BoxContainer.ALIGNMENT_CENTER
	p2_content.add_theme_constant_override("separation", 20)
	p2_center.add_child(p2_content)

	p2_title = _create_label(p2_content, "DESEMPATE WORDLE - RONDA 1/3", 28, Color.YELLOW)

	p2_status = _create_label(p2_content, "Escribe una palabra de 5 letras (Teclado Real)", 18)

	p2_grid = GridContainer.new()
	p2_content.add_child(p2_grid)
	p2_grid.columns = 5
	p2_grid.add_theme_constant_override("h_separation", 10)
	p2_grid.add_theme_constant_override("v_separation", 10)
	
	for i in range(30):
		var panel = PanelContainer.new()
		panel.custom_minimum_size = Vector2(64, 60)
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.2, 0.2, 0.2)
		style.border_width_bottom = 2
		style.border_width_top = 2
		style.border_width_left = 2
		style.border_width_right = 2
		style.border_color = Color(0.5, 0.5, 0.5)
		panel.add_theme_stylebox_override("panel", style)
		
		var lbl = _create_label(panel, "", 32)
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		
		p2_grid.add_child(panel)
		wordle_labels.append({"panel": panel, "label": lbl, "style": style})

func _next_question() -> void:
	if player_strikes >= STRIKE_LIMIT:
		var time_remaining := maxf(0.0, TIME_LIMIT_SEC - _time_elapsed)
		ScoreManager.record_minigame_result("trivia", false, 0, time_remaining)
		end(false)
		return
	if enrique_strikes >= STRIKE_LIMIT:
		var time_remaining := maxf(0.0, TIME_LIMIT_SEC - _time_elapsed)
		ScoreManager.record_minigame_result("trivia", true, STRIKE_LIMIT - player_strikes, time_remaining)
		end(true)
		return

	if questions_asked >= QUESTION_COUNT:
		_start_phase_2()
		return
		
	current_q_index = (current_q_index + 1) % questions.size()
	var q = questions[current_q_index]
	
	p1_question.text = "Pregunta %d: %s" % [(questions_asked + 1), q["q"]]
	_step_start_time = _time_elapsed

	for child in p1_options.get_children():
		child.queue_free()

	var ops: Array = q.get("ops", [])
	for i in range(ops.size()):
		p1_options.add_child(_create_option_button(String(ops[i]), i))

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
	var options_height := _measure_options_block_height(content_width)
	var question_height := _measure_label_height(p1_question, content_width)
	var block_height := question_height + 16.0 + options_height
	var area_top := P1_HEADER_HEIGHT
	var area_bottom := vp_size.y - P1_STATUS_RESERVE
	var block_top := area_top + maxf(0.0, (area_bottom - area_top - block_height) * 0.5)

	p1_question.set_anchors_preset(Control.PRESET_TOP_LEFT)
	p1_question.position = Vector2(P1_MARGIN_X, block_top)
	p1_question.size = Vector2(content_width, question_height)

	p1_options.position = Vector2(P1_MARGIN_X, block_top + question_height + 16.0)
	p1_options.size = Vector2(content_width, maxf(options_height, 48.0))


func _measure_options_block_height(content_width: float) -> float:
	var total_height := 0.0
	var is_first := true
	for child in p1_options.get_children():
		if child is Button:
			if not is_first:
				total_height += P1_OPTION_SEPARATION
			is_first = false
			_resize_option_button(child as Button, content_width)
			total_height += (child as Button).custom_minimum_size.y
	return total_height


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


func _resize_option_button(btn: Button, content_width: float) -> void:
	var text_height := _measure_option_text_height(btn.text, content_width - 32.0)
	var option_height := maxf(48.0, text_height + 24.0)
	btn.custom_minimum_size = Vector2(content_width, option_height)


func _create_option_button(option_text: String, index: int) -> Button:
	var width := _get_p1_content_width()
	var text_height := _measure_option_text_height(option_text, width - 32.0)
	var option_height := maxf(48.0, text_height + 24.0)

	var btn := Button.new()
	btn.text = option_text
	btn.add_theme_font_size_override("font_size", P1_OPTION_FONT_SIZE)
	btn.custom_minimum_size = Vector2(width, option_height)
	btn.pressed.connect(_on_option_selected.bind(index))
	return btn


func _on_option_selected(idx: int) -> void:
	for child in p1_options.get_children():
		if child is BaseButton:
			(child as BaseButton).disabled = true
		
	var q = questions[current_q_index]
	var player_correct = (idx == q["ans"])
	
	var time_taken = _time_elapsed - _step_start_time
	_step_start_time = _time_elapsed
	
	if not player_correct:
		player_strikes += 1
		p1_player_strikes.text = "Tus Strikes: %d/%d" % [player_strikes, STRIKE_LIMIT]
		p1_status.text = "¡Incorrecto!"
		wrong_sound.play()
		ScoreManager.record_minigame_step(false, "Respuesta incorrecta a la trivia", time_taken)
	else:
		p1_status.text = "¡Correcto!"
		correct_sound.play()
		ScoreManager.record_minigame_step(true, "Respuesta correcta a la trivia", time_taken)
		
	var enrique_correct = randf() < 0.75
	if not enrique_correct:
		enrique_strikes += 1
		p1_enrique_strikes.text = "Strikes de Enrique: %d/%d" % [enrique_strikes, STRIKE_LIMIT]
		p1_status.text += " | ¡Enrique falló!"
	else:
		p1_status.text += " | Enrique acertó."
		
	questions_asked += 1
	
	await get_tree().create_timer(2.0).timeout
	if _is_running:
		_next_question()

# ================= PHASE 2 WORDLE =================

func _start_phase_2() -> void:
	is_phase_2 = true
	p1_container.visible = false
	p2_container.visible = true
	p2_round = 1
	player_w_wins = 0
	enrique_w_wins = 0
	_setup_wordle_round()

func _setup_wordle_round() -> void:
	if p2_round > 3:
		_end_phase_2()
		return
		
	p2_title.text = "DESEMPATE WORDLE - RONDA %d/3" % p2_round
	p2_status.text = "Escribe una palabra de 5 letras (Tú: %d | Enrique: %d)" % [player_w_wins, enrique_w_wins]
	p2_status.add_theme_color_override("font_color", Color.WHITE)
	target_word = wordle_words[(p2_round - 1) % wordle_words.size()]
	current_guess = ""
	current_attempt = 0
	
	for w_dict in wordle_labels:
		w_dict["label"].text = ""
		w_dict["style"].bg_color = Color(0.2, 0.2, 0.2)
		
	_step_start_time = _time_elapsed

func _unhandled_key_input(event: InputEvent) -> void:
	if not is_phase_2 or not _is_running or not event is InputEventKey or not event.pressed:
		return
		
	if event.keycode == KEY_BACKSPACE and current_guess.length() > 0:
		current_guess = current_guess.substr(0, current_guess.length() - 1)
		_update_grid_text()
	elif event.keycode == KEY_ENTER and current_guess.length() == 5:
		_submit_guess()
	elif current_guess.length() < 5:
		var chr = OS.get_keycode_string(event.keycode)
		if chr.length() == 1 and chr >= "A" and chr <= "Z":
			current_guess += chr
			step_sound.play()
			_update_grid_text()

func _update_grid_text() -> void:
	var start_idx = current_attempt * 5
	for i in range(5):
		wordle_labels[start_idx + i]["label"].text = current_guess[i] if i < current_guess.length() else ""

func _submit_guess() -> void:
	var start_idx = current_attempt * 5
	var is_correct = current_guess == target_word
	var used_indices = []
	
	for i in range(5):
		var is_exact = current_guess[i] == target_word[i]
		wordle_labels[start_idx + i]["style"].bg_color = Color(0.2, 0.6, 0.2) if is_exact else Color(0.3, 0.3, 0.3)
		if is_exact: used_indices.append(i)
	
	for i in range(5):
		if current_guess[i] != target_word[i]:
			for j in range(5):
				if current_guess[i] == target_word[j] and not j in used_indices:
					wordle_labels[start_idx + i]["style"].bg_color = Color(0.7, 0.6, 0.1)
					used_indices.append(j)
					break
	
	current_attempt += 1
	var time_taken = _time_elapsed - _step_start_time
	_step_start_time = _time_elapsed
	
	if is_correct:
		ScoreManager.record_minigame_step(true, "Acierto Wordle", time_taken)
		_round_over(true)
	elif current_attempt >= 6:
		ScoreManager.record_minigame_step(false, "Fallo Wordle", time_taken)
		_round_over(false)
		
	current_guess = ""

func _round_over(player_won: bool) -> void:
	# Simulamos el turno de Enrique (35% de ganar)
	var enrique_won = randf() < 0.35
	
	if player_won:
		player_w_wins += 1
		p2_status.text = "¡Adivinaste la palabra! "
		p2_status.add_theme_color_override("font_color", Color.GREEN)
		correct_sound.play()
	else:
		p2_status.text = "Fallaste. La palabra era %s. " % target_word
		p2_status.add_theme_color_override("font_color", Color.RED)
		wrong_sound.play()
		
	if enrique_won:
		enrique_w_wins += 1
		p2_status.text += "Enrique adivinó la suya."
	else:
		p2_status.text += "Enrique también falló."
		
	await get_tree().create_timer(3.0).timeout
	p2_round += 1
	if _is_running:
		_setup_wordle_round()

func _end_phase_2() -> void:
	if player_w_wins > enrique_w_wins:
		p2_title.text = "¡GANASTE EL DESEMPATE!"
		p2_title.add_theme_color_override("font_color", Color.GREEN)
		p2_status.text = "Tú: %d | Enrique: %d" % [player_w_wins, enrique_w_wins]
		success_fanfare.play()
		await get_tree().create_timer(3.0).timeout
		var time_remaining := maxf(0.0, TIME_LIMIT_SEC - _time_elapsed)
		ScoreManager.record_minigame_result("trivia", true, STRIKE_LIMIT - player_strikes, time_remaining)
		end(true)
	elif enrique_w_wins > player_w_wins:
		p2_title.text = "ENRIQUE GANÓ EL DESEMPATE"
		p2_title.add_theme_color_override("font_color", Color.RED)
		p2_status.text = "Tú: %d | Enrique: %d" % [player_w_wins, enrique_w_wins]
		fail_sound.play()
		await get_tree().create_timer(3.0).timeout
		var time_remaining := maxf(0.0, TIME_LIMIT_SEC - _time_elapsed)
		ScoreManager.record_minigame_result("trivia", false, 0, time_remaining)
		end(false)
	else:
		# Empate, repetimos la ronda 3
		p2_status.text = "¡Empate! Ronda de muerte súbita."
		p2_round -= 1
		await get_tree().create_timer(2.0).timeout
		_setup_wordle_round()

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

	[p1_container, p2_container, _loading_overlay].filter(is_active).map(resize_container)

	if is_instance_valid(p1_container) and p1_container.visible:
		_layout_phase1_ui()
