extends Node

const SETTINGS_PATH := "user://settings.save"
const SAVE_SLOT_COUNT := 3
const SAVE_VERSION := 1

var active_slot: int = 0
var _loading: bool = false
var _dirty: bool = false

func _ready() -> void:
	load_settings()

func get_save_path(slot: int) -> String:
	return "user://savegame_%d.save" % slot

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
	if data.get("version", 0) != SAVE_VERSION:
		return
	if data.has("is_muted"):
		Global.set_mute(data["is_muted"])
	if data.has("volume_db"):
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), data["volume_db"])
	if data.has("fullscreen"):
		if data["fullscreen"]:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

# ─── Game Progress (slot-based) ──────────────────────────────

func reset_game(slot: int) -> void:
	active_slot = slot
	Global.dialogs_seen.clear()
	Global.pending_position_restore = false
	Global.saved_player_position = Vector2.ZERO
	_dirty = false
	var path := get_save_path(slot)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)

func has_game_save(slot: int) -> bool:
	return FileAccess.file_exists(get_save_path(slot))

func get_save_info(slot: int) -> Dictionary:
	var path := get_save_path(slot)
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
	return {
		"empty": false,
		"last_scene": data.get("last_scene", ""),
	}

func mark_dirty() -> void:
	if _loading:
		return
	_dirty = true

func flush(override_last_scene: String = "") -> void:
	if not _dirty and override_last_scene == "":
		return
	_dirty = false
	_save_game(active_slot, override_last_scene)

func _save_game(slot: int, override_last_scene: String = "") -> void:
	var data := _build_game_data(override_last_scene)
	var json := JSON.stringify(data, "\t")
	var file := FileAccess.open(get_save_path(slot), FileAccess.WRITE)
	if file == null:
		push_error("SaveManager: No se pudo guardar partida slot %d" % slot)
		return
	file.store_string(json)
	file.close()

func load_game(slot: int) -> String:
	var path := get_save_path(slot)
	if not FileAccess.file_exists(path):
		return ""
	active_slot = slot
	_loading = true
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
	var scene := get_tree().current_scene
	if not scene:
		return null
	return scene.find_child("Player", true, false) as Player

func _build_game_data(override_last_scene: String = "") -> Dictionary:
	var last_scene := override_last_scene
	if last_scene == "":
		last_scene = get_tree().current_scene.scene_file_path if get_tree().current_scene else ""
	var data: Dictionary = {
		"version": SAVE_VERSION,
		"dialogs_seen": Global.dialogs_seen.duplicate(),
		"quest_progress": {},
		"last_scene": last_scene,
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
		for key in data["dialogs_seen"]:
			Global.dialogs_seen[key] = data["dialogs_seen"][key]
	if data.has("player_position_x") and data.has("player_position_y"):
		Global.saved_player_position = Vector2(data["player_position_x"], data["player_position_y"])
		Global.pending_position_restore = true
	return data.get("last_scene", "")
