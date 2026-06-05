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


func _ready() -> void:
	EventBus.minigame_completed.connect(_on_minigame_completed)
	EventBus.quest_completed.connect(_on_quest_completed)
	EventBus.dialog_finished.connect(_on_dialog_finished)


func record_minigame_step(success: bool) -> void:
	if not success:
		_step_errors += 1


func record_minigame_result(success: bool, lives: int, time: float) -> void:
	minigame_passed = success
	student_saved = success
	lives_remaining = lives
	time_remaining = time
	errors_count = _step_errors
	total_errors += _step_errors
	minigame_attempts += 1
	_step_errors = 0
	EventBus.score_updated.emit()


func record_student_death() -> void:
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


func calculate_score() -> int:
	var score: int = 0
	if minigame_passed:
		score += 1000
		score += int(lives_remaining * 200)
		score += int(time_remaining * 5)
		score -= errors_count * 50
	else:
		score += errors_count * -25
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
	}


func reset() -> void:
	minigame_passed = false
	student_saved = false
	lives_remaining = 0
	time_remaining = 0.0
	errors_count = 0
	total_errors = 0
	quests_completed = 0
	npcs_talked = 0
	minigame_attempts = 0
	_step_errors = 0


func _on_minigame_completed(_game_id: String, _success: bool) -> void:
	pass


func _on_quest_completed(_qid: String, _qname: String) -> void:
	record_quest_completed()


func _on_dialog_finished() -> void:
	record_npc_talked()
