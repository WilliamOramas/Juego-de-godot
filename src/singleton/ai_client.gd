extends Node

const CONFIG_PATH: String = "res://ai.cfg"
const DEFAULT_MODEL: String = "gemini-3.5-flash"
const CONTENT_REQUEST_TIMEOUT: float = 12.0

var _api_key: String = ""
var _npc_model: String = DEFAULT_MODEL
var _content_model: String = DEFAULT_MODEL
var _http_request: HTTPRequest
var _content_http_request: HTTPRequest
var _conversation_history: Dictionary = {}
var _current_npc: String = ""
var _content_callback: Callable = Callable()

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_config()
	_http_request = HTTPRequest.new()
	_http_request.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_http_request)
	_http_request.request_completed.connect(_on_npc_request_completed)

	_content_http_request = HTTPRequest.new()
	_content_http_request.process_mode = Node.PROCESS_MODE_ALWAYS
	_content_http_request.timeout = CONTENT_REQUEST_TIMEOUT
	add_child(_content_http_request)
	_content_http_request.request_completed.connect(_on_content_request_completed)


func has_valid_api_key() -> bool:
	return not _api_key.is_empty() and _api_key != "TU_API_KEY_AQUI"


func get_content_model() -> String:
	return _content_model


func get_npc_model() -> String:
	return _npc_model


func _clean_config_value(value: Variant) -> String:
	return String(value).strip_edges().trim_prefix("\"").trim_suffix("\"")


func _load_config() -> void:
	var config := ConfigFile.new()
	if config.load(CONFIG_PATH) != OK:
		push_error("No se pudo cargar ai.cfg.")
		return

	_api_key = _clean_config_value(config.get_value("gemini", "api_key", ""))
	var default_model := _clean_config_value(config.get_value("gemini", "model", DEFAULT_MODEL))
	if default_model.is_empty():
		default_model = DEFAULT_MODEL

	_npc_model = _clean_config_value(config.get_value("gemini", "npc_model", default_model))
	_content_model = _clean_config_value(config.get_value("gemini", "content_model", default_model))

	if _npc_model.is_empty():
		_npc_model = DEFAULT_MODEL
	if _content_model.is_empty():
		_content_model = DEFAULT_MODEL


func _build_api_url(model: String) -> String:
	return "https://generativelanguage.googleapis.com/v1beta/models/%s:generateContent?key=" % model


func generate_npc_response(npc_name: String, user_message: String, system_prompt: String) -> void:
	if _api_key.is_empty() or _api_key == "TU_API_KEY_AQUI":
		EventBus.ai_error_received.emit("API Key no configurada. Revisa ai.cfg.")
		return

	_current_npc = npc_name
	_conversation_history[npc_name] = _conversation_history.get(npc_name, [])
	_conversation_history[npc_name].append({"role": "user", "parts": [{"text": user_message}]})

	var req_data := {
		"systemInstruction": {
			"role": "model",
			"parts": [{"text": system_prompt}],
		},
		"contents": _conversation_history[npc_name],
	}

	if _http_request.request(_build_api_url(_npc_model) + _api_key, ["Content-Type: application/json"], HTTPClient.METHOD_POST, JSON.stringify(req_data)) != OK:
		EventBus.ai_error_received.emit("Error interno al hacer la petición HTTP.")


func generate_content(
	system_prompt: String,
	user_message: String,
	callback: Callable,
	generation_config: Dictionary = {}
) -> void:
	if not callback.is_valid():
		return

	if not has_valid_api_key():
		callback.call(false, "", "API Key no configurada. Revisa ai.cfg.")
		return

	_content_callback = callback

	var req_data := {
		"systemInstruction": {
			"role": "model",
			"parts": [{"text": system_prompt}],
		},
		"contents": [
			{"role": "user", "parts": [{"text": user_message}]},
		],
	}

	if not generation_config.is_empty():
		req_data["generationConfig"] = generation_config

	if _content_http_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		_content_http_request.cancel_request()

	if _content_http_request.request(_build_api_url(_content_model) + _api_key, ["Content-Type: application/json"], HTTPClient.METHOD_POST, JSON.stringify(req_data)) != OK:
		_fail_content_request("Error interno al hacer la petición HTTP.")


func _invoke_content_callback(success: bool, text: String, error: String) -> void:
	if _content_callback.is_valid():
		_content_callback.call(success, text, error)
	_content_callback = Callable()


func _fail_content_request(error: String) -> void:
	_invoke_content_callback(false, "", error)


func _extract_response_text(json_data: Dictionary) -> String:
	var candidates: Array = json_data.get("candidates", [])
	if candidates.is_empty():
		return ""
	var parts: Array = candidates[0].get("content", {}).get("parts", [])
	if parts.is_empty():
		return ""
	return String(parts[0].get("text", ""))


func _is_transient_http_code(response_code: int) -> bool:
	return response_code in [408, 429, 500, 502, 503, 504]


func _log_api_error(response_code: int, response_text: String) -> void:
	var message := "API Error (%d): %s" % [response_code, response_text]
	if _is_transient_http_code(response_code):
		push_warning(message)
		return
	push_error(message)


func _on_npc_request_completed(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	var response_text := body.get_string_from_utf8()
	var parsed_data: Variant = JSON.parse_string(response_text)
	var json_data: Dictionary = parsed_data if typeof(parsed_data) == TYPE_DICTIONARY else {}

	match response_code:
		200:
			var text: String = _extract_response_text(json_data)
			if text.is_empty():
				EventBus.ai_error_received.emit("Respuesta vacía o formato desconocido de la API.")
			else:
				_conversation_history[_current_npc].append({"role": "model", "parts": [{"text": text}]})
				EventBus.ai_response_received.emit(_current_npc, text)
		_:
			var error_msg: String = json_data.get("error", {}).get("message", "Error desconocido")
			_log_api_error(response_code, response_text)
			EventBus.ai_error_received.emit("Error de API (%d): %s" % [response_code, error_msg])


func _http_result_message(result: int) -> String:
	match result:
		HTTPRequest.RESULT_CANT_CONNECT:
			return "No se pudo conectar con la API."
		HTTPRequest.RESULT_CANT_RESOLVE:
			return "No se pudo resolver el host de la API."
		HTTPRequest.RESULT_CONNECTION_ERROR:
			return "Error de conexión con la API."
		HTTPRequest.RESULT_TLS_HANDSHAKE_ERROR:
			return "Error TLS al contactar la API."
		HTTPRequest.RESULT_TIMEOUT:
			return "Tiempo de espera agotado al contactar la API."
		HTTPRequest.RESULT_NO_RESPONSE:
			return "La API no respondió."
		_:
			return "Error de red al contactar la API (código %d)." % result


func _on_content_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS:
		_fail_content_request(_http_result_message(result))
		return

	var response_text := body.get_string_from_utf8()
	var parsed_data: Variant = JSON.parse_string(response_text)
	var json_data: Dictionary = parsed_data if typeof(parsed_data) == TYPE_DICTIONARY else {}

	if response_code != 200:
		var error_msg: String = json_data.get("error", {}).get("message", "Error desconocido")
		if not _is_transient_http_code(response_code):
			_log_api_error(response_code, response_text)
		_fail_content_request("Error de API (%d): %s" % [response_code, error_msg])
		return

	var text: String = _extract_response_text(json_data)
	if text.is_empty():
		_fail_content_request("Respuesta vacía o formato desconocido de la API.")
		return

	_invoke_content_callback(true, text, "")
