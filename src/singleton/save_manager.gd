extends Node

const SETTINGS_PATH := "user://settings.save"
const SAVE_PATH := "user://savegame.save"
const SAVE_VERSION := 1

var _loading: bool = false
var _dirty: bool = false

func _ready() -> void:
	load_settings()

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

# ─── Game Progress (only for continue) ────────────────────────

func reset_game() -> void:
	Global.dialogs_seen.clear()
	_dirty = false
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)

func has_game_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func mark_dirty() -> void:
	if _loading:
		return
	_dirty = true

func flush() -> void:
	if not _dirty:
		return
	_dirty = false
	save_game()

func save_game() -> void:
	var data := _build_game_data()
	var json := JSON.stringify(data, "\t")
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("SaveManager: No se pudo guardar partida")
		return
	file.store_string(json)
	file.close()

func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	_loading = true
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		_loading = false
		return
	var json := file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(json)
	if parsed == null or not (parsed is Dictionary):
		push_warning("SaveManager: Archivo de guardado corrupto")
		_loading = false
		return
	_apply_game_data(parsed as Dictionary)
	_loading = false

func _build_game_data() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"dialogs_seen": Global.dialogs_seen.duplicate(),
		"quest_progress": {},
		"last_scene": get_tree().current_scene.scene_file_path if get_tree().current_scene else "",
	}

func _apply_game_data(data: Dictionary) -> void:
	if data.get("version", 0) != SAVE_VERSION:
		return
	if data.has("dialogs_seen") and data["dialogs_seen"] is Dictionary:
		for key in data["dialogs_seen"]:
			Global.dialogs_seen[key] = data["dialogs_seen"][key]
