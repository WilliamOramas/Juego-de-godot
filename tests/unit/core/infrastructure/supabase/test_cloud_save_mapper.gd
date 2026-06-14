extends RefCounted

const CloudSaveMapperScript = preload("res://src/core/infrastructure/supabase/cloud_save_mapper.gd")

static func run(runner) -> void:
	runner.run_suite("CloudSaveMapper", func() -> void:
		_test_extract_completed_scenarios(runner)
		_test_extract_slot_summary(runner)
		_test_extract_all_slots(runner)
	)


static func _test_extract_completed_scenarios(runner) -> void:
	var completed := {"fainting_first_aid": true, "cpr": true, "trivia": true}
	var result = CloudSaveMapperScript.extract_completed_scenarios(completed)
	runner.assert_array_eq(result, ["cpr", "fainting_first_aid", "trivia"], "completed scenarios")
	runner.assert_array_eq(CloudSaveMapperScript.extract_completed_scenarios({}), [], "empty completed")
	runner.assert_array_eq(CloudSaveMapperScript.extract_completed_scenarios(null), [], "invalid completed")


static func _test_extract_slot_summary(runner) -> void:
	var slot_data := {
		"last_scene": "res://src/levels/school_hallway.tscn",
		"score_stats": {"score": 1200, "quests_completed": 2},
		"completed_scenarios": {"cpr": true, "trivia": true},
	}
	var summary = CloudSaveMapperScript.extract_slot_summary("user-1", 1, slot_data)
	runner.assert_eq(summary["user_id"], "user-1")
	runner.assert_eq(summary["slot"], 1)
	runner.assert_eq(summary["ultima_escena"], "res://src/levels/school_hallway.tscn")
	runner.assert_eq(summary["puntaje"], 1200)
	runner.assert_eq(summary["quests_completadas"], 2)
	runner.assert_array_eq(summary["escenarios_completados"], ["cpr", "trivia"], "slot summary scenarios")


static func _test_extract_all_slots(runner) -> void:
	var save_data := {
		"slot_0": {
			"last_scene": "res://a.tscn",
			"score_stats": {"score": 100, "quests_completed": 1},
			"completed_scenarios": {"trivia": true},
		},
		"slot_2": {
			"last_scene": "res://b.tscn",
			"score_stats": {"score": 500, "quests_completed": 0},
			"completed_scenarios": {},
		},
		"ignored": {},
	}
	var summaries = CloudSaveMapperScript.extract_all_slots(save_data, "abc")
	runner.assert_eq(summaries.size(), 2)
	runner.assert_eq(summaries[0]["slot"], 0)
	runner.assert_eq(summaries[1]["slot"], 2)
