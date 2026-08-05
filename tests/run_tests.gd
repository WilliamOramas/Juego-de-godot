extends Node

# Run from project root:
#   godot --headless -s res://tests/run_tests.gd

const TestRunnerScript = preload("res://tests/framework/test_runner.gd")

# Core / Infrastructure
const TestCloudSaveMapperScript = preload("res://tests/unit/core/infrastructure/supabase/test_cloud_save_mapper.gd")
const TestSupabaseApiScript = preload("res://tests/unit/core/infrastructure/supabase/test_supabase_api.gd")
const TestGameProtocolScript = preload("res://tests/unit/core/infrastructure/network/test_game_protocol.gd")
const TestAiClientScript = preload("res://tests/unit/core/infrastructure/ai/test_ai_client.gd")
const TestAiDialogBoxScript = preload("res://tests/unit/features/menu/features/dialog/test_ai_dialog_box.gd")

# Core / Managers
const TestScoreManagerScript = preload("res://tests/unit/core/managers/test_score_manager.gd")
const TestJournalManagerScript = preload("res://tests/unit/core/managers/test_journal_manager.gd")
const TestQuestManagerScript = preload("res://tests/unit/core/managers/test_quest_manager.gd")

# Features
const TestTriviaQuestionGeneratorScript = preload("res://tests/unit/features/minigames/components/test_trivia_question_generator.gd")

func _ready() -> void:
	var runner = TestRunnerScript.new()
	
	# Run infrastructure tests
	TestCloudSaveMapperScript.run(runner)
	TestSupabaseApiScript.run(runner)
	TestGameProtocolScript.run(runner)
	TestAiClientScript.run(runner)
	TestAiDialogBoxScript.run(runner)
	
	# Run manager tests
	TestScoreManagerScript.run(runner)
	TestJournalManagerScript.run(runner)
	TestQuestManagerScript.run(runner)
	
	# Run feature tests
	TestTriviaQuestionGeneratorScript.run(runner)
	
	var exit_code: int = runner.summary()
	get_tree().quit(exit_code)
