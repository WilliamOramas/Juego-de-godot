extends SceneTree

# Run from project root:
#   godot --headless -s res://tests/run_tests.gd

const TestRunnerScript = preload("res://tests/framework/test_runner.gd")
const TestCloudSaveMapperScript = preload("res://tests/unit/test_cloud_save_mapper.gd")
const TestGameProtocolScript = preload("res://tests/unit/test_game_protocol.gd")
const TestSupabaseApiScript = preload("res://tests/unit/test_supabase_api.gd")
const TestScoreManagerScript = preload("res://tests/unit/test_score_manager.gd")

func _initialize() -> void:
	var runner = TestRunnerScript.new()
	TestCloudSaveMapperScript.run(runner)
	TestGameProtocolScript.run(runner)
	TestSupabaseApiScript.run(runner)
	TestScoreManagerScript.run(runner)
	var exit_code: int = runner.summary()
	quit(exit_code)
