extends CanvasLayer

signal dialog_finished

@export var type_speed: float = 0.015

@onready var panel: Panel = $Panel
@onready var npc_name_label: Label = %NPCName
@onready var dialog_label: Label = %DialogText
@onready var continue_prompt: Label = %ContinuePrompt
@onready var type_timer: Timer = $TypeTimer

var is_open: bool = false

var _lines: Array[String] = []
var _current_line: int = 0
var _char_index: int = 0
var _is_typing: bool = false
var _blink_tween: Tween = null
var _slide_tween: Tween = null
var _just_opened: bool = false

func _ready():
	visible = false

func show_dialog(npc_name: String, lines: Array[String]) -> void:
	if is_open or lines.is_empty():
		return

	_lines = lines
	_current_line = 0
	npc_name_label.text = npc_name
	npc_name_label.visible = not npc_name.is_empty()

	visible = true
	is_open = true
	_just_opened = true

	panel.offset_top = 0
	_slide_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_slide_tween.tween_property(panel, "offset_top", -170.0, 0.3)
	_slide_tween.finished.connect(_start_typewriter)

func _start_typewriter() -> void:
	if _current_line >= _lines.size():
		hide_dialog()
		return

	_stop_blink()
	dialog_label.text = ""
	_char_index = 0
	_is_typing = true
	continue_prompt.visible = false
	type_timer.start(type_speed)

func _stop_blink() -> void:
	if _blink_tween:
		_blink_tween.kill()
		_blink_tween = null

func _start_blink() -> void:
	_stop_blink()
	continue_prompt.modulate.a = 1.0
	_blink_tween = create_tween().set_loops()
	_blink_tween.tween_property(continue_prompt, "modulate:a", 0.2, 0.5)
	_blink_tween.tween_property(continue_prompt, "modulate:a", 1.0, 0.5)

func _on_type_timer_timeout() -> void:
	if _char_index < _lines[_current_line].length():
		_char_index += 1
		dialog_label.text = _lines[_current_line].left(_char_index)
	else:
		_is_typing = false
		type_timer.stop()
		continue_prompt.visible = true
		_start_blink()

func _unhandled_input(event: InputEvent) -> void:
	if not is_open:
		return

	if _just_opened:
		_just_opened = false
		return

	if event.is_action_pressed("ui_accept") or (event is InputEventKey and event.keycode == KEY_E and event.pressed and not event.echo):
		get_viewport().set_input_as_handled()

		if _is_typing:
			_is_typing = false
			type_timer.stop()
			dialog_label.text = _lines[_current_line]
			continue_prompt.visible = true
			_start_blink()
		else:
			_current_line += 1
			if _current_line >= _lines.size():
				hide_dialog()
			else:
				_start_typewriter()

func hide_dialog() -> void:
	if not is_open:
		return

	is_open = false
	_is_typing = false
	type_timer.stop()
	_stop_blink()
	continue_prompt.visible = false

	if _slide_tween:
		_slide_tween.kill()
		_slide_tween = null

	if _just_opened:
		_just_opened = false
		visible = false
		dialog_finished.emit()
		return

	_slide_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	_slide_tween.tween_property(panel, "offset_top", 0.0, 0.25)
	_slide_tween.finished.connect(_on_hide_finished)

func _on_hide_finished() -> void:
	visible = false
	dialog_finished.emit()
