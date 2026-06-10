extends Node

const SETTINGS_PATH: String = "user://settings.save"
const SAVE_SLOT_COUNT: int = 3
const SAVE_VERSION: int = 1

var active_slot: int = 0
var active_is_cloud: bool = false
var _loading: bool = false
var _dirty: bool = false

func _ready() -> void:
	load_settings()

func get_save_path(slot: int, is_cloud: bool) -> String:
	if is_cloud and Supabase.is_logged_in():
		return "user://savegame_%s_%d.save" % [Supabase.user_id, slot]
	return "user://savegame_local_%d.save" % slot

# ─── Settings (always persist) ────────────────────────────────

func save_settings() -> void:
	if _loading:
		return
	var data := _build_settings_data()
	var json := JSON.stringify(data, "\t")
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if file == null:
		push_error("SaveManager: No se pudo guardar settings")
		return
	file.store_string(json)
	file.close()

func load_settings() -> void:
	if not FileAccess.file_exists(SETTINGS_PATH):
		return
	_loading = true
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	if file == null:
		_loading = false
		return
	var json := file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(json)
	if parsed == null or not (parsed is Dictionary):
		push_warning("SaveManager: Settings corruptos")
		_loading = false
		return
	_apply_settings(parsed as Dictionary)
	_loading = false

func _build_settings_data() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"is_muted": Global.is_muted,
		"volume_db": AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Master")),
		"fullscreen": DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN,
	}

func _apply_settings(data: Dictionary) -> void:
	if data.get("version", 0) != SAVE_VERSION: return
	if "is_muted" in data: Global.set_mute(data.is_muted)
	if "volume_db" in data: AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), data.volume_db)
	if "fullscreen" in data: DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if data.fullscreen else DisplayServer.WINDOW_MODE_MAXIMIZED)

# ─── Game Progress (slot-based) ──────────────────────────────

func reset_game(slot: int, is_cloud: bool) -> void:
	active_slot = slot
	active_is_cloud = is_cloud
	Global.dialogs_seen.clear()
	Global.completed_scenarios.clear()
	Global.pending_position_restore = false
	Global.saved_player_position = Vector2.ZERO
	ScoreManager.reset()
	JournalManager.clear()
	QuestManager.set_quest_progress({})
	_dirty = false
	var path := get_save_path(slot, is_cloud)
	if FileAccess.file_exists(path):
		var err: Error = DirAccess.remove_absolute(path)
		if err != OK:
			push_warning("Failed to remove save file: " + str(err))

func has_game_save(slot: int, is_cloud: bool) -> bool:
	return FileAccess.file_exists(get_save_path(slot, is_cloud))

func get_save_info(slot: int, is_cloud: bool) -> Dictionary:
	var path := get_save_path(slot, is_cloud)
	if not FileAccess.file_exists(path):
		return {"empty": true}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"empty": true}
	var json := file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(json)
	if parsed == null or not (parsed is Dictionary):
		return {"empty": true}
	var data := parsed as Dictionary
	var score_data := data.get("score_stats", {}) as Dictionary
	return {
		"empty": false,
		"last_scene": data.get("last_scene", ""),
		"timestamp": data.get("timestamp", 0),
		"student_died": data.get("student_died", false),
		"score": score_data.get("score", 0),
		"grade": score_data.get("grade", "?"),
		"quests_completed": score_data.get("quests_completed", 0),
	}

func mark_dirty() -> void:
	if _loading:
		return
	_dirty = true

func flush(override_last_scene: String = "") -> void:
	if not _dirty and override_last_scene == "":
		return
	_dirty = false
	_save_game(active_slot, active_is_cloud, override_last_scene)

func save_to_slot(slot: int, is_cloud: bool) -> void:
	active_slot = slot
	active_is_cloud = is_cloud
	_dirty = false
	_save_game(slot, is_cloud)

func _save_game(slot: int, is_cloud: bool, override_last_scene: String = "") -> void:
	var data := _build_game_data(override_last_scene)
	var json := JSON.stringify(data, "\t")
	var file := FileAccess.open(get_save_path(slot, is_cloud), FileAccess.WRITE)
	if file == null:
		push_error("SaveManager: No se pudo guardar partida slot %d" % slot)
		return
	file.store_string(json)
	file.close()
	if is_cloud:
		sync_to_cloud()

func sync_to_cloud() -> void:
	if not Supabase.is_logged_in(): return
	var combined_saves = {}
	for i in SAVE_SLOT_COUNT:
		var path = get_save_path(i, true)
		if FileAccess.file_exists(path):
			var file = FileAccess.open(path, FileAccess.READ)
			if file:
				var json_str = file.get_as_text()
				file.close()
				var parsed = JSON.parse_string(json_str)
				if typeof(parsed) == TYPE_DICTIONARY:
					combined_saves["slot_" + str(i)] = parsed
	Supabase.push_cloud_saves(combined_saves)

