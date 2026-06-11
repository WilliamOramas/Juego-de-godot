extends RefCounted

const TriviaQuestionGeneratorScript = preload("res://src/domain/trivia_question_generator.gd")


static func run(runner) -> void:
	runner.run_suite("TriviaQuestionGenerator", func() -> void:
		_test_parse_valid_json(runner)
		_test_parse_invalid_json(runner)
		_test_parse_wrong_answer_index(runner)
		_test_fallback_questions(runner)
		_test_truncates_long_text(runner)
		_test_pick_question_by_difficulty(runner)
		_test_pick_extreme_question(runner)
		_test_fallback_pool_includes_traps(runner)
	)


static func _test_parse_valid_json(runner) -> void:
	var raw := JSON.stringify({
		"questions": [
			{
				"q": "¿Qué hacer ante un desmayo?",
				"ops": ["Elevar piernas", "Dar agua", "Sacudirlo", "Correr"],
				"ans": 0,
				"difficulty": 1,
			},
			{
				"q": "¿Cuántas compresiones en RCP?",
				"ops": ["30", "15", "10", "5"],
				"ans": 0,
				"difficulty": 2,
			},
			{
				"q": "Número de emergencias en España?",
				"ops": ["911", "112", "171", "999"],
				"ans": 1,
				"difficulty": 1,
			},
			{
				"q": "Atragantamiento severo?",
				"ops": ["Agua", "Heimlich", "Esperar", "Acostar"],
				"ans": 1,
				"difficulty": 3,
			},
		],
	})
	var parsed: Array = TriviaQuestionGeneratorScript.parse_and_validate(raw, 4)
	runner.assert_eq(parsed.size(), 4, "valid JSON should return 4 questions")
	runner.assert_eq(parsed[0]["q"], "¿Qué hacer ante un desmayo?")


static func _test_parse_invalid_json(runner) -> void:
	runner.assert_eq(TriviaQuestionGeneratorScript.parse_and_validate("not json", 4).size(), 0)
	runner.assert_eq(TriviaQuestionGeneratorScript.parse_and_validate('{"questions":[]}', 4).size(), 0)


static func _test_parse_wrong_answer_index(runner) -> void:
	var raw := JSON.stringify({
		"questions": [
			{
				"q": "Pregunta inválida",
				"ops": ["A", "B", "C", "D"],
				"ans": 9,
			},
		],
	})
	runner.assert_eq(TriviaQuestionGeneratorScript.parse_and_validate(raw, 1).size(), 0)


static func _test_truncates_long_text(runner) -> void:
	var long_option := "Presionar suavemente las alas de la nariz durante varios minutos e inclinar la cabeza ligeramente hacia adelante"
	var raw := JSON.stringify({
		"questions": [
			{
				"q": "Pregunta muy larga " + "x".repeat(120),
				"ops": [long_option, "Opción B", "Opción C", "Opción D"],
				"ans": 0,
			},
		],
	})
	var parsed: Array = TriviaQuestionGeneratorScript.parse_and_validate(raw, 1)
	runner.assert_eq(parsed.size(), 1)
	runner.assert_true(parsed[0]["q"].length() <= TriviaQuestionGeneratorScript.MAX_QUESTION_CHARS + 1)
	runner.assert_true(parsed[0]["ops"][0].length() <= TriviaQuestionGeneratorScript.MAX_OPTION_CHARS + 1)
	runner.assert_true(String(parsed[0]["ops"][0]).ends_with("…"))


static func _test_fallback_questions(runner) -> void:
	var fallback: Array = TriviaQuestionGeneratorScript.get_fallback_questions(4)
	runner.assert_eq(fallback.size(), 4, "fallback should return 4 questions")
	for item: Dictionary in fallback:
		runner.assert_true(item.has("q"))
		runner.assert_true(item.has("difficulty"))
		runner.assert_eq((item["ops"] as Array).size(), 4)
		runner.assert_true(int(item["ans"]) >= 0 and int(item["ans"]) < 4)
		runner.assert_true(
			int(item["difficulty"]) >= TriviaQuestionGeneratorScript.DIFFICULTY_MIN
			and int(item["difficulty"]) <= TriviaQuestionGeneratorScript.DIFFICULTY_MAX
		)


static func _test_pick_question_by_difficulty(runner) -> void:
	var pool: Array = [
		{"q": "Fácil A", "ops": ["A", "B", "C", "D"], "ans": 0, "difficulty": 1},
		{"q": "Difícil B", "ops": ["A", "B", "C", "D"], "ans": 1, "difficulty": 3},
	]
	var used: Array[String] = []
	var easy: Dictionary = TriviaQuestionGeneratorScript.pick_question(pool, used, 1)
	runner.assert_eq(easy.get("q", ""), "Fácil A")
	used.append("Fácil A")
	var only_hard: Dictionary = TriviaQuestionGeneratorScript.pick_question(pool, used, 1)
	runner.assert_true(only_hard.is_empty())


static func _test_pick_extreme_question(runner) -> void:
	var pool: Array = [
		{"q": "Normal", "ops": ["A", "B", "C", "D"], "ans": 0, "difficulty": 2},
		{"q": "Trampa", "ops": ["A", "B", "C", "D"], "ans": 1, "difficulty": 4},
	]
	var used: Array[String] = []
	var blocked: Dictionary = TriviaQuestionGeneratorScript.pick_question(pool, used, 4, false)
	runner.assert_eq(blocked.get("q", ""), "Normal")
	var allowed: Dictionary = TriviaQuestionGeneratorScript.pick_question(pool, used, 4, true)
	runner.assert_true(allowed.get("q", "") in ["Normal", "Trampa"])


static func _test_fallback_pool_includes_traps(runner) -> void:
	var pool: Array = TriviaQuestionGeneratorScript.get_fallback_pool()
	var trap_count := 0
	for item: Dictionary in pool:
		if int(item.get("difficulty", 0)) == TriviaQuestionGeneratorScript.DIFFICULTY_EXTREME:
			trap_count += 1
	runner.assert_eq(
		trap_count,
		TriviaQuestionGeneratorScript.FALLBACK_TRAP_QUESTIONS.size(),
		"fallback pool should include all trap questions"
	)
