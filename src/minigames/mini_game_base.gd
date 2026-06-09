extends CanvasLayer
class_name MiniGameBase

signal game_completed(game_id: String, success: bool)

var game_id: String = ""
var _is_running: bool = false

@onready var background: TextureRect = $Background
@onready var game_container: Control = $GameContainer

func setup(id: String) -> void:
	game_id = id

func set_background_image(img: Image) -> void:
	if img and not img.is_empty():
		background.texture = ImageTexture.create_from_image(img)

func start() -> void:
	if _is_running:
		return
	_is_running = true
	process_mode = PROCESS_MODE_WHEN_PAUSED
	get_tree().paused = true
	show()
	var tween = create_tween()
	tween.tween_property(background, "modulate:a", 0.65, 0.15)

func end(success: bool) -> void:
	if not _is_running:
		return
	_is_running = false
	_on_before_end(success)
	process_mode = PROCESS_MODE_INHERIT
	
	if SceneManager and SceneManager.has_method("play_time_passage"):
		SceneManager.play_time_passage(1.5, func():
			get_tree().paused = false
			hide()
			_on_after_end(success)
			game_completed.emit(game_id, success)
		)
	else:
		get_tree().paused = false
		var tween = create_tween()
		tween.tween_property(background, "modulate:a", 0.0, 0.3)
		await tween.finished
		hide()
		_on_after_end(success)
		game_completed.emit(game_id, success)

func _on_before_end(_success: bool) -> void:
	pass

func _on_after_end(_success: bool) -> void:
	pass

func get_result() -> bool:
	return false

func _ready() -> void:
	hide()
	background.modulate.a = 0.0
	_apply_crt_to_background()

func _apply_crt_to_background() -> void:
	var mat := ShaderMaterial.new()
	mat.shader = load("res://src/minigames/crt_overlay.gdshader")
	mat.set_shader_parameter("vignette_intensity", 0.4)
	mat.set_shader_parameter("vignette_opacity", 0.8)
	mat.set_shader_parameter("vignette_color", Color.BLACK)
	mat.set_shader_parameter("scanline_intensity", 0.15)
	mat.set_shader_parameter("scanline_frequency", 400.0)
	background.material = mat
