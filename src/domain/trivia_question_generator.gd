class_name TriviaQuestionGenerator
extends RefCounted

const OPTIONS_PER_QUESTION: int = 4
const MAX_QUESTION_CHARS: int = 100
const MAX_OPTION_CHARS: int = 50
const DIFFICULTY_MIN: int = 1
const DIFFICULTY_MEDIUM: int = 2
const DIFFICULTY_HARD: int = 3
const DIFFICULTY_EXTREME: int = 4
const DIFFICULTY_MAX: int = DIFFICULTY_EXTREME
const EXTREME_PICK_CHANCE: float = 0.3
const AI_POOL_SIZE: int = 10

# 1 = fácil, 2 = media, 3 = difícil (mismo orden que FALLBACK_QUESTIONS)
const FALLBACK_DIFFICULTIES: Array[int] = [
	1, 2, 2, 1, 2, 1, 1, 2, 2, 2, 3, 2, 2, 3, 3, 1, 1, 2, 2, 1, 2, 2, 2, 2, 2, 2, 1, 1, 2, 3, 2, 3, 1, 3,
]

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
- El campo ans es el índice 0-3 de la opción correcta en ops.
- El campo difficulty es un entero 1-3 (1=fácil, 2=media, 3=difícil). No uses 4; reservado al juego."""

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
	{
		"q": "Ante una hemorragia nasal leve, ¿qué hacer?",
		"ops": ["Inclinar la cabeza atrás", "Presionar las alas de la nariz", "Meter algodón hondo", "Acostar boca arriba"],
		"ans": 1,
	},
	{
		"q": "Inconsciente pero respira. ¿Qué posición usar?",
		"ops": ["Boca arriba", "Posición lateral de seguridad", "Sentado", "De pie apoyado"],
		"ans": 1,
	},
	{
		"q": "Sospecha de golpe de calor. ¿Primera acción?",
		"ops": ["Dar agua helada", "Llevar a sombra y refrescar", "Cubrir con mantas", "Hacer ejercicio suave"],
		"ans": 1,
	},
	{
		"q": "Sospecha de fractura en un brazo.",
		"ops": ["Moverlo para alinear", "Inmovilizar y no mover", "Masajear la zona", "Aplicar calor intenso"],
		"ans": 1,
	},
	{
		"q": "Mordedura de serpiente. ¿Qué hacer?",
		"ops": ["Succionar el veneno", "Aplicar torniquete", "Inmovilizar y llamar emergencias", "Cortar la herida"],
		"ans": 2,
	},
	{
		"q": "Alguien tiene una convulsión. ¿Qué hacer?",
		"ops": ["Meter algo en la boca", "Sujetar fuerte", "Proteger la cabeza y esperar", "Dar agua al despertar"],
		"ans": 2,
	},
	{
		"q": "Alergia grave con dificultad para respirar.",
		"ops": ["Dar solo agua", "Usar epinefrina si hay autoinyector", "Aplicar hielo en el cuello", "Hacer que corra"],
		"ans": 1,
	},
	{
		"q": "RCP en adultos: profundidad de compresiones.",
		"ops": ["1-2 cm", "Unos 5-6 cm", "10 cm", "Solo tocar el pecho"],
		"ans": 1,
	},
	{
		"q": "Ritmo recomendado para compresiones en RCP.",
		"ops": ["60 por minuto", "100-120 por minuto", "200 por minuto", "Lo más lento posible"],
		"ans": 1,
	},
	{
		"q": "Herida cortante superficial. ¿Primer paso?",
		"ops": ["Limpiar con agua y jabón", "Poner tierra", "Soplar la herida", "Ignorarla siempre"],
		"ans": 0,
	},
	{
		"q": "Partícula pequeña en el ojo. ¿Qué intentar?",
		"ops": ["Frotar fuerte", "Enjuagar con agua limpia", "Usar aceite", "Pinchar con alfiler"],
		"ans": 1,
	},
	{
		"q": "Persona con hipotermia leve. ¿Qué hacer?",
		"ops": ["Frotar vigorosamente", "Quitar ropa mojada y abrigar", "Dar alcohol", "Sumergir en agua fría"],
		"ans": 1,
	},
	{
		"q": "Sospecha de intoxicación. ¿Qué evitar?",
		"ops": ["Llamar a emergencias", "Inducir el vómito siempre", "Identificar la sustancia", "Vigilar la respiración"],
		"ans": 1,
	},
	{
		"q": "Picadura de abeja sin alergia conocida.",
		"ops": ["Raspar el aguijón y aplicar frío", "Pellizcar el aguijón", "Aplicar barro", "Ignorar la hinchazón"],
		"ans": 0,
	},
	{
		"q": "Esguince reciente en el tobillo.",
		"ops": ["Calor y masaje fuerte", "Reposo, hielo y compresión", "Correr para disiparlo", "Alcohol en la piel"],
		"ans": 1,
	},
	{
		"q": "Sospecha de infarto. ¿Primera acción?",
		"ops": ["Hacer que camine", "Llamar emergencias y reposo", "Dar comida", "RCP de inmediato siempre"],
		"ans": 1,
	},
	{
		"q": "Persona en shock (palidez, pulso rápido).",
		"ops": ["Sentarla erguida", "Acostar y elevar piernas", "Dar café", "Dar de comer"],
		"ans": 1,
	},
	{
		"q": "Ahogamiento: persona consciente tras salir del agua.",
		"ops": ["Dar de beber agua", "Mantener calor y vigilar", "Hacer correr", "Ignorar si tose"],
		"ans": 1,
	},
	{
		"q": "Diabético mareado y muy sudoroso.",
		"ops": ["Dar azúcar si está consciente", "Dar insulina siempre", "Dejarlo solo", "Hacer ejercicio"],
		"ans": 0,
	},
	{
		"q": "Golpe fuerte en la cabeza con confusión.",
		"ops": ["Dejar dormir de inmediato", "Vigilar y buscar ayuda médica", "Dar aspirina", "Menear para despertar"],
		"ans": 1,
	},
	{
		"q": "La ropa de alguien se prende fuego.",
		"ops": ["Correr para apagarlo", "Detener, tirar y enrollar", "Abanicar con las manos", "Echar agua fría"],
		"ans": 1,
	},
	{
		"q": "Atragantamiento leve: la persona tose.",
		"ops": ["Heimlich de inmediato", "Animar a toser y vigilar", "Dar agua", "Golpes fuertes en espalda"],
		"ans": 1,
	},
	{
		"q": "Salpicadura de químico en la piel.",
		"ops": ["Neutralizar con otro químico", "Enjuagar con mucha agua", "Cubrir con aceite", "Frotar la zona"],
		"ans": 1,
	},
	{
		"q": "¿Cuándo usar un torniquete?",
		"ops": ["En cualquier herida", "Solo en hemorragia muy severa", "En heridas leves", "En quemaduras"],
		"ans": 1,
	},
	{
		"q": "Persona no respira y está inconsciente.",
		"ops": ["Esperar a que despierte", "Llamar emergencias e iniciar RCP", "Dar agua", "Sentarla"],
		"ans": 1,
	},
	{
		"q": "Herida con objeto clavado en el cuerpo.",
		"ops": ["Retirar el objeto", "Inmovilizar sin quitar el objeto", "Empujar el objeto", "Lavar con alcohol"],
		"ans": 1,
	},
	{
		"q": "Mordedura de perro. ¿Primer cuidado?",
		"ops": ["Suturar en casa", "Lavar con agua y jabón", "Ignorar si es pequeña", "Aplicar barro"],
		"ans": 1,
	},
	{
		"q": "¿Qué revisar antes de RCP en un adulto?",
		"ops": ["Pulso y respiración", "Solo el color de piel", "Solo la temperatura", "Nada, comprimir ya"],
		"ans": 0,
	},
]

# Nivel 4: trampa educativa, escaso y solo tras racha de aciertos
const FALLBACK_TRAP_QUESTIONS: Array[Dictionary] = [
	{
		"q": "¿Se puede dar agua a alguien inconsciente?",
		"ops": ["Sí, para hidratar", "No, riesgo de atragantamiento", "Solo si la pide", "Sí, con azúcar"],
		"ans": 1,
		"difficulty": DIFFICULTY_EXTREME,
	},
	{
		"q": "Quemadura con ropa pegada. ¿Qué hacer?",
		"ops": ["Quitar la ropa de golpe", "No retirar ropa adherida", "Raspar con cuchillo", "Aplicar crema"],
		"ans": 1,
		"difficulty": DIFFICULTY_EXTREME,
	},
	{
		"q": "Hemorragia nasal: ¿cabeza atrás o adelante?",
		"ops": ["Atrás para frenar sangre", "Ligeramente adelante", "De lado únicamente", "Da igual la postura"],
		"ans": 1,
		"difficulty": DIFFICULTY_EXTREME,
	},
	{
		"q": "¿Dar aspirina ante sospecha de infarto?",
		"ops": ["Nunca en ningún caso", "Sí, si está consciente y no es alérgico", "Solo si es menor", "Siempre sin preguntar"],
		"ans": 1,
		"difficulty": DIFFICULTY_EXTREME,
	},
	{
		"q": "RCP: ¿cuándo parar las compresiones?",
		"ops": ["A los 30 segundos fijos", "Si responde o llega ayuda especializada", "Tras 10 compresiones", "Nunca, hasta agotarse"],
		"ans": 1,
		"difficulty": DIFFICULTY_EXTREME,
	},
	{
		"q": "Convulsión: ¿meter algo en la boca?",
		"ops": ["Sí, un pañuelo", "No, proteger la cabeza", "Sí, una cuchara", "Sí, para morder"],
		"ans": 1,
		"difficulty": DIFFICULTY_EXTREME,
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
							"difficulty": {"type": "integer"},
						},
						"required": ["q", "ops", "ans", "difficulty"],
					},
					"minItems": question_count,
					"maxItems": question_count,
				},
			},
			"required": ["questions"],
		},
	}


static func fetch_session_pool(callback: Callable) -> void:
	if not callback.is_valid():
		return

	if not AiClient.has_valid_api_key():
		callback.call(get_fallback_pool(), true)
		return

	var user_message := (
		"Genera exactamente %d preguntas de trivia de primeros auxilios con 4 opciones cada una. "
		+ "Mantén preguntas y opciones muy breves (pregunta max %d chars, opcion max %d chars). "
		+ "Incluye difficulty 1-3 variada."
	) % [AI_POOL_SIZE, MAX_QUESTION_CHARS, MAX_OPTION_CHARS]
	var generation_config := build_response_schema(AI_POOL_SIZE)

	AiClient.generate_content(
		SYSTEM_PROMPT,
		user_message,
		func(success: bool, text: String, _error: String) -> void:
			if success:
				var parsed := parse_pool(text, OPTIONS_PER_QUESTION)
				if not parsed.is_empty():
					callback.call(parsed, false)
					return
			callback.call(get_fallback_pool(), true),
		generation_config
	)


static func fetch_questions(count: int, callback: Callable) -> void:
	fetch_session_pool(func(pool: Array, used_fallback: bool) -> void:
		if not callback.is_valid():
			return
		var limit := mini(count, pool.size())
		var result: Array[Dictionary] = []
		for i in range(limit):
			if typeof(pool[i]) == TYPE_DICTIONARY:
				result.append(pool[i] as Dictionary)
		callback.call(result, used_fallback)
	)


static func parse_pool(raw_json: String, min_count: int) -> Array[Dictionary]:
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
			continue
		result.append(normalized)

	if result.size() < min_count:
		return []

	return result


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


static func get_fallback_pool() -> Array[Dictionary]:
	var pool: Array[Dictionary] = []
	for i in range(FALLBACK_QUESTIONS.size()):
		pool.append(_duplicate_fallback_item(i))
	for item: Dictionary in FALLBACK_TRAP_QUESTIONS:
		pool.append(item.duplicate(true))
	pool.shuffle()
	return pool


static func get_fallback_questions(count: int) -> Array[Dictionary]:
	var pool := get_fallback_pool()
	var limit: int = mini(count, pool.size())
	var result: Array[Dictionary] = []
	for i in range(limit):
		result.append(pool[i])
	return result


static func question_key(question: Dictionary) -> String:
	return String(question.get("q", "")).strip_edges()


static func get_difficulty(question: Dictionary) -> int:
	return clampi(int(question.get("difficulty", DIFFICULTY_MEDIUM)), DIFFICULTY_MIN, DIFFICULTY_MAX)


static func pick_question(
	pool: Array,
	used_keys: Array[String],
	max_difficulty: int,
	allow_extreme: bool = false
) -> Dictionary:
	var hard_cap := DIFFICULTY_EXTREME if allow_extreme else DIFFICULTY_HARD
	var capped_difficulty := clampi(max_difficulty, DIFFICULTY_MIN, hard_cap)

	if allow_extreme and capped_difficulty >= DIFFICULTY_EXTREME:
		var extreme_only := _filter_unused_pool(
			pool,
			used_keys,
			DIFFICULTY_EXTREME,
			DIFFICULTY_EXTREME
		)
		if not extreme_only.is_empty() and randf() < EXTREME_PICK_CHANCE:
			extreme_only.shuffle()
			return (extreme_only[0] as Dictionary).duplicate(true)

	var eligible := _filter_unused_pool(
		pool,
		used_keys,
		mini(capped_difficulty, DIFFICULTY_HARD)
	)
	if eligible.is_empty():
		eligible = _filter_unused_pool(pool, used_keys, hard_cap)
	if eligible.is_empty():
		return {}

	eligible.shuffle()
	return (eligible[0] as Dictionary).duplicate(true)


static func _duplicate_fallback_item(index: int) -> Dictionary:
	var item := FALLBACK_QUESTIONS[index].duplicate(true)
	var difficulty := DIFFICULTY_MEDIUM
	if index < FALLBACK_DIFFICULTIES.size():
		difficulty = FALLBACK_DIFFICULTIES[index]
	item["difficulty"] = clampi(difficulty, DIFFICULTY_MIN, DIFFICULTY_HARD)
	return item


static func _filter_unused_pool(
	pool: Array,
	used_keys: Array[String],
	max_difficulty: int,
	min_difficulty: int = DIFFICULTY_MIN
) -> Array[Dictionary]:
	var eligible: Array[Dictionary] = []
	for item_variant: Variant in pool:
		if typeof(item_variant) != TYPE_DICTIONARY:
			continue
		var item := item_variant as Dictionary
		var key := question_key(item)
		if key.is_empty() or key in used_keys:
			continue
		var level := get_difficulty(item)
		if level < min_difficulty or level > max_difficulty:
			continue
		eligible.append(item)
	return eligible


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

	var difficulty := clampi(int(item.get("difficulty", DIFFICULTY_MEDIUM)), DIFFICULTY_MIN, DIFFICULTY_HARD)

	return {
		"q": question_text,
		"ops": options,
		"ans": ans,
		"difficulty": difficulty,
	}


static func _truncate_text(text: String, max_chars: int) -> String:
	if text.length() <= max_chars:
		return text

	var trimmed := text.substr(0, max_chars).strip_edges()
	var last_space := trimmed.rfind(" ")
	if last_space > int(max_chars * 0.5):
		trimmed = trimmed.substr(0, last_space).strip_edges()

	return trimmed + "…"
