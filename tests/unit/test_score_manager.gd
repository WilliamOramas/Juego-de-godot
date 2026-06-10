extends RefCounted

const ScoreManagerScript = preload("res://src/singleton/score_manager.gd")


static func run(runner) -> void:
	runner.run_suite("ScoreManager", func() -> void:
		_test_calculate_score(runner)
		_test_get_grade(runner)
		_test_recompute_summary(runner)
	)


static func _new_score_manager() -> Node:
	return ScoreManagerScript.new()


static func _test_calculate_score(runner) -> void:
	var manager := _new_score_manager()
	manager.set_minigame_results({
		"cpr": {"passed": true, "lives": 2, "time": 40.0, "errors": 1},
	})
	# 1000 + 400 + 200 - 50 = 1550
	runner.assert_eq(manager.calculate_score(), 1550)

	manager.set_minigame_results({
		"trivia": {"passed": false, "lives": 0, "time": 0.0, "errors": 2},
	})
	runner.assert_eq(manager.calculate_score(), 0)

	manager.set_minigame_results({
		"cpr": {"passed": true, "lives": 1, "time": 10.0, "errors": 0},
		"trivia": {"passed": false, "lives": 0, "time": 0.0, "errors": 4},
	})
	# passed: 1000 + 200 + 50 = 1250, failed: -100 => 1150
	runner.assert_eq(manager.calculate_score(), 1150)


static func _test_get_grade(runner) -> void:
	var manager := _new_score_manager()
	manager.set_minigame_results({
		"a": {"passed": true, "lives": 3, "time": 100.0, "errors": 0},
	})
	runner.assert_eq(manager.get_grade(), "S")

	manager.set_minigame_results({
		"a": {"passed": true, "lives": 1, "time": 10.0, "errors": 0},
	})
	runner.assert_eq(manager.get_grade(), "B")

	manager.reset()
	runner.assert_eq(manager.get_grade(), "D")


static func _test_recompute_summary(runner) -> void:
	var manager := _new_score_manager()
	manager.set_minigame_results({
		"cpr": {"passed": true, "lives": 2, "time": 30.0, "errors": 1},
		"trivia": {"passed": false, "lives": 1, "time": 10.0, "errors": 2},
	})
	runner.assert_true(manager.minigame_passed)
	runner.assert_false(manager.student_saved)
	runner.assert_eq(manager.lives_remaining, 3)
	runner.assert_eq(manager.errors_count, 3)
