extends Node

var _active_minigame: MiniGameBase = null

func launch_minigame(scene_path: String, game_id: String) -> void:
	if _active_minigame:
		return
	var scene: PackedScene = load(scene_path)
	if not scene:
		push_error("MiniGameManager: No se pudo cargar ", scene_path)
		return
	var instance: MiniGameBase = scene.instantiate()
	instance.setup(game_id)
	instance.game_completed.connect(_on_minigame_completed)
	add_child(instance)
	_active_minigame = instance
	EventBus.minigame_started.emit(game_id)
	instance.start()

func _on_minigame_completed(game_id: String, success: bool) -> void:
	EventBus.minigame_completed.emit(game_id, success)
	if _active_minigame:
		_active_minigame.game_completed.disconnect(_on_minigame_completed)
		_active_minigame.queue_free()
		_active_minigame = null

func is_minigame_active() -> bool:
	return _active_minigame != null
