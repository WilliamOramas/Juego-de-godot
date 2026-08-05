extends Control

@export var disable_bubble: bool = false

@onready var bubble: PanelContainer = $SpeechBubble

var _message_timer: Timer

func _ready() -> void:
	bubble.hide()
	_setup_messages.call_deferred()

func _setup_messages() -> void:
	if disable_bubble:
		return

	_message_timer = Timer.new()
	_message_timer.wait_time = 1800.0 # 30 minutes
	_message_timer.timeout.connect(_on_timer_timeout)
	add_child(_message_timer)

	# Show first message after 3 seconds if not logged in
	get_tree().create_timer(3.0).timeout.connect(func():
		if is_inside_tree():
			_check_and_show()
			_message_timer.start()
	)

func _check_and_show() -> void:
	if not Supabase.is_logged_in():
		_show_message()

func _show_message() -> void:
	bubble.modulate.a = 0.0
	bubble.show()
	var tw = create_tween()
	tw.tween_property(bubble, "modulate:a", 1.0, 0.5)
	
	# Hide after 6 seconds
	get_tree().create_timer(6.0).timeout.connect(func():
		if is_inside_tree() and bubble.visible:
			var tw2 = create_tween()
			tw2.tween_property(bubble, "modulate:a", 0.0, 0.5)
			tw2.tween_callback(bubble.hide)
	)

func _on_timer_timeout() -> void:
	_check_and_show()
