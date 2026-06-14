extends RefCounted

const AiClientScript = preload("res://src/core/infrastructure/ai/ai_client.gd")
const AiMessageScript = preload("res://src/core/models/ai_message.gd")
const GeminiProviderScript = preload("res://src/core/infrastructure/ai/gemini_provider.gd")

static func run(runner) -> void:
	runner.run_suite("AiClient and Providers", func() -> void:
		_test_ai_message(runner)
		_test_client_initialization(runner)
		_test_history_management(runner)
		_test_gemini_format(runner)
	)

static func _test_ai_message(runner) -> void:
	var msg = AiMessageScript.new(AiMessageScript.Role.USER, "Hola")
	runner.assert_eq(msg.role, AiMessageScript.Role.USER)
	runner.assert_eq(msg.content, "Hola")
	runner.assert_eq(msg.get_role_string(), "user")
	
	var sys_msg = AiMessageScript.new(AiMessageScript.Role.SYSTEM, "Act as NPC")
	runner.assert_eq(sys_msg.get_role_string(), "system")

static func _test_client_initialization(runner) -> void:
	var client = AiClientScript.new()
	client._load_provider()
	
	runner.assert_true(client._provider != null, "AiClient debe instanciar un proveedor tras _ready")
	
	if client._provider is GeminiProviderScript:
		runner.assert_true(true, "El proveedor por defecto es Gemini")
	else:
		runner.assert_true(false, "El proveedor debería ser Gemini por fallback o config")
	
	client.free()

static func _test_history_management(runner) -> void:
	var client = AiClientScript.new()
	client._load_provider()
	if client._provider:
		client._provider._ready() # Forzamos _ready del provider para que cree los HTTPRequests
	
	# Simulamos una llamada manual
	client.generate_npc_response("NPC1", "Hola", "System Prompt")
	
	var hist: Array = client._conversation_history.get("NPC1", [])
	runner.assert_eq(hist.size(), 1, "Debe agregar el mensaje de usuario al historial")
	runner.assert_eq(hist[0].content, "Hola")
	runner.assert_eq(hist[0].role, AiMessageScript.Role.USER)
	
	client.free()

static func _test_gemini_format(runner) -> void:
	var gemini = GeminiProviderScript.new("test_key")
	var hist: Array[AIMessage] = [
		AiMessageScript.new(AiMessageScript.Role.USER, "A"),
		AiMessageScript.new(AiMessageScript.Role.ASSISTANT, "B"),
		AiMessageScript.new(AiMessageScript.Role.SYSTEM, "Ignored")
	]
	
	var formatted = gemini._format_history(hist)
	runner.assert_eq(formatted.size(), 2, "Debe ignorar el SYSTEM prompt en el historial directo")
	runner.assert_eq(formatted[0].role, "user")
	runner.assert_eq(formatted[0].parts[0].text, "A")
	runner.assert_eq(formatted[1].role, "model")
	runner.assert_eq(formatted[1].parts[0].text, "B")
