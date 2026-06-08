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

	bgm = AudioStreamPlayer.new()
	bgm.stream = preload("res://src/assets/sounds/Quiz_BACKGROUND_MUSIC.mp3")
	bgm.volume_db = -8.0
	game_container.add_child(bgm)
	bgm.play()
	bgm.finished.connect(func(): bgm.play())

	correct_sound = AudioStreamPlayer.new()
	correct_sound.stream = preload("res://src/assets/sounds/correct.wav")
	game_container.add_child(correct_sound)

	wrong_sound = AudioStreamPlayer.new()
	wrong_sound.stream = preload("res://src/assets/sounds/wrong.wav")
	game_container.add_child(wrong_sound)

	step_sound = AudioStreamPlayer.new()
	step_sound.stream = preload("res://src/assets/sounds/step.wav")
	game_container.add_child(step_sound)

	success_fanfare = AudioStreamPlayer.new()
	success_fanfare.stream = preload("res://src/assets/sounds/success_fanfare.wav")
	game_container.add_child(success_fanfare)

	fail_sound = AudioStreamPlayer.new()
	fail_sound.stream = preload("res://src/assets/sounds/fail_sound.wav")
	game_container.add_child(fail_sound)

func start() -> void:
	super.start()
	_next_question()

# Helper Functions for guaranteed absolute anchor/offset scaling
func _set_full_rect(node: Control) -> void:
	node.anchor_left = 0
	node.anchor_right = 1
	node.anchor_top = 0
	node.anchor_bottom = 1
	node.offset_left = 0
	node.offset_right = 0
	node.offset_top = 0
	node.offset_bottom = 0

func _set_top_wide(node: Control, top_y: float, height: float) -> void:
	node.anchor_left = 0
	node.anchor_right = 1
	node.anchor_top = 0
	node.anchor_bottom = 0
	node.offset_left = 0
	node.offset_right = 0
	node.offset_top = top_y
	node.offset_bottom = top_y + height

func _set_center(node: Control, width: float, height: float, y_offset: float = 0) -> void:
	node.anchor_left = 0.5
	node.anchor_right = 0.5
	node.anchor_top = 0.5
	node.anchor_bottom = 0.5
	node.offset_left = -width / 2.0
	node.offset_right = width / 2.0
	node.offset_top = (-height / 2.0) + y_offset
	node.offset_bottom = (height / 2.0) + y_offset

