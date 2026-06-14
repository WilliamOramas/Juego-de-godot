extends RefCounted

const JournalManagerScript = preload("res://src/core/managers/journal_manager.gd")
const JournalEntryScript = preload("res://src/core/models/journal_entry.gd")

static func run(runner) -> void:
	runner.run_suite("JournalManager", func() -> void:
		_test_add_basic_entry(runner)
		_test_description_truncation(runner)
		_test_dialog_limit(runner)
		_test_serialization(runner)
	)

static func _new_manager() -> Node:
	return JournalManagerScript.new()

static func _test_add_basic_entry(runner) -> void:
	var manager = _new_manager()
	manager.add_minigame_entry("CPR Completed", "Good job")
	manager.add_quest_entry("Find Teacher", "Go to hallway")
	manager.add_system_entry("Game Saved", "")
	
	var entries = manager.get_entries()
	runner.assert_eq(entries.size(), 3)
	runner.assert_eq(entries[0].title, "CPR Completed")
	runner.assert_eq(entries[0].category, JournalEntryScript.Category.MINIGAME)
	runner.assert_eq(entries[1].category, JournalEntryScript.Category.QUEST)

static func _test_description_truncation(runner) -> void:
	var manager = _new_manager()
	var long_text = "A".repeat(200)
	manager.add_system_entry("Test", long_text)
	var entries = manager.get_entries()
	runner.assert_eq(entries[0].description.length(), 153) # 150 + "..."
	runner.assert_true(entries[0].description.ends_with("..."))

static func _test_dialog_limit(runner) -> void:
	var manager = _new_manager()
	for i in range(60):
		var lines: Array[String] = [str(i)]
		manager.add_dialog_entry("NPC", lines)
	var dialogs = manager.get_filtered(JournalEntryScript.Category.DIALOG)
	runner.assert_eq(dialogs.size(), 50, "Debe limitar los diálogos a MAX_DIALOG_ENTRIES (50)")
	# Si elimina el más viejo (FIFO), el que queda en index 0 debería ser "10"
	runner.assert_eq(dialogs[0].description, "10")
	runner.assert_eq(dialogs[49].description, "59")

static func _test_serialization(runner) -> void:
	var manager = _new_manager()
	manager.add_minigame_entry("A", "B")
	var hi_arr: Array[String] = ["Hi"]
	manager.add_dialog_entry("Prof", hi_arr)
	var data = manager.serialize()
	runner.assert_eq(data.size(), 2)
	
	var manager2 = _new_manager()
	manager2.deserialize(data)
	var loaded = manager2.get_entries()
	runner.assert_eq(loaded.size(), 2)
	runner.assert_eq(loaded[0].title, "A")
	runner.assert_eq(loaded[1].title, "Prof")
	runner.assert_eq(loaded[1].category, JournalEntryScript.Category.DIALOG)
