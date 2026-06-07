extends Node

const CONFIG_PATH = "res://ai.cfg"
const API_URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-3.5-flash:generateContent?key="

var _api_key: String = ""
var _http_request: HTTPRequest
var _conversation_history: Dictionary = {}
var _current_npc: String = ""

func _ready() -> void:
	_api_key = _load_config()
	_http_request = HTTPRequest.new()
	add_child(_http_request)
	_http_request.request_completed.connect(_on_request_completed)

# Expresión para cargar la configuración de forma funcional
func _load_config() -> String:
	var config := ConfigFile.new()
	if config.load(CONFIG_PATH) != OK:
		push_error("No se pudo cargar ai.cfg.")
		return ""
	return config.get_value("gemini", "api_key", "").strip_edges().trim_prefix("\"").trim_suffix("\"")

func generate_npc_response(npc_name: String, user_message: String, system_prompt: String) -> void:
	if _api_key.is_empty() or _api_key == "TU_API_KEY_AQUI":
		EventBus.ai_error_received.emit("API Key no configurada. Revisa ai.cfg.")
		return

	_current_npc = npc_name

	# Inicialización perezosa / declarativa del historial
	_conversation_history[npc_name] = _conversation_history.get(npc_name, [])

	# Se encapsula el nuevo dato en línea
	_conversation_history[npc_name].append({"role": "user", "parts": [{"text": user_message}]})

	# Construcción de la petición usando diccionarios literales puros
	var req_data := {
		"systemInstruction": {
			"role": "model",
			"parts": [{"text": system_prompt}]
		},
		"contents": _conversation_history[npc_name]
	}

	# Short-circuiting de error
	if _http_request.request(API_URL + _api_key, ["Content-Type: application/json"], HTTPClient.METHOD_POST, JSON.stringify(req_data)) != OK:
		EventBus.ai_error_received.emit("Error interno al hacer la petición HTTP.")

func _on_request_completed(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	var response_text := body.get_string_from_utf8()
	var parsed_data = JSON.parse_string(response_text)
	var json_data: Dictionary = parsed_data if typeof(parsed_data) == TYPE_DICTIONARY else {}

	# Uso de pattern matching y encadenamiento seguro con .get() en lugar de ifs anidados
	match response_code:
		200:
			var candidates: Array = json_data.get("candidates", [])
			var parts: Array = candidates[0].get("content", {}).get("parts", []) if not candidates.is_empty() else []
			var text: String = parts[0].get("text", "") if not parts.is_empty() else ""

			if text.is_empty():
				EventBus.ai_error_received.emit("Respuesta vacía o formato desconocido de la API.")
			else:
				_conversation_history[_current_npc].append({"role": "model", "parts": [{"text": text}]})
				EventBus.ai_response_received.emit(_current_npc, text)
		_:
			var error_msg: String = json_data.get("error", {}).get("message", "Error desconocido")
			push_error("API Error: " + response_text)
			EventBus.ai_error_received.emit("Error de API (%d): %s" % [response_code, error_msg])
