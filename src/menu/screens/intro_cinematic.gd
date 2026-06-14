extends Control

const PIXEL_BASE_SIZE := Vector2(192, 192)

@onready var pixel: Control = $PixelContainer/Pixel
@onready var narrator_label: Label = $NarratorLabel
@onready var skip_hint: Label = $SkipHint
@onready var audio: AudioStreamPlayer = $AudioStreamPlayer

var _pixel_face: TextureRect
var _pixel_arm_right: TextureRect
var _face_happy: Texture2D
var _face_normal: Texture2D
var _skip: bool = false
var _pixel_target_y: float
var _pixel_size: Vector2


func _ready() -> void:
	pixel.modulate.a = 0.0
	narrator_label.modulate.a = 0.0
	skip_hint.modulate.a = 0.0
	process_mode = Node.PROCESS_MODE_ALWAYS
	PhoneHud.visible = false
	PhoneHud.set_process_input(false)
	PhoneHud.set_process_unhandled_input(false)

	_pixel_face = pixel.get_node("Body/Face")
	_pixel_arm_right = pixel.get_node("ArmRight")
	_face_happy = load("res://src/assets/sprites/robot_face_happy.svg")
	_face_normal = _pixel_face.texture

	_pixel_size = PIXEL_BASE_SIZE * pixel.scale
	_pixel_target_y = pixel.offset_top
	pixel.offset_top = _pixel_target_y + 500
	pixel.offset_bottom = _pixel_target_y + 500 + _pixel_size.y
	_run_intro()


func _unhandled_input(event: InputEvent) -> void:
	if _skip:
		return
	if event.is_action_pressed("ui_accept") or (event is InputEventKey and event.keycode == KEY_E and event.pressed and not event.echo):
		_skip = true
		_finish_intro()


func _run_intro() -> void:
	await get_tree().create_timer(0.5).timeout
	audio.play()

	# 1. MEDI-BOT sube desde abajo
	var tween_slide = create_tween()
	tween_slide.tween_property(pixel, "modulate:a", 1.0, 0.2)
	tween_slide.parallel().tween_property(pixel, "offset_top", _pixel_target_y, 1.0).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween_slide.parallel().tween_property(pixel, "offset_bottom", _pixel_target_y + _pixel_size.y, 1.0).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await tween_slide.finished
	if _skip: return

	# 2. Wave animation
	var tween_wave = create_tween()
	tween_wave.tween_property(_pixel_arm_right, "rotation", -0.6, 0.15).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween_wave.tween_property(_pixel_arm_right, "rotation", 0.1, 0.15).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	tween_wave.tween_property(_pixel_arm_right, "rotation", -0.4, 0.15).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween_wave.tween_property(_pixel_arm_right, "rotation", 0.0, 0.15).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	await tween_wave.finished
	if _skip: return

	# 3. Happy face
	_pixel_face.texture = _face_happy
	await get_tree().create_timer(0.5).timeout
	if _skip: return

	# 4. Narrador línea 1
	_show_narrator("¡Hola! Soy MEDI-BOT,")
	await get_tree().create_timer(2.0).timeout
	if _skip: return

	# 5. Narrador línea 2
	_show_narrator("tu guía de primeros auxilios.")
	await get_tree().create_timer(2.0).timeout
	if _skip: return

	# 6. Narrador línea 3
	_show_narrator("En este juego aprenderás")
	await get_tree().create_timer(2.0).timeout
	if _skip: return

	# 7. Narrador línea 4
	_show_narrator("a cuidar de ti y los demás.")
	await get_tree().create_timer(2.0).timeout
	if _skip: return

	# 8. Narrador línea 5
	_show_narrator("¡Empecemos!")
	await get_tree().create_timer(1.5).timeout
	if _skip: return

	# 9. Fade out
	_finish_intro()


func _show_narrator(text: String) -> void:
	narrator_label.text = text
	var tween = create_tween()
	tween.tween_property(narrator_label, "modulate:a", 1.0, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _finish_intro() -> void:
	_skip = true
	var tween = create_tween().set_parallel(true)
	tween.tween_property(pixel, "modulate:a", 0.0, 0.4)
	tween.tween_property(narrator_label, "modulate:a", 0.0, 0.4)
	tween.tween_property(skip_hint, "modulate:a", 0.0, 0.3)
	tween.tween_property(audio, "volume_db", -40.0, 0.6)
	tween.tween_property($Particles, "modulate:a", 0.0, 0.4)
	await tween.finished
	get_tree().change_scene_to_file("res://src/menu/screens/intro_video.tscn")
