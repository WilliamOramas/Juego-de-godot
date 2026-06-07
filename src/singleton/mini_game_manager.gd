extends Node

const SCENARIOS: Dictionary = {
	"fainting_first_aid": {
		"path": "res://src/minigames/mini_fainting_first_aid.tscn",
		"id": "fainting_first_aid",
		"cinematic": false,
	},
	"cpr": {
		"path": "res://src/minigames/mini_cpr.tscn",
		"id": "cpr",
		"cinematic": false,
	},
	"trivia": {
		"path": "res://src/minigames/mini_trivia.tscn",
		"id": "trivia",
		"cinematic": true,
	},
}

var _active_minigame: MiniGameBase = null
var _bgm_player: Node = null

func get_scenario(scenario_id: String) -> Dictionary:
	return SCENARIOS.get(scenario_id, {})

func has_scenario(scenario_id: String) -> bool:
	return SCENARIOS.has(scenario_id)

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
	_stop_bgm()
	var viewport_img: Image = get_viewport().get_texture().get_image()
	instance.set_background_image(viewport_img)
	EventBus.minigame_started.emit(game_id)
	instance.start()
	
	# Iniciar sesión de telemetría en la base de datos
	var db_escenario_id = 1
	if game_id == "cpr":
		db_escenario_id = 2
	elif game_id == "trivia":
		db_escenario_id = 3
		
	if Supabase.is_logged_in():
		Supabase.start_session(db_escenario_id, func(_s, _id, _e): pass)

func _stop_bgm() -> void:
	var scene := get_tree().current_scene
	if not scene:
		return
	for child in scene.get_children():
		if (child is AudioStreamPlayer or child is AudioStreamPlayer2D) and child.playing:
			_bgm_player = child
			child.stop()
			return

func _resume_bgm() -> void:
	if _bgm_player and is_instance_valid(_bgm_player):
		_bgm_player.play()
	_bgm_player = null

func _on_minigame_completed(game_id: String, success: bool) -> void:
	EventBus.minigame_completed.emit(game_id, success)
	_resume_bgm()
	if _active_minigame:
		_active_minigame.game_completed.disconnect(_on_minigame_completed)
		_active_minigame.queue_free()
		_active_minigame = null

func is_minigame_active() -> bool:
	return _active_minigame != null
