class_name TriviaQuestionGenerator
extends RefCounted

const OPTIONS_PER_QUESTION: int = 4
const MAX_QUESTION_CHARS: int = 100
const MAX_OPTION_CHARS: int = 50

const SYSTEM_PROMPT: String = """Eres un generador de preguntas de trivia sobre primeros auxilios para estudiantes universitarios.
Reglas estrictas:
- Preguntas en español, claras y educativas.
- BREVEDAD OBLIGATORIA: pregunta ≤100 caracteres; cada opción ≤50 caracteres.
- Usa frases cortas en las opciones (ej. "Presión en la nariz", no párrafos explicativos).
- Cada pregunta debe tener exactamente 4 opciones de respuesta.
- Solo una opción correcta; las otras deben ser plausibles pero incorrectas.
- Cubre temas variados: RCP, desmayo, hemorragias, quemaduras, atragantamiento, números de emergencia, etc.
- No repitas el mismo tema entre preguntas del mismo lote.
- La información médica debe ser correcta según guías básicas de primeros auxilios.
- El campo ans es el índice 0-3 de la opción correcta en ops."""

const FALLBACK_QUESTIONS: Array[Dictionary] = [
	{
		"q": "¿Qué hacer ante una quemadura leve?",
		"ops": ["Aplicar hielo directo", "Echar agua fría por 10 min", "Poner pasta dental", "Reventar ampollas"],
		"ans": 1,
	},
	{
		"q": "¿Cuántas compresiones en RCP?",
		"ops": ["30 y 2 ventilaciones", "15 y 1", "100 seguidas", "20 y 5"],
		"ans": 0,
	},
	{
		"q": "Si alguien se atraganta y no tose...",
		"ops": ["Darle agua", "Maniobra de Heimlich", "Golpear la espalda acostado", "Esperar a que tosa"],
		"ans": 1,
	},
	{
		"q": "¿Cuál es el número de emergencias?",
		"ops": ["911", "112", "171", "Depende del país"],
		"ans": 3,
	},
	{
		"q": "Para una hemorragia severa se debe...",
		"ops": ["Aplicar un torniquete flojo", "Lavar con alcohol", "Presión directa en la herida", "Dar aspirina"],
		"ans": 2,
	},
	{
		"q": "¿Qué hacer si alguien sufre un desmayo?",
		"ops": ["Levantarlo rápido", "Elevar sus piernas", "Echarle agua fría", "Darle a oler alcohol"],
		"ans": 1,
	},
]


static func build_response_schema(question_count: int) -> Dictionary:
	return {
		"responseMimeType": "application/json",
		"thinkingConfig": {
			"thinkingBudget": 0,
		},
		"responseSchema": {
			"type": "object",
			"properties": {
				"questions": {
					"type": "array",
					"items": {
						"type": "object",
						"properties": {
							"q": {"type": "string"},
							"ops": {
								"type": "array",
								"items": {"type": "string"},
								"minItems": OPTIONS_PER_QUESTION,
								"maxItems": OPTIONS_PER_QUESTION,
							},
							"ans": {"type": "integer"},
						},
						"required": ["q", "ops", "ans"],
					},
					"minItems": question_count,
					"maxItems": question_count,
				},
			},
			"required": ["questions"],
		},
	}


static func fetch_questions(count: int, callback: Callable) -> void:
	if count <= 0:
		if callback.is_valid():
			callback.call([], false)
		return

	if not callback.is_valid():
		return

	if not AiClient.has_valid_api_key():
		callback.call(get_fallback_questions(count), true)
		return

	var user_message := (
		"Genera exactamente %d preguntas de trivia de primeros auxilios con 4 opciones cada una. "
		+ "Mantén preguntas y opciones muy breves (pregunta max %d chars, opcion max %d chars)."
	) % [count, MAX_QUESTION_CHARS, MAX_OPTION_CHARS]
	var generation_config := build_response_schema(count)

	AiClient.generate_content(
		SYSTEM_PROMPT,
		user_message,
		func(success: bool, text: String, error: String) -> void:
			if success:
				var parsed := parse_and_validate(text, count)
				if parsed.size() == count:
					callback.call(parsed, false)
					return
			callback.call(get_fallback_questions(count), true),
		generation_config
	)


static func parse_and_validate(raw_json: String, expected_count: int) -> Array[Dictionary]:
	var parsed: Variant = JSON.parse_string(raw_json.strip_edges())
	if typeof(parsed) != TYPE_DICTIONARY:
		return []

	var root := parsed as Dictionary
	var items: Variant = root.get("questions", [])
	if typeof(items) != TYPE_ARRAY:
		return []

	var result: Array[Dictionary] = []
	for item_variant: Variant in items as Array:
		var normalized := _normalize_question(item_variant)
		if normalized.is_empty():
			return []
		result.append(normalized)

	if result.size() != expected_count:
		return []

	return result


static func get_fallback_questions(count: int) -> Array[Dictionary]:
	var pool: Array[Dictionary] = []
	for item: Dictionary in FALLBACK_QUESTIONS:
		pool.append(item.duplicate(true))
	pool.shuffle()
	var limit: int = mini(count, pool.size())
	var result: Array[Dictionary] = []
	for i in range(limit):
		result.append(pool[i])
	return result


static func _normalize_question(item_variant: Variant) -> Dictionary:
	if typeof(item_variant) != TYPE_DICTIONARY:
		return {}

	var item := item_variant as Dictionary
	var question_text := _truncate_text(String(item.get("q", "")).strip_edges(), MAX_QUESTION_CHARS)
	if question_text.is_empty():
		return {}

	var ops_variant: Variant = item.get("ops", [])
	if typeof(ops_variant) != TYPE_ARRAY:
		return {}

	var ops_array := ops_variant as Array
	if ops_array.size() != OPTIONS_PER_QUESTION:
		return {}

	var options: Array[String] = []
	for opt_variant: Variant in ops_array:
		var opt_text := _truncate_text(String(opt_variant).strip_edges(), MAX_OPTION_CHARS)
		if opt_text.is_empty():
			return {}
		options.append(opt_text)

	var ans: int = int(item.get("ans", -1))
	if ans < 0 or ans >= OPTIONS_PER_QUESTION:
		return {}

	return {
		"q": question_text,
		"ops": options,
		"ans": ans,
	}


static func _truncate_text(text: String, max_chars: int) -> String:
	if text.length() <= max_chars:
		return text

	var trimmed := text.substr(0, max_chars).strip_edges()
	var last_space := trimmed.rfind(" ")
	if last_space > int(max_chars * 0.5):
		trimmed = trimmed.substr(0, last_space).strip_edges()

	return trimmed + "…"
