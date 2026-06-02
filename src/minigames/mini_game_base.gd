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
	tween.tween_property(background, "modulate:a", 0.5, 0.15)

func end(success: bool) -> void:
	if not _is_running:
		return
	_is_running = false
	get_tree().paused = false
	process_mode = PROCESS_MODE_INHERIT
	var tween = create_tween()
	tween.tween_property(background, "modulate:a", 0.0, 0.3)
	await tween.finished
	hide()
	emit_signal("game_completed", game_id, success)

func get_result() -> bool:
	return false

func _ready() -> void:
	hide()
	background.modulate.a = 0.0
