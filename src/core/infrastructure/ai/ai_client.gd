extends Node

## AiClient
## Wrapper / Director genérico que delega las peticiones de IA al proveedor seleccionado.

const CONFIG_PATH: String = "res://config.cfg"

var _provider: AiProvider
var _conversation_history: Dictionary = {}
var _current_npc: String = ""

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_provider()

func _clean_config_value(value: Variant) -> String:
	return String(value).strip_edges().trim_prefix("\"").trim_suffix("\"")

func _load_provider() -> void:
	var config := ConfigFile.new()
	if config.load(CONFIG_PATH) != OK:
		push_error("No se pudo cargar config.cfg.")
		_fallback_to_gemini("", "", "")
		return

	var provider_name = _clean_config_value(config.get_value("ai", "provider", "gemini")).to_lower()
	
	if provider_name == "gemini":
		var api_key = _clean_config_value(config.get_value("gemini", "api_key", ""))
		var default_model = _clean_config_value(config.get_value("gemini", "model", "gemini-1.5-flash"))
		var npc_model = _clean_config_value(config.get_value("gemini", "npc_model", default_model))
		var content_model = _clean_config_value(config.get_value("gemini", "content_model", default_model))
		_fallback_to_gemini(api_key, npc_model, content_model)
	else:
		push_error("Proveedor de IA desconocido: " + provider_name)
		_fallback_to_gemini("", "", "")

func _fallback_to_gemini(api_key: String, npc_model: String, content_model: String) -> void:
	var GeminiScript = load("res://src/core/infrastructure/ai/gemini_provider.gd")
	if npc_model.is_empty(): npc_model = "gemini-1.5-flash"
	if content_model.is_empty(): content_model = "gemini-1.5-flash"
	_provider = GeminiScript.new(api_key, npc_model, content_model)
	add_child(_provider)
	_provider.request_completed.connect(_on_provider_request_completed)

func get_content_model() -> String:
	if _provider and "content_model" in _provider:
		return _provider.content_model
	if _provider:
		return "Activo"
	return "Desconocido"

func has_valid_api_key() -> bool:
	if not _provider: return false
	return _provider.is_configured()

func generate_npc_response(npc_name: String, user_message: String, system_prompt: String) -> void:
	if not _provider or not _provider.is_configured():
		EventBus.ai_error_received.emit("API Key no configurada. Revisa config.cfg.")
		return

	_current_npc = npc_name
	if not _conversation_history.has(npc_name):
		_conversation_history[npc_name] = [] as Array[AIMessage]
		
	var hist: Array[AIMessage] = _conversation_history[npc_name]
	hist.append(AIMessage.new(AIMessage.Role.USER, user_message))

	_provider.generate_npc_response(npc_name, system_prompt, hist)

func generate_content(
	system_prompt: String,
	user_message: String,
	callback: Callable,
	generation_config: Dictionary = {}
) -> void:
	if not callback.is_valid():
		return

	if not _provider or not _provider.is_configured():
		callback.call(false, "", "API Key no configurada. Revisa config.cfg.")
		return

	_provider.generate_content(system_prompt, user_message, generation_config, callback)

func _on_provider_request_completed(success: bool, text: String, error_msg: String, custom_callback: Callable, npc_name: String) -> void:
	if custom_callback.is_valid():
		# Flujo de Content Request (Callbacks directos)
		if not success:
			push_error("[AiClient] Petición directa falló: " + error_msg)
		custom_callback.call(success, text, error_msg)
		return
	else:
		# Flujo de NPC (EventBus)
		if success:
			var hist: Array[AIMessage] = _conversation_history.get(npc_name, [])
			hist.append(AIMessage.new(AIMessage.Role.ASSISTANT, text))
			EventBus.ai_response_received.emit(npc_name, text)
		else:
			push_error("[AiClient] Petición de NPC ('" + npc_name + "') falló: " + error_msg)
			EventBus.ai_error_received.emit(error_msg)
