class_name GeminiProvider
extends AiProvider

const DEFAULT_MODEL: String = "gemini-1.5-flash"
const CONTENT_REQUEST_TIMEOUT: float = 12.0

var api_key: String = ""
var npc_model: String = DEFAULT_MODEL
var content_model: String = DEFAULT_MODEL

var _npc_http: HTTPRequest
var _content_http: HTTPRequest

var _pending_npc_request: String = ""
var _pending_content_callback: Callable = Callable()

func _init(_api_key: String, _npc_model: String = DEFAULT_MODEL, _content_model: String = DEFAULT_MODEL) -> void:
	api_key = _api_key
	npc_model = _npc_model
	content_model = _content_model
	
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_npc_http = HTTPRequest.new()
	_npc_http.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_npc_http)
	_npc_http.request_completed.connect(_on_npc_request_completed)
	
	_content_http = HTTPRequest.new()
	_content_http.process_mode = Node.PROCESS_MODE_ALWAYS
	_content_http.timeout = CONTENT_REQUEST_TIMEOUT
	add_child(_content_http)
	_content_http.request_completed.connect(_on_content_request_completed)

func is_configured() -> bool:
	return not api_key.is_empty() and api_key != "TU_API_KEY_AQUI"

func _build_api_url(model: String) -> String:
	return "https://generativelanguage.googleapis.com/v1beta/models/%s:generateContent?key=" % model

# Convierte AIMessage a formato Gemini
func _format_history(history: Array[AIMessage]) -> Array:
	var formatted: Array = []
	for msg in history:
		var role_str := "user"
		if msg.role == AIMessage.Role.ASSISTANT:
			role_str = "model"
		
		# Gemini no soporta el rol "system" en el history standard, se ignora aquí porque se pasa por separado.
		if msg.role != AIMessage.Role.SYSTEM:
			formatted.append({"role": role_str, "parts": [{"text": msg.content}]})
	return formatted

func generate_npc_response(npc_name: String, system_prompt: String, history: Array[AIMessage]) -> void:
	if not is_configured():
		request_completed.emit(false, "", "API Key de Gemini no configurada.", Callable(), npc_name)
		return
		
	_pending_npc_request = npc_name
	var req_data := {
		"systemInstruction": {
			"role": "model",
			"parts": [{"text": system_prompt}],
		},
		"contents": _format_history(history),
	}
	
	if _npc_http.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		_npc_http.cancel_request()

	if _npc_http.request(_build_api_url(npc_model) + api_key, ["Content-Type: application/json"], HTTPClient.METHOD_POST, JSON.stringify(req_data)) != OK:
		request_completed.emit(false, "", "Error interno al hacer la petición HTTP a Gemini.", Callable(), npc_name)

func generate_content(system_prompt: String, user_message: String, generation_config: Dictionary, callback: Callable) -> void:
	if not callback.is_valid():
		return

	if not is_configured():
		callback.call(false, "", "API Key de Gemini no configurada.")
		return

	_pending_content_callback = callback
	
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

	if _content_http.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		_content_http.cancel_request()

	if _content_http.request(_build_api_url(content_model) + api_key, ["Content-Type: application/json"], HTTPClient.METHOD_POST, JSON.stringify(req_data)) != OK:
		request_completed.emit(false, "", "Error interno al hacer la petición HTTP a Gemini.", _pending_content_callback, "")
		_pending_content_callback = Callable()

func cancel_requests() -> void:
	if _npc_http and _npc_http.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		_npc_http.cancel_request()
	if _content_http and _content_http.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		_content_http.cancel_request()

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

func _on_npc_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	var npc := _pending_npc_request
	
	if result != HTTPRequest.RESULT_SUCCESS:
		request_completed.emit(false, "", "Error de conexión con la API de Gemini.", Callable(), npc)
		return
		
	var response_text := body.get_string_from_utf8()
	var parsed_data: Variant = JSON.parse_string(response_text)
	var json_data: Dictionary = parsed_data if typeof(parsed_data) == TYPE_DICTIONARY else {}

	match response_code:
		200:
			var text: String = _extract_response_text(json_data)
			if text.is_empty():
				request_completed.emit(false, "", "Respuesta vacía o formato desconocido de Gemini.", Callable(), npc)
			else:
				request_completed.emit(true, text, "", Callable(), npc)
		_:
			var error_msg: String = json_data.get("error", {}).get("message", "Error desconocido")
			request_completed.emit(false, "", "Error de API Gemini (%d): %s" % [response_code, error_msg], Callable(), npc)

func _on_content_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	var cb := _pending_content_callback
	_pending_content_callback = Callable()
	
	if not cb.is_valid():
		return
		
	if result != HTTPRequest.RESULT_SUCCESS:
		request_completed.emit(false, "", "Error de red al contactar la API de Gemini.", cb, "")
		return

	var response_text := body.get_string_from_utf8()
	var parsed_data: Variant = JSON.parse_string(response_text)
	var json_data: Dictionary = parsed_data if typeof(parsed_data) == TYPE_DICTIONARY else {}

	if response_code != 200:
		var error_msg: String = json_data.get("error", {}).get("message", "Error desconocido")
		request_completed.emit(false, "", "Error de API Gemini (%d): %s" % [response_code, error_msg], cb, "")
		return

	var text: String = _extract_response_text(json_data)
	if text.is_empty():
		request_completed.emit(false, "", "Respuesta vacía o formato desconocido de Gemini.", cb, "")
		return

	request_completed.emit(true, text, "", cb, "")
