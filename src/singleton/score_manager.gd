extends Node

var minigame_passed: bool = false
var student_saved: bool = false
var lives_remaining: int = 0
var time_remaining: float = 0.0
var errors_count: int = 0
var total_errors: int = 0
var quests_completed: int = 0
var npcs_talked: int = 0
var minigame_attempts: int = 0

var _step_errors: int = 0
var _minigame_results: Dictionary = {}
var _student_died: bool = false


func _ready() -> void:
	EventBus.minigame_completed.connect(_on_minigame_completed)
	EventBus.quest_completed.connect(_on_quest_completed)
	EventBus.dialog_finished.connect(_on_dialog_finished)
	EventBus.student_died.connect(record_student_death)


func record_minigame_step(success: bool, action: String = "Acción médica", time_taken: float = 0.0, health: String = "Estable") -> void:
	if not success:
		_step_errors += 1
		
	if Supabase.current_session_id != -1:
		Supabase.send_telemetry(Supabase.current_session_id, action, success, time_taken, health)


func record_minigame_result(game_id: String, success: bool, lives: int, time: float) -> void:
	_minigame_results[game_id] = {
		"passed": success,
		"lives": lives,
		"time": time,
		"errors": _step_errors,
	}
	total_errors += _step_errors
	minigame_attempts += 1
	_step_errors = 0
	_recompute_summary()
	EventBus.score_updated.emit()
	
	if Supabase.current_session_id != -1:
		var resultado = "Salvado" if success and not _student_died else "Fallecido"
		Supabase.finish_session(Supabase.current_session_id, resultado)


func record_student_death() -> void:
	_student_died = true
	student_saved = false
	EventBus.score_updated.emit()


func record_quest_completed() -> void:
	quests_completed += 1
	EventBus.score_updated.emit()


func record_npc_talked() -> void:
	var new_count := Global.dialogs_seen.size()
	if new_count > npcs_talked:
		npcs_talked = new_count
		EventBus.score_updated.emit()


func _recompute_summary() -> void:
	var any_passed := false
	var all_passed := true
	var total_lives := 0
	var total_time := 0.0
	var total_err := 0

	for r in _minigame_results.values():
		total_lives += r.lives
		total_time += r.time
		total_err += r.errors
		if r.passed:
			any_passed = true
		else:
			all_passed = false

	if _minigame_results.is_empty():
		minigame_passed = false
		student_saved = false
	else:
		minigame_passed = any_passed
		student_saved = all_passed and not _student_died

	lives_remaining = total_lives
	time_remaining = total_time
	errors_count = total_err


func calculate_score() -> int:
	var score: int = 0
	for r in _minigame_results.values():
		if r.passed:
			score += 1000
			score += int(r.lives * 200)
			score += int(r.time * 5)
			score -= r.errors * 50
		else:
			score += r.errors * -25
	return max(score, 0)


func get_grade() -> String:
	var s := calculate_score()
	if s >= 2000:
		return "S"
	if s >= 1500:
		return "A"
	if s >= 1000:
		return "B"
	if s >= 500:
		return "C"
	return "D"


func get_stats() -> Dictionary:
	return {
		"minigame_passed": minigame_passed,
		"student_saved": student_saved,
		"lives_remaining": lives_remaining,
		"time_remaining": time_remaining,
		"errors_count": errors_count,
		"total_errors": total_errors,
		"quests_completed": quests_completed,
		"npcs_talked": npcs_talked,
		"minigame_attempts": minigame_attempts,
		"score": calculate_score(),
		"grade": get_grade(),
		"minigame_results": _minigame_results.duplicate(true),
	}


func set_minigame_results(results: Dictionary) -> void:
	_minigame_results = results.duplicate(true)
	_recompute_summary()


func get_minigame_results() -> Dictionary:
	return _minigame_results.duplicate(true)


func reset() -> void:
	_minigame_results.clear()
	_student_died = false
	_step_errors = 0
	minigame_passed = false
	student_saved = false
	lives_remaining = 0
	time_remaining = 0.0
	errors_count = 0
	total_errors = 0
	quests_completed = 0
	npcs_talked = 0
	minigame_attempts = 0


func _on_minigame_completed(_game_id: String, _success: bool) -> void:
	pass


func _on_quest_completed(_qid: String, _qname: String) -> void:
	record_quest_completed()


func _on_dialog_finished() -> void:
	record_npc_talked()
