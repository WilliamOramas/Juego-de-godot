extends Node

const SCENARIOS: Dictionary = {
	"fainting_first_aid": {
		"path": "res://src/features/minigames/mini_fainting_first_aid.tscn",
		"id": "fainting_first_aid",
		"db_id": 1,
		"cinematic": false,
	},
	"cpr": {
		"path": "res://src/features/minigames/mini_cpr.tscn",
		"id": "cpr",
		"db_id": 2,
		"cinematic": false,
	},
	"trivia": {
		"path": "res://src/features/minigames/mini_trivia.tscn",
		"id": "trivia",
		"db_id": 3,
		"cinematic": true,
	},
	"wordle": {
		"path": "res://src/features/minigames/mini_wordle.tscn",
		"id": "wordle",
		"db_id": 3,
		"cinematic": true,
	},
}

var _active_minigame: MiniGameBase = null
var _bgm_player: Node = null
var _escenario_tiempos: Dictionary = {}

func _ready() -> void:
	Supabase.auth_completed.connect(_on_auth_completed)
	if Supabase.is_logged_in():
		_load_escenarios_from_db()

func _on_auth_completed(success: bool, _message: String) -> void:
	if success and Supabase.is_logged_in():
		_load_escenarios_from_db()

func _load_escenarios_from_db() -> void:
	Supabase.fetch_escenarios(func(success: bool, resp_json: Variant, _error: String) -> void:
		if not success or typeof(resp_json) != TYPE_ARRAY:
			return
		for row in resp_json:
			if typeof(row) != TYPE_DICTIONARY:
				continue
			var db_id: int = int(row.get("id_escenario", 0))
			var tiempo: int = int(row.get("tiempo_base_seg", 0))
			if db_id > 0:
				_escenario_tiempos[db_id] = tiempo
	)

func get_escenario_time_limit(db_id: int) -> int:
	return int(_escenario_tiempos.get(db_id, 0))

func get_scenario(scenario_id: String) -> Dictionary:
	return SCENARIOS.get(scenario_id, {})

func has_scenario(scenario_id: String) -> bool:
	return SCENARIOS.has(scenario_id)

func launch_minigame(scene_path: String, game_id: String, background_override: Image = null) -> void:
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
	var viewport_img: Image = background_override if background_override else get_viewport().get_texture().get_image()

	if not Supabase.is_logged_in():
		_start_minigame(instance, game_id, viewport_img)
		return

	var scenario := get_scenario(game_id)
	var db_id: int = int(scenario.get("db_id", 0))
	if db_id <= 0:
		push_warning("MiniGameManager: Sin db_id para '%s', telemetría desactivada" % game_id)
		_start_minigame(instance, game_id, viewport_img)
		return

	Supabase.start_session(db_id, func(success: bool, _id: Variant, error: String) -> void:
		if not is_instance_valid(instance) or _active_minigame != instance:
			return
		if not success:
			push_warning("MiniGameManager: No se pudo abrir sesión en BD: %s" % error)
		_start_minigame(instance, game_id, viewport_img)
	)


func _start_minigame(instance: MiniGameBase, game_id: String, viewport_img: Image) -> void:
	instance.set_background_image(viewport_img)
	EventBus.minigame_started.emit(game_id)
	instance.start()

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
	Global.completed_scenarios[game_id] = true
	SaveManager.mark_dirty()
	EventBus.minigame_completed.emit(game_id, success)
	_resume_bgm()
	if _active_minigame:
		_active_minigame.game_completed.disconnect(_on_minigame_completed)
		_active_minigame.queue_free()
		_active_minigame = null

func is_minigame_active() -> bool:
	return _active_minigame != null
