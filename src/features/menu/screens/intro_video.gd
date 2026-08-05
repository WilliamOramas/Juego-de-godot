extends Control

@onready var video: VideoStreamPlayer = $VideoStreamPlayer
@onready var skip_hint: Label = $SkipHint
@onready var fade_rect: ColorRect = $FadeRect

var _can_skip: bool = false
var _is_ending: bool = false


func _ready() -> void:
	skip_hint.modulate.a = 0.0
	PhoneHud.visible = false
	PhoneHud.set_process_input(false)
	PhoneHud.set_process_unhandled_input(false)
	fade_rect.modulate.a = 1.0
	video.play()
	_fade_in()
	await get_tree().create_timer(1.0).timeout
	_can_skip = true
	var tween = create_tween()
	tween.tween_property(skip_hint, "modulate:a", 0.6, 0.5)


func _unhandled_input(event: InputEvent) -> void:
	if not _can_skip or _is_ending:
		return
	if event.is_action_pressed("ui_accept") or (event is InputEventKey and event.keycode == KEY_E and event.pressed and not event.echo):
		_go_to_menu()


func _on_video_stream_player_finished() -> void:
	if not _is_ending:
		_go_to_menu()


func _fade_in() -> void:
	var tween = create_tween()
	tween.tween_property(fade_rect, "modulate:a", 0.0, 0.8).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _go_to_menu() -> void:
	_is_ending = true
	_can_skip = false
	skip_hint.modulate.a = 0.0
	video.stop()
	var tween = create_tween()
	tween.tween_property(fade_rect, "modulate:a", 1.0, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	await tween.finished
	get_tree().change_scene_to_file("res://src/features/menu/screens/splash_screen.tscn")
