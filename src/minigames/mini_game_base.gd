extends CanvasLayer
class_name MiniGameBase

signal game_completed(game_id: String, success: bool)

var game_id: String = ""
var _is_running: bool = false

@onready var background: ColorRect = $Background
@onready var game_container: Control = $GameContainer

func setup(id: String) -> void:
	game_id = id

func start() -> void:
	if _is_running:
		return
	_is_running = true
	get_tree().paused = true
	show()
	var tween = create_tween()
	tween.tween_property(background, "modulate:a", 0.6, 0.15)

func end(success: bool) -> void:
	if not _is_running:
		return
	_is_running = false
	get_tree().paused = false
	emit_signal("game_completed", game_id, success)
	hide()

func get_result() -> bool:
	return false

func _ready() -> void:
	hide()
	background.color = Color.BLACK
	background.modulate.a = 0.0
