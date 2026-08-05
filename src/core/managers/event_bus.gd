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

@warning_ignore("unused_signal")
signal ai_response_received(npc_name: String, response_text: String)
@warning_ignore("unused_signal")
signal ai_error_received(error_message: String)

@warning_ignore("unused_signal")
signal quest_started(quest_id: String, quest_name: String)
@warning_ignore("unused_signal")
signal objective_advanced(quest_id: String, objective_id: String, description: String)
@warning_ignore("unused_signal")
signal quest_completed(quest_id: String, quest_name: String)

@warning_ignore("unused_signal")
signal student_died

@warning_ignore("unused_signal")
signal score_updated
@warning_ignore("unused_signal")
signal journal_entry_added(entry: Resource)
@warning_ignore("unused_signal")
signal quest_blocked(quest_id: String, required_quest_id: String)
