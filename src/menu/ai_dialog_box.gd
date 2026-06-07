extends CanvasLayer

signal dialog_finished

@export var type_speed: float = 0.015

@onready var panel: Panel = $Panel
@onready var npc_name_label: Label = %NPCName
@onready var dialog_label: Label = %DialogText
@onready var type_timer: Timer = $TypeTimer
@onready var audio_typewriter: AudioStreamPlayer = $AudioTypewriter
@onready var audio_select: AudioStreamPlayer = $AudioSelect

# New elements for AI Chat
@onready var input_line: LineEdit = %InputLine
@onready var send_button: Button = %SendButton
@onready var badge_container: HBoxContainer = %BadgeContainer

var is_open: bool = false

var _lines: Array[String] = []
var _current_line: int = 0
var _char_index: int = 0
var _is_typing: bool = false
var _slide_tween: Tween = null
var _just_opened: bool = false
var _was_open_before_pause: bool = false
var _current_ai_prompt: String = ""

func _ready() -> void:
	visible = false
	input_line.text_submitted.connect(_on_text_submitted)
	send_button.pressed.connect(_on_send_pressed)
	
	# Programación funcional para conectar botones (filtrado y mapeo)
	var _discard = badge_container.get_children().filter(func(c): return c is Button).map(func(btn): btn.pressed.connect(func(): _on_badge_pressed(btn.text)))
			
	EventBus.ai_response_received.connect(_on_ai_response_received)
	EventBus.ai_error_received.connect(_on_ai_error_received)

func show_dialog(npc_name: String, lines: Array[String], ai_system_prompt: String = "") -> void:
	if is_open or lines.is_empty():
		return

	_current_ai_prompt = ai_system_prompt
	_lines = lines
	_current_line = 0
	npc_name_label.text = npc_name
	npc_name_label.visible = not npc_name.is_empty()
	dialog_label.text = ""

	visible = true
	is_open = true
	_just_opened = true
	badge_container.visible = true
	
	input_line.text = ""
	input_line.editable = false
	send_button.disabled = true

	panel.offset_top = 0
	_slide_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	# Increased height from -170.0 to -240.0 to accommodate input area
	_slide_tween.tween_property(panel, "offset_top", -240.0, AnimHelper.DIALOG_SLIDE_IN)
	_slide_tween.finished.connect(_start_typewriter)
	audio_select.play()
	EventBus.dialog_started.emit()

func _set_input_state(enabled: bool) -> void:
	input_line.text = "" if not enabled else input_line.text
	input_line.editable = enabled
	send_button.disabled = not enabled
	if enabled: input_line.grab_focus()

func _start_typewriter() -> void:
	if _current_line >= _lines.size():
		return _set_input_state(true)

	dialog_label.text = ""
	_char_index = 0
	_is_typing = true
	_set_input_state(false)
	type_timer.start(type_speed)

func _on_type_timer_timeout() -> void:
	if get_tree().paused:
		return
	if _char_index < _lines[_current_line].length():
		_char_index += 1
		dialog_label.text = _lines[_current_line].left(_char_index)
		if not audio_typewriter.playing:
			audio_typewriter.play()
	else:
		_is_typing = false
		type_timer.stop()
		audio_typewriter.stop()
		
		# If there are more lines, wait for user to press E or Enter to continue reading
		# Otherwise, enable text input
		if _current_line < _lines.size() - 1:
			pass # wait for input event
		else:
			_set_input_state(true)

func _unhandled_input(event: InputEvent) -> void:
	if not is_open or get_tree().paused or _just_opened:
		_just_opened = false if _just_opened else false
		return

	# Declarative input evaluation
	var is_accept = not input_line.has_focus() and (event.is_action_pressed("ui_accept") or (event is InputEventKey and event.keycode == KEY_E and event.pressed and not event.echo))
	var is_cancel = event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.keycode == KEY_ESCAPE and event.pressed and not event.echo)

	# Control de flujo declarativo mediante Pattern Matching
	match [is_accept, is_cancel, _is_typing]:
		[true, false, true]:
			get_viewport().set_input_as_handled()
			_is_typing = false
			type_timer.stop()
			audio_typewriter.stop()
			dialog_label.text = _lines[_current_line]
			if _current_line >= _lines.size() - 1: _set_input_state(true)
		[true, false, false]:
			get_viewport().set_input_as_handled()
			if _current_line < _lines.size() - 1:
				audio_select.play()
				_current_line += 1
				_start_typewriter()
		[false, true, _]:
			get_viewport().set_input_as_handled()
			hide_dialog()

func _on_send_pressed() -> void:
	var text = input_line.text.strip_edges()
	if text != "":
		_submit_player_message(text)

func _on_text_submitted(new_text: String) -> void:
	var text = new_text.strip_edges()
	if text != "":
		_submit_player_message(text)

func _on_badge_pressed(text: String) -> void:
	if input_line.editable:
		_submit_player_message(text)

func _submit_player_message(text: String) -> void:
	_set_input_state(false)
	badge_container.visible = false
	audio_select.play()
	_update_dialog_lines(["..."])
	AiClient.generate_npc_response(npc_name_label.text, text, _current_ai_prompt)

func _update_dialog_lines(new_lines: Array[String]) -> void:
	_lines = new_lines
	_current_line = 0
	_start_typewriter()

func _on_ai_response_received(npc_name: String, text: String) -> void:
	if is_open and npc_name == npc_name_label.text: 
		_update_dialog_lines([text])

func _on_ai_error_received(error: String) -> void:
	if is_open: _update_dialog_lines(["[Error de sistema: " + error + "]"])

func hide_dialog() -> void:
	if not is_open:
		return

	is_open = false
	_is_typing = false
	type_timer.stop()
	audio_typewriter.stop()
	
	if _slide_tween:
		_slide_tween.kill()
		_slide_tween = null

	if _just_opened:
		_just_opened = false
		visible = false
		_clear_dialog_finished()
		return

	_slide_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	_slide_tween.tween_property(panel, "offset_top", 0.0, AnimHelper.DIALOG_SLIDE_OUT)
	_slide_tween.finished.connect(_on_hide_finished)
	audio_select.play()

func hide_for_pause() -> void:
	_was_open_before_pause = is_open
	if is_open:
		visible = false

func show_for_pause() -> void:
	if _was_open_before_pause:
		_was_open_before_pause = false
		visible = true

func _on_hide_finished() -> void:
	visible = false
	_clear_dialog_finished()

func _clear_dialog_finished() -> void:
	dialog_finished.emit()
	EventBus.dialog_finished.emit()
