extends RefCounted

const GameProtocolScript = preload("res://src/domain/game_protocol.gd")
const MiniFaintingFirstAidScript = preload("res://src/minigames/mini_fainting_first_aid.gd")
const MiniCprScript = preload("res://src/minigames/mini_cpr.gd")


static func run(runner) -> void:
	runner.run_suite("GameProtocol", func() -> void:
		_test_session_result(runner)
		_test_protocol_seed_counts(runner)
		_test_minigame_protocol_alignment(runner)
	)


static func _test_session_result(runner) -> void:
	runner.assert_eq(GameProtocolScript.resolve_session_result(true, false), "Salvado")
	runner.assert_eq(GameProtocolScript.resolve_session_result(true, true), "Fallecido")
	runner.assert_eq(GameProtocolScript.resolve_session_result(false, false), "Fallecido")
	runner.assert_true(GameProtocolScript.VALID_SESSION_RESULTS.has("Salvado"))
	runner.assert_true(GameProtocolScript.VALID_SESSION_RESULTS.has("Fallecido"))


static func _test_protocol_seed_counts(runner) -> void:
	runner.assert_eq(GameProtocolScript.get_protocol_steps(GameProtocolScript.ESCENARIO_DESMAYO).size(), 7)
	runner.assert_eq(GameProtocolScript.get_protocol_steps(GameProtocolScript.ESCENARIO_RCP).size(), 5)
	runner.assert_eq(GameProtocolScript.get_protocol_steps(GameProtocolScript.ESCENARIO_TRIVIA).size(), 4)


static func _test_minigame_protocol_alignment(runner) -> void:
	var fainting_actions := GameProtocolScript.collect_step_actions(MiniFaintingFirstAidScript.STEP_DATA)
	var cpr_actions := GameProtocolScript.collect_step_actions(MiniCprScript.STEP_DATA)
	runner.assert_array_eq(
		fainting_actions,
		GameProtocolScript.get_protocol_steps(GameProtocolScript.ESCENARIO_DESMAYO),
		"fainting protocol actions match DB seeds"
	)
	runner.assert_array_eq(
		cpr_actions,
		GameProtocolScript.get_protocol_steps(GameProtocolScript.ESCENARIO_RCP),
		"cpr protocol actions match DB seeds"
	)
