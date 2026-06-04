extends Node

@warning_ignore("unused_signal")
signal dialog_started
@warning_ignore("unused_signal")
signal dialog_finished
@warning_ignore("unused_signal")
signal scene_changing(scene_path: String)
@warning_ignore("unused_signal")
signal scene_changed(scene_path: String)
@warning_ignore("unused_signal")
signal minigame_started(game_id: String)
@warning_ignore("unused_signal")
signal minigame_completed(game_id: String, success: bool)
