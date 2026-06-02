extends Node

signal dialog_finished
signal scene_changing(scene_path: String)
signal scene_changed(scene_path: String)
signal minigame_started(game_id: String)
signal minigame_completed(game_id: String, success: bool)