func sync_from_cloud(callback: Callable = Callable()) -> void:
	if not Supabase.is_logged_in():
		if callback.is_valid(): callback.call(false)
		return
	Supabase.pull_cloud_saves(func(success, save_data, _error):
		if success and typeof(save_data) == TYPE_DICTIONARY:
			for i in SAVE_SLOT_COUNT:
				var key = "slot_" + str(i)
				if save_data.has(key):
					var d = save_data[key]
					var file = FileAccess.open(get_save_path(i, true), FileAccess.WRITE)
					if file:
						file.store_string(JSON.stringify(d, "\t"))
						file.close()
			if callback.is_valid(): callback.call(true)
		else:
			if callback.is_valid(): callback.call(false)
	)

func load_game(slot: int, is_cloud: bool) -> String:
	var path := get_save_path(slot, is_cloud)
	if not FileAccess.file_exists(path):
		return ""
	active_slot = slot
	active_is_cloud = is_cloud
	_loading = true

	Global.dialogs_seen.clear()
	Global.completed_scenarios.clear()
	Global.pending_position_restore = false
	Global.saved_player_position = Vector2.ZERO
	Global.return_spawn_name = ""
	Global.student_died = false
	QuestManager.set_quest_progress({})
	ScoreManager.reset()
	JournalManager.clear()

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		_loading = false
		return ""
	var json := file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(json)
	if parsed == null or not (parsed is Dictionary):
		push_warning("SaveManager: Slot %d corrupto" % slot)
		_loading = false
		return ""
	var last_scene := _apply_game_data(parsed as Dictionary)
	_loading = false
	return last_scene

func _get_player() -> Player:
	return get_tree().get_first_node_in_group("player") as Player

func _build_game_data(override_last_scene: String = "") -> Dictionary:
	var last_scene := override_last_scene
	if last_scene == "":
		last_scene = get_tree().current_scene.scene_file_path if get_tree().current_scene else ""
	var data: Dictionary = {
		"version": SAVE_VERSION,
		"dialogs_seen": Global.dialogs_seen.duplicate(),
		"quest_progress": QuestManager.get_quest_progress(),
		"last_scene": last_scene,
		"timestamp": Time.get_unix_time_from_system(),
		"student_died": Global.student_died,
		"return_spawn_name": Global.return_spawn_name,
		"score_stats": ScoreManager.get_stats(),
		"journal_entries": JournalManager.serialize(),
		"completed_scenarios": Global.completed_scenarios.duplicate(),
	}
	var player := _get_player()
	if player:
		data["player_position_x"] = player.global_position.x
		data["player_position_y"] = player.global_position.y
	return data

func _apply_game_data(data: Dictionary) -> String:
	if data.get("version", 0) != SAVE_VERSION:
		return ""
	if data.has("dialogs_seen") and data["dialogs_seen"] is Dictionary:
		Global.dialogs_seen = data["dialogs_seen"].duplicate()
	if data.has("quest_progress") and data["quest_progress"] is Dictionary:
		QuestManager.set_quest_progress(data["quest_progress"])
	if data.has("player_position_x") and data.has("player_position_y"):
		Global.saved_player_position = Vector2(data["player_position_x"], data["player_position_y"])
		Global.pending_position_restore = true
	if data.has("student_died"):
		Global.student_died = data["student_died"]
	if data.has("return_spawn_name"):
		Global.return_spawn_name = data["return_spawn_name"]
	if data.has("score_stats"):
		var s := data["score_stats"] as Dictionary
		if s.has("minigame_results"):
			ScoreManager.set_minigame_results(s["minigame_results"])
		else:
			ScoreManager.minigame_passed = s.get("minigame_passed", false)
			ScoreManager.student_saved = s.get("student_saved", false)
			ScoreManager.lives_remaining = s.get("lives_remaining", 0)
			ScoreManager.time_remaining = s.get("time_remaining", 0.0)
			ScoreManager.errors_count = s.get("errors_count", 0)
		ScoreManager.total_errors = s.get("total_errors", 0)
		ScoreManager.quests_completed = s.get("quests_completed", 0)
		ScoreManager.npcs_talked = s.get("npcs_talked", 0)
		ScoreManager.minigame_attempts = s.get("minigame_attempts", 0)
	if data.has("journal_entries"):
		JournalManager.deserialize(data["journal_entries"] as Array)
	if data.has("completed_scenarios"):
		Global.completed_scenarios = data["completed_scenarios"].duplicate()
	return data.get("last_scene", "")
