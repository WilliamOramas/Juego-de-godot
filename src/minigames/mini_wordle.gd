extends MiniGameBase

const TIME_LIMIT_SEC: float = 120.0
const ENRIQUE_WIN_CHANCE: float = 0.35

var p2_container: Control
var p2_title: Label
var p2_status: Label
var p2_grid: GridContainer
var wordle_labels: Array = []

var bgm: AudioStreamPlayer
var correct_sound: AudioStreamPlayer
var wrong_sound: AudioStreamPlayer
var step_sound: AudioStreamPlayer
var success_fanfare: AudioStreamPlayer
var fail_sound: AudioStreamPlayer

var wordle_words: Array = [
	"VENDA", "SALUD", "DOLOR", "GOLPE", "CURAR", "PULSO", "CORTE", "SANAR", "VIRUS", "HUESO",
	"TOSER", "DOSIS", "SUDOR", "GRIPE", "VITAL", "CIEGO", "SORDO", "AGUJA", "VENAS", "RENAL",
	"GOTAS", "SUERO", "PARTO", "MUELA", "CALOR", "CREMA", "VISTA", "TACTO",
]
var target_word: String = ""
var current_guess: String = ""
var current_attempt: int = 0
var p2_round: int = 1
var player_w_wins: int = 0
var enrique_w_wins: int = 0

var _time_elapsed: float = 0.0
var _step_start_time: float = 0.0


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
	p2_round = 1
	player_w_wins = 0
	enrique_w_wins = 0
	p2_container.visible = true
	_setup_wordle_round()
	_enter_paused_play()


func _enter_paused_play() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	get_tree().paused = true
	if background:
		var tween := create_tween()
		tween.tween_property(background, "modulate:a", 0.5, 0.15)


func _create_audio(stream: AudioStream, volume: float = 0.0) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = volume
	game_container.add_child(player)
	return player


func _create_label(
	parent: Node,
	text: String,
	font_size: int = -1,
	color: Color = Color.WHITE,
	align: int = HORIZONTAL_ALIGNMENT_CENTER
) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.horizontal_alignment = align
	if font_size > 0:
		lbl.add_theme_font_size_override("font_size", font_size)
	if color != Color.WHITE:
		lbl.add_theme_color_override("font_color", color)
	parent.add_child(lbl)
	return lbl


func _build_ui() -> void:
	p2_container = Control.new()
	game_container.add_child(p2_container)
	p2_container.set_anchors_preset(Control.PRESET_FULL_RECT)

	var p2_bg := ColorRect.new()
	p2_container.add_child(p2_bg)
	p2_bg.color = Color(0.1, 0.1, 0.2, 0.95)
	p2_bg.set_anchors_preset(Control.PRESET_FULL_RECT)

	var p2_center := CenterContainer.new()
	p2_center.set_anchors_preset(Control.PRESET_FULL_RECT)
	p2_container.add_child(p2_center)

	var p2_content := VBoxContainer.new()
	p2_content.alignment = BoxContainer.ALIGNMENT_CENTER
	p2_content.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	p2_content.add_theme_constant_override("separation", 20)
	p2_center.add_child(p2_content)

	p2_title = _create_label(p2_content, "%s - RONDA 1/3" % _get_wordle_mode_title(), 28, Color.YELLOW)
	p2_title.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	p2_status = _create_label(p2_content, "Escribe una palabra de 5 letras (Teclado Real)", 18)
	p2_status.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

	var grid_center := CenterContainer.new()
	grid_center.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	p2_content.add_child(grid_center)

	p2_grid = GridContainer.new()
	grid_center.add_child(p2_grid)
	p2_grid.columns = 5
	p2_grid.add_theme_constant_override("h_separation", 10)
	p2_grid.add_theme_constant_override("v_separation", 10)

	for i in range(30):
		var panel := PanelContainer.new()
		panel.custom_minimum_size = Vector2(64, 60)
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.2, 0.2, 0.2)
		style.border_width_bottom = 2
		style.border_width_top = 2
		style.border_width_left = 2
		style.border_width_right = 2
		style.border_color = Color(0.5, 0.5, 0.5)
		panel.add_theme_stylebox_override("panel", style)

		var lbl := _create_label(panel, "", 32)
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

		p2_grid.add_child(panel)
		wordle_labels.append({"panel": panel, "label": lbl, "style": style})


func _is_story_tiebreaker() -> bool:
	return (
		Global.professor_challenge.get("trivia_tied", false)
		and not Global.professor_challenge.get("first_arc_complete", false)
	)


func _get_wordle_mode_title() -> String:
	if _is_story_tiebreaker():
		return "DESEMPATE WORDLE"
	return "WORDLE MÉDICO"