func _build_ui() -> void:
	# ================= PHASE 1 UI =================
	p1_container = Control.new()
	game_container.add_child(p1_container)
	_set_full_rect(p1_container)
	
	var panel_bg = ColorRect.new()
	p1_container.add_child(panel_bg)
	panel_bg.color = Color(0, 0, 0, 0.8)
	_set_full_rect(panel_bg)
	
	var title = Label.new()
	p1_container.add_child(title)
	title.text = "TRIVIA MÉDICA: TÚ VS ENRIQUE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	_set_top_wide(title, 20, 40)
	
	p1_player_strikes = Label.new()
	p1_container.add_child(p1_player_strikes)
	p1_player_strikes.text = "Tus Strikes: 0/3"
	p1_player_strikes.add_theme_color_override("font_color", Color.AQUA)
	# Top Left anchor
	p1_player_strikes.anchor_left = 0
	p1_player_strikes.anchor_right = 0
	p1_player_strikes.anchor_top = 0
	p1_player_strikes.anchor_bottom = 0
	p1_player_strikes.offset_left = 50
	p1_player_strikes.offset_top = 70
	p1_player_strikes.offset_right = 300
	p1_player_strikes.offset_bottom = 110
	
	p1_enrique_strikes = Label.new()
	p1_container.add_child(p1_enrique_strikes)
	p1_enrique_strikes.text = "Strikes de Enrique: 0/3"
	p1_enrique_strikes.add_theme_color_override("font_color", Color.ORANGE)
	p1_enrique_strikes.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	# Top Right anchor
	p1_enrique_strikes.anchor_left = 1
	p1_enrique_strikes.anchor_right = 1
	p1_enrique_strikes.anchor_top = 0
	p1_enrique_strikes.anchor_bottom = 0
	p1_enrique_strikes.offset_left = -300
	p1_enrique_strikes.offset_top = 70
	p1_enrique_strikes.offset_right = -50
	p1_enrique_strikes.offset_bottom = 110
	
	p1_question = Label.new()
	p1_container.add_child(p1_question)
	p1_question.text = "Pregunta..."
	p1_question.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	p1_question.autowrap_mode = TextServer.AUTOWRAP_WORD
	p1_question.add_theme_font_size_override("font_size", 20)
	_set_top_wide(p1_question, 110, 80)
	
	p1_options = VBoxContainer.new()
	p1_container.add_child(p1_options)
	p1_options.add_theme_constant_override("separation", 15)
	_set_center(p1_options, 500, 300, 60)
	
	p1_status = Label.new()
	p1_container.add_child(p1_status)
	p1_status.text = ""
	p1_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	# Bottom Wide anchor
	p1_status.anchor_left = 0
	p1_status.anchor_right = 1
	p1_status.anchor_top = 1
	p1_status.anchor_bottom = 1
	p1_status.offset_left = 0
	p1_status.offset_right = 0
	p1_status.offset_top = -100
	p1_status.offset_bottom = -50
	
	# ================= PHASE 2 UI =================
	p2_container = Control.new()
	game_container.add_child(p2_container)
	p2_container.visible = false
	_set_full_rect(p2_container)
	
	var p2_bg = ColorRect.new()
	p2_container.add_child(p2_bg)
	p2_bg.color = Color(0.1, 0.1, 0.2, 0.95)
	_set_full_rect(p2_bg)
	
	p2_title = Label.new()
	p2_container.add_child(p2_title)
	p2_title.text = "DESEMPATE WORDLE - RONDA 1/3"
	p2_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	p2_title.add_theme_font_size_override("font_size", 28)
	p2_title.add_theme_color_override("font_color", Color.YELLOW)
	_set_top_wide(p2_title, 30, 40)
	
	p2_status = Label.new()
	p2_container.add_child(p2_status)
	p2_status.text = "Escribe una palabra de 5 letras (Teclado Real)"
	p2_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	p2_status.add_theme_font_size_override("font_size", 18)
	_set_top_wide(p2_status, 80, 30)
	
	p2_grid = GridContainer.new()
	p2_container.add_child(p2_grid)
	p2_grid.columns = 5
	p2_grid.add_theme_constant_override("h_separation", 10)
	p2_grid.add_theme_constant_override("v_separation", 10)
	_set_center(p2_grid, 340, 410, 50) # Approx 5 cols of 60px+10px, 6 rows of 60px+10px, shifted down
	
	for i in range(30):
		var panel = PanelContainer.new()
		panel.custom_minimum_size = Vector2(60, 60)
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.2, 0.2, 0.2)
		style.border_width_bottom = 2
		style.border_width_top = 2
		style.border_width_left = 2
		style.border_width_right = 2
		style.border_color = Color(0.5, 0.5, 0.5)
		panel.add_theme_stylebox_override("panel", style)
		
		var lbl = Label.new()
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 32)
		panel.add_child(lbl)
		
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
		btn.custom_minimum_size = Vector2(500, 45)
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
	if not is_phase_2 or not _is_running:
		return
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_BACKSPACE:
			if current_guess.length() > 0:
				current_guess = current_guess.substr(0, current_guess.length() - 1)
				_update_grid_text()
		elif event.keycode == KEY_ENTER:
			if current_guess.length() == 5:
				_submit_guess()
		else:
			var chr = OS.get_keycode_string(event.keycode)
			if chr.length() == 1 and current_guess.length() < 5:
				var regex = RegEx.new()
				regex.compile("^[A-Z]$")
				if regex.search(chr):
					current_guess += chr
					step_sound.play()
					_update_grid_text()

func _update_grid_text() -> void:
	var start_idx = current_attempt * 5
	for i in range(5):
		var lbl = wordle_labels[start_idx + i]["label"]
		if i < current_guess.length():
			lbl.text = current_guess[i]
		else:
			lbl.text = ""

func _submit_guess() -> void:
	var start_idx = current_attempt * 5
	
	var exact_matches = 0
	var used_indices = []
	
	# First pass: Green
	for i in range(5):
		var style = wordle_labels[start_idx + i]["style"]
		if current_guess[i] == target_word[i]:
			style.bg_color = Color(0.2, 0.6, 0.2) # Green
			exact_matches += 1
			used_indices.append(i)
		else:
			style.bg_color = Color(0.3, 0.3, 0.3) # Gray
	
	# Second pass: Yellow
	for i in range(5):
		if current_guess[i] != target_word[i]:
			for j in range(5):
				if current_guess[i] == target_word[j] and j not in used_indices:
					wordle_labels[start_idx + i]["style"].bg_color = Color(0.7, 0.6, 0.1) # Yellow
					used_indices.append(j)
					break
	
	current_attempt += 1
	current_guess = ""
	
	var time_taken = _time_elapsed - _step_start_time
	_step_start_time = _time_elapsed
	
	if exact_matches == 5:
		ScoreManager.record_minigame_step(true, "Acierto Wordle", time_taken)
		_round_over(true)
	elif current_attempt >= 6:
		ScoreManager.record_minigame_step(false, "Fallo Wordle", time_taken)
		_round_over(false)

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
	if is_instance_valid(p1_container) and p1_container.visible:
		p1_container.size = vp_size
		if p1_container.get_child_count() > 0 and p1_container.get_child(0) is ColorRect:
			p1_container.get_child(0).size = vp_size
	if is_instance_valid(p2_container) and p2_container.visible:
		p2_container.size = vp_size
		if p2_container.get_child_count() > 0 and p2_container.get_child(0) is ColorRect:
			p2_container.get_child(0).size = vp_size
