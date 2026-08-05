extends RefCounted

const QuestManagerScript = preload("res://src/core/managers/quest_manager.gd")
const EventBusScript = preload("res://src/core/managers/event_bus.gd")

static func run(runner) -> void:
	runner.run_suite("QuestManager", func() -> void:
		_test_start_quest(runner)
		_test_advance_and_complete(runner)
		_test_serialization(runner)
	)

static func _new_manager() -> Node:
	return QuestManagerScript.new()

static func _test_start_quest(runner) -> void:
	var manager = _new_manager()
	var mock_quest = {
		"quest_id": "q1",
		"quest_name": "Test Quest",
		"requires_quest": "",
		"objectives": [{"objective_id": "obj1", "description": "Test Obj"}]
	}
	runner.assert_true(manager.start_quest(mock_quest))
	runner.assert_true(manager.is_quest_active("q1"))
	runner.assert_false(manager.start_quest(mock_quest), "No debe iniciar la misma misión dos veces")
	
	var locked_quest = {
		"quest_id": "q2",
		"requires_quest": "q3", # Not completed
		"objectives": []
	}
	runner.assert_false(manager.start_quest(locked_quest), "Debe fallar si requiere una misión no completada")

static func _test_advance_and_complete(runner) -> void:
	var manager = _new_manager()
	var mock_quest = {
		"quest_id": "q1",
		"quest_name": "Test",
		"requires_quest": "",
		"objectives": [
			{"objective_id": "obj1", "description": "1", "type": 0},
			{"objective_id": "obj2", "description": "2", "type": 0}
		]
	}
	manager.start_quest(mock_quest)
	runner.assert_false(manager.is_objective_done("q1", "obj1"))
	
	manager.advance_objective("q1", "obj1")
	runner.assert_true(manager.is_objective_done("q1", "obj1"))
	runner.assert_false(manager.is_quest_completed("q1"))
	
	manager.advance_objective("q1", "obj2")
	runner.assert_true(manager.is_quest_completed("q1"), "Misión se completa si todos los objetivos terminan")
	runner.assert_false(manager.is_quest_active("q1"))

static func _test_serialization(runner) -> void:
	var manager = _new_manager()
	var mock_quest = {
		"quest_id": "q1",
		"quest_name": "Test",
		"requires_quest": "",
		"objectives": [{"objective_id": "o1", "description": ""}]
	}
	manager.start_quest(mock_quest)
	manager.advance_objective("q1", "o1") # Completa q1
	
	var mock_quest2 = {
		"quest_id": "q2",
		"quest_name": "Test 2",
		"requires_quest": "",
		"objectives": [{"objective_id": "o2", "description": ""}]
	}
	manager.start_quest(mock_quest2) # Activa q2
	
	var data = manager.get_quest_progress()
	runner.assert_true(data.completed_quests.has("q1"))
	runner.assert_true(data.active_quests.has("q2"))
	
	var manager2 = _new_manager()
	manager2.set_quest_progress(data)
	# Solo cargará si _load_quest_data funciona o los inyectamos directamente,
	# set_quest_progress intenta usar ResourceLoader para q2, lo cual puede fallar
	# pero completed_quests debe cargarse seguro:
	runner.assert_true(manager2.is_quest_completed("q1"))