func _setup_wordle_round() -> void:
	if p2_round > 3:
		_end_wordle()
		return

	p2_title.text = "%s - RONDA %d/3" % [_get_wordle_mode_title(), p2_round]
	p2_status.text = "Escribe una palabra de 5 letras (Tú: %d | Enrique: %d)" % [player_w_wins, enrique_w_wins]
	p2_status.add_theme_color_override("font_color", Color.WHITE)
	target_word = wordle_words[(p2_round - 1) % wordle_words.size()]
	current_guess = ""
	current_attempt = 0

	for w_dict: Dictionary in wordle_labels:
		w_dict["label"].text = ""
		w_dict["style"].bg_color = Color(0.2, 0.2, 0.2)

	_step_start_time = _time_elapsed


func _unhandled_key_input(event: InputEvent) -> void:
	if not _is_running or not event is InputEventKey or not event.pressed:
		return

	if event.keycode == KEY_BACKSPACE and current_guess.length() > 0:
		current_guess = current_guess.substr(0, current_guess.length() - 1)
		_update_grid_text()
	elif event.keycode == KEY_ENTER and current_guess.length() == 5:
		_submit_guess()
	elif current_guess.length() < 5:
		var chr := OS.get_keycode_string(event.keycode)
		if chr.length() == 1 and chr >= "A" and chr <= "Z":
			current_guess += chr
			step_sound.play()
			_update_grid_text()


func _update_grid_text() -> void:
	var start_idx := current_attempt * 5
	for i in range(5):
		wordle_labels[start_idx + i]["label"].text = current_guess[i] if i < current_guess.length() else ""


func _submit_guess() -> void:
	var start_idx := current_attempt * 5
	var is_correct := current_guess == target_word
	var used_indices: Array[int] = []

	for i in range(5):
		var is_exact := current_guess[i] == target_word[i]
		wordle_labels[start_idx + i]["style"].bg_color = Color(0.2, 0.6, 0.2) if is_exact else Color(0.3, 0.3, 0.3)
		if is_exact:
			used_indices.append(i)

	for i in range(5):
		if current_guess[i] == target_word[i]:
			continue
		for j in range(5):
			if current_guess[i] == target_word[j] and not j in used_indices:
				wordle_labels[start_idx + i]["style"].bg_color = Color(0.7, 0.6, 0.1)
				used_indices.append(j)
				break

	current_attempt += 1
	var time_taken := _time_elapsed - _step_start_time
	_step_start_time = _time_elapsed

	if is_correct:
		ScoreManager.record_minigame_step(true, "Acierto Wordle", time_taken)
		_round_over(true)
	elif current_attempt >= 6:
		ScoreManager.record_minigame_step(false, "Fallo Wordle", time_taken)
		_round_over(false)

	current_guess = ""


func _round_over(player_won: bool) -> void:
	var enrique_won := randf() < ENRIQUE_WIN_CHANCE

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


func _end_wordle() -> void:
	var time_remaining := maxf(0.0, TIME_LIMIT_SEC - _time_elapsed)
	if player_w_wins > enrique_w_wins:
		p2_title.text = "¡GANASTE EL DESEMPATE!"
		p2_title.add_theme_color_override("font_color", Color.GREEN)
		p2_status.text = "Tú: %d | Enrique: %d" % [player_w_wins, enrique_w_wins]
		success_fanfare.play()
		await get_tree().create_timer(3.0).timeout
		ScoreManager.record_minigame_result("wordle", true, player_w_wins, time_remaining)
		end(true)
		return

	if enrique_w_wins > player_w_wins:
		p2_title.text = "ENRIQUE GANÓ EL DESEMPATE"
		p2_title.add_theme_color_override("font_color", Color.RED)
		p2_status.text = "Tú: %d | Enrique: %d" % [player_w_wins, enrique_w_wins]
		fail_sound.play()
		await get_tree().create_timer(3.0).timeout
		ScoreManager.record_minigame_result("wordle", false, 0, time_remaining)
		end(false)
		return

	p2_status.text = "¡Empate! Ronda de muerte súbita."
	p2_round -= 1
	await get_tree().create_timer(2.0).timeout
	if _is_running:
		_setup_wordle_round()


func _process(delta: float) -> void:
	if _is_running:
		_time_elapsed += delta

	var vp_size := get_viewport().get_visible_rect().size
	if is_instance_valid(game_container):
		game_container.size = vp_size
	if is_instance_valid(p2_container) and p2_container.visible:
		p2_container.size = vp_size
		if p2_container.get_child_count() > 0 and p2_container.get_child(0) is ColorRect:
			(p2_container.get_child(0) as ColorRect).size = vp_size
