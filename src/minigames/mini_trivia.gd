extends MiniGameBase

# === UI Nodes ===
var p1_container: Control
var p1_question: Label
var p1_options: VBoxContainer
var p1_player_strikes: Label
var p1_enrique_strikes: Label
var p1_status: Label

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

var questions: Array = [
	{"q": "¿Qué hacer ante una quemadura leve?", "ops": ["Aplicar hielo directo", "Echar agua fría por 10 min", "Poner pasta dental", "Reventar ampollas"], "ans": 1},
	{"q": "¿Cuántas compresiones en RCP?", "ops": ["30 y 2 ventilaciones", "15 y 1", "100 seguidas", "20 y 5"], "ans": 0},
	{"q": "Si alguien se atraganta y no tose...", "ops": ["Darle agua", "Maniobra de Heimlich", "Golpear la espalda acostado", "Esperar a que tosa"], "ans": 1},
	{"q": "¿Cuál es el número de emergencias?", "ops": ["911", "112", "171", "Todas las anteriores (depende del país/región)"], "ans": 3},
	{"q": "Para una hemorragia severa se debe...", "ops": ["Aplicar un torniquete flojo", "Lavar con alcohol", "Presión directa en la herida", "Dar aspirina"], "ans": 2},
	{"q": "¿Qué hacer si alguien sufre un desmayo?", "ops": ["Levantarlo rápido", "Elevar sus piernas", "Echarle agua fría", "Darle a oler alcohol"], "ans": 1},
]

func _ready() -> void:
	super._ready()
	if background:
		background.hide()
	_build_ui()
	questions.shuffle()
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
	super.start()
	_next_question()

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

func _set_center(node: Control, width: float, height: float, y_offset: float = 0) -> void:
	node.set_anchors_preset(Control.PRESET_CENTER)
	node.position = Vector2(-width / 2.0, -height / 2.0 + y_offset)
	node.size = Vector2(width, height)

func _build_ui() -> void:
	# ================= PHASE 1 UI =================
	p1_container = Control.new()
	game_container.add_child(p1_container)
	p1_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	var panel_bg = ColorRect.new()
	p1_container.add_child(panel_bg)
	panel_bg.color = Color(0, 0, 0, 0.8)
	panel_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	var title = _create_label(p1_container, "TRIVIA MÉDICA: TÚ VS ENRIQUE", 24)
	_set_top_wide(title, 20, 40)
	
	p1_player_strikes = _create_label(p1_container, "Tus Strikes: 0/3", -1, Color.AQUA, HORIZONTAL_ALIGNMENT_LEFT)
	p1_player_strikes.set_anchors_preset(Control.PRESET_TOP_LEFT)
	p1_player_strikes.position = Vector2(48, 66)
	p1_player_strikes.size = Vector2(320, 42)
	
	p1_enrique_strikes = _create_label(p1_container, "Strikes de Enrique: 0/3", -1, Color.ORANGE, HORIZONTAL_ALIGNMENT_RIGHT)
	p1_enrique_strikes.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	p1_enrique_strikes.position = Vector2(-368, 66)
	p1_enrique_strikes.size = Vector2(320, 42)
	
	p1_question = _create_label(p1_container, "Pregunta...", 20)
	p1_question.autowrap_mode = TextServer.AUTOWRAP_WORD
	_set_top_wide(p1_question, 110, 80)
	
	p1_options = VBoxContainer.new()
	p1_container.add_child(p1_options)
	p1_options.add_theme_constant_override("separation", 15)
	_set_center(p1_options, 672, 240, 48)
	
	p1_status = _create_label(p1_container, "", -1)
	p1_status.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	p1_status.offset_top = -100
	p1_status.offset_bottom = -50
	
	# ================= PHASE 2 UI =================
	p2_container = Control.new()
	game_container.add_child(p2_container)
	p2_container.visible = false
	p2_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	var p2_bg = ColorRect.new()
	p2_container.add_child(p2_bg)
	p2_bg.color = Color(0.1, 0.1, 0.2, 0.95)
	p2_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	p2_title = _create_label(p2_container, "DESEMPATE WORDLE - RONDA 1/3", 28, Color.YELLOW)
	_set_top_wide(p2_title, 30, 40)
	
	p2_status = _create_label(p2_container, "Escribe una palabra de 5 letras (Teclado Real)", 18)
	_set_top_wide(p2_status, 80, 30)
	
	p2_grid = GridContainer.new()
	p2_container.add_child(p2_grid)
	p2_grid.columns = 5
	p2_grid.add_theme_constant_override("h_separation", 10)
	p2_grid.add_theme_constant_override("v_separation", 10)
	_set_center(p2_grid, 480, 336, 36) # Approx 5 cols of 60px+10px, 6 rows of 60px+10px, shifted down
	
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
	if player_strikes >= 3:
		var time_remaining = max(0.0, 120.0 - _time_elapsed)
		ScoreManager.record_minigame_result("trivia", false, 0, time_remaining)
		end(false)
		return
	if enrique_strikes >= 3:
		var time_remaining = max(0.0, 120.0 - _time_elapsed)
		ScoreManager.record_minigame_result("trivia", true, 3 - player_strikes, time_remaining)
		end(true)
		return
		
	if questions_asked >= 4:
		_start_phase_2()
		return
		
	current_q_index = (current_q_index + 1) % questions.size()
	var q = questions[current_q_index]
	
	p1_question.text = "Pregunta %d: %s" % [(questions_asked + 1), q["q"]]
	_step_start_time = _time_elapsed
	
	for child in p1_options.get_children():
		child.queue_free()
		
	for i in range(q["ops"].size()):
		var btn = Button.new()
		btn.text = q["ops"][i]
		btn.add_theme_font_size_override("font_size", 18)
		btn.custom_minimum_size = Vector2(672, 48)
		btn.pressed.connect(_on_option_selected.bind(i))
		p1_options.add_child(btn)

func _on_option_selected(idx: int) -> void:
	for child in p1_options.get_children():
		child.disabled = true
		
	var q = questions[current_q_index]
	var player_correct = (idx == q["ans"])
	
	var time_taken = _time_elapsed - _step_start_time
	_step_start_time = _time_elapsed
	
	if not player_correct:
		player_strikes += 1
		p1_player_strikes.text = "Tus Strikes: %d/3" % player_strikes
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
		p1_enrique_strikes.text = "Strikes de Enrique: %d/3" % enrique_strikes
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
		var time_remaining = max(0.0, 120.0 - _time_elapsed)
		ScoreManager.record_minigame_result("trivia", true, 3 - player_strikes, time_remaining)
		end(true)
	elif enrique_w_wins > player_w_wins:
		p2_title.text = "ENRIQUE GANÓ EL DESEMPATE"
		p2_title.add_theme_color_override("font_color", Color.RED)
		p2_status.text = "Tú: %d | Enrique: %d" % [player_w_wins, enrique_w_wins]
		fail_sound.play()
		await get_tree().create_timer(3.0).timeout
		var time_remaining = max(0.0, 120.0 - _time_elapsed)
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
		
	var vp_size = get_viewport().get_visible_rect().size
	
	if is_instance_valid(game_container):
		game_container.size = vp_size
		
	var is_active = func(c): return is_instance_valid(c) and c.visible
	var resize_container = func(c):
		c.size = vp_size
		if c.get_child_count() > 0 and c.get_child(0) is ColorRect:
			c.get_child(0).size = vp_size

	[p1_container, p2_container].filter(is_active).map(resize_container)
