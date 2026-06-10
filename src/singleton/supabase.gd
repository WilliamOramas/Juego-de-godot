extends Node

signal auth_completed(success: bool, message: String)

const CONFIG_PATH: String = "res://supabase.cfg"

var supabase_url: String = ""
var supabase_key: String = ""
var access_token: String = ""
var user_id: String = ""
var current_session_id: int = -1

var _http_request: HTTPRequest
var _is_login_request: bool = true

func _ready() -> void:
	_load_config()
	_http_request = HTTPRequest.new()
	_http_request.timeout = 10
	add_child(_http_request)
	_http_request.request_completed.connect(_on_request_completed)

func _load_config() -> void:
	var config = ConfigFile.new()
	var err = config.load(CONFIG_PATH)
	if err == OK:
		supabase_url = config.get_value("supabase", "url", "")
		supabase_key = config.get_value("supabase", "key", "")
	else:
		push_warning("Supabase: No se encontró supabase.cfg. Por favor crea el archivo con la url y key de tu proyecto.")

func _get_headers() -> PackedStringArray:
	var headers = PackedStringArray([
		"apikey: " + supabase_key,
		"Content-Type: application/json"
	])
	if access_token != "":
		headers.append("Authorization: Bearer " + access_token)
	return headers

func is_logged_in() -> bool:
	return access_token != ""

func logout() -> void:
	access_token = ""
	user_id = ""
	current_session_id = -1

func login(email: String, password: String) -> void:
	_is_login_request = true
	if supabase_url == "" or supabase_key == "":
		auth_completed.emit(false, "Faltan las credenciales de Supabase en supabase.cfg")
		return
		
	var url = supabase_url + "/auth/v1/token?grant_type=password"
	var body = JSON.stringify({
		"email": email,
		"password": password
	})
	
	var err = _http_request.request(url, _get_headers(), HTTPClient.METHOD_POST, body)
	if err != OK:
		auth_completed.emit(false, "Error al enviar petición HTTP")

func register(email: String, password: String) -> void:
	_is_login_request = false
	if supabase_url == "" or supabase_key == "":
		auth_completed.emit(false, "Faltan las credenciales de Supabase en supabase.cfg")
		return
		
	var url = supabase_url + "/auth/v1/signup"
	var body = JSON.stringify({
		"email": email,
		"password": password
	})
	
	var err = _http_request.request(url, _get_headers(), HTTPClient.METHOD_POST, body)
	if err != OK:
		auth_completed.emit(false, "Error al enviar petición HTTP")

func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	match result:
		HTTPRequest.RESULT_TIMEOUT:
			auth_completed.emit(false, "La conexión tardó demasiado. Revisa tu internet.")
			return
		HTTPRequest.RESULT_CONNECTION_ERROR:
			auth_completed.emit(false, "No se pudo conectar al servidor.")
			return
		HTTPRequest.RESULT_BODY_SIZE_LIMIT_EXCEEDED:
			auth_completed.emit(false, "La respuesta del servidor es demasiado grande.")
			return
		HTTPRequest.RESULT_CANT_CONNECT:
			auth_completed.emit(false, "No se pudo establecer conexión con el servidor.")
			return
		HTTPRequest.RESULT_CANT_RESOLVE:
			auth_completed.emit(false, "No se pudo resolver la dirección del servidor.")
			return
		HTTPRequest.RESULT_REQUEST_FAILED:
			auth_completed.emit(false, "La petición falló.")
			return
		HTTPRequest.RESULT_SUCCESS:
			pass
		_:
			auth_completed.emit(false, "Error de red inesperado.")
			return

	var response_text := body.get_string_from_utf8()
	if response_text == "" and body.size() > 0:
		auth_completed.emit(false, "Respuesta inválida del servidor.")
		return

	var json = JSON.parse_string(response_text)
	
	if response_code >= 200 and response_code < 300:
		if typeof(json) == TYPE_DICTIONARY and json.has("access_token") and _is_login_request:
			access_token = json["access_token"]
			if json.has("user") and typeof(json["user"]) == TYPE_DICTIONARY and json["user"].has("id"):
				user_id = json["user"]["id"]
			auth_completed.emit(true, "Operación exitosa.")
		else:
			# For register
			auth_completed.emit(true, "Te hemos enviado un correo de verificación.")
	else:
		var error_msg = "Error desconocido"
		if typeof(json) == TYPE_DICTIONARY:
			error_msg = json.get("error_description", json.get("msg", json.get("message", error_msg)))
		if error_msg == "Error desconocido":
			if response_code == 400: error_msg = "Solicitud inválida. Revisa tus datos."
			elif response_code == 401: error_msg = "Credenciales incorrectas."
			elif response_code == 403: error_msg = "Acceso denegado."
			elif response_code == 404: error_msg = "Servicio no encontrado."
			elif response_code >= 500: error_msg = "Error interno del servidor. Intenta más tarde."
		auth_completed.emit(false, error_msg)

# ==========================================
# BASE DE DATOS REST API (Supabase PostgREST)
# ==========================================

func _send_db_request(endpoint: String, method: int, body: String = "", callback: Callable = Callable(), extra_headers: PackedStringArray = PackedStringArray()) -> void:
	if supabase_url == "" or supabase_key == "":
		if callback.is_valid():
			callback.call(false, null, "Faltan credenciales")
		return
		
	var http = HTTPRequest.new()
	add_child(http)
	
	var headers = PackedStringArray([
		"apikey: " + supabase_key,
		"Content-Type: application/json"
	])
	
	if access_token != "":
		headers.append("Authorization: Bearer " + access_token)
		
	# Para insert y updates, pedir que devuelva el registro modificado
	if method == HTTPClient.METHOD_POST or method == HTTPClient.METHOD_PATCH:
		headers.append("Prefer: return=representation")
		
	if extra_headers.size() > 0:
		headers.append_array(extra_headers)

	http.request_completed.connect(func(result, response_code, _resp_headers, resp_body):
		var success = result == HTTPRequest.RESULT_SUCCESS and response_code >= 200 and response_code < 300
		var json = null
		var error_msg = ""
		
		if result == HTTPRequest.RESULT_SUCCESS:
			var text = resp_body.get_string_from_utf8()
			if text != "":
				json = JSON.parse_string(text)
			if not success:
				error_msg = json.get("message", "Error HTTP %d" % response_code) if typeof(json) == TYPE_DICTIONARY else "Error HTTP %d" % response_code
		else:
			error_msg = "Error de red"
			
		if callback.is_valid():
			callback.call(success, json, error_msg)
			
		http.queue_free() # Auto-destrucción del nodo temporal
	)
	
	var url = supabase_url + "/rest/v1/" + endpoint
	http.request(url, headers, method, body)

func fetch_escenarios(callback: Callable) -> void:
	_send_db_request(SupabaseApi.build_escenarios_endpoint(), HTTPClient.METHOD_GET, "", callback)

func fetch_protocolo(id_escenario: int, callback: Callable) -> void:
	_send_db_request(SupabaseApi.build_protocolo_endpoint(id_escenario), HTTPClient.METHOD_GET, "", callback)

func upsert_usuario(nombre: String, carrera: String = "", callback: Callable = Callable()) -> void:
	if user_id == "":
		if callback.is_valid():
			callback.call(false, null, "No hay usuario activo")
		return
	var carrera_val: Variant
	if carrera != "":
		carrera_val = carrera
	else:
		carrera_val = null
	var data := {
		"nombre": nombre,
		"carrera": carrera_val,
	}
	_send_db_request(
		SupabaseApi.build_usuario_patch_endpoint(user_id),
		HTTPClient.METHOD_PATCH,
		JSON.stringify(data),
		callback
	)

func start_session(id_escenario: int, callback: Callable) -> void:
	if user_id == "":
		callback.call(false, null, "No hay usuario activo")
		return
		
	var data = {
		"id_usuario": user_id,
		"id_escenario": id_escenario
	}
	_send_db_request("sesiones", HTTPClient.METHOD_POST, JSON.stringify(data), func(success, resp_json, error):
		if success and typeof(resp_json) == TYPE_ARRAY and resp_json.size() > 0:
			var id_sesion = resp_json[0]["id_sesion"]
			current_session_id = int(id_sesion)
			callback.call(true, id_sesion, "")
		else:
			callback.call(false, null, error)
	)

func send_telemetry(id_sesion: int, accion: String, es_correcto: bool, tiempo: float, salud: String = "") -> void:
	var data := SupabaseApi.build_telemetry_body(id_sesion, accion, es_correcto, tiempo, salud)
	_send_db_request("telemetria_eventos", HTTPClient.METHOD_POST, JSON.stringify(data))

func finish_session(id_sesion: int, resultado: String, callback: Callable = Callable()) -> void:
	var data := SupabaseApi.build_finish_session_rpc_body(id_sesion, resultado)
	_send_db_request("rpc/finalizar_sesion_transaccional", HTTPClient.METHOD_POST, JSON.stringify(data), func(success, resp_data, error):
		current_session_id = -1
		if callback.is_valid():
			callback.call(success, resp_data, error)
	)

# --- CLOUD SAVES ---
func push_cloud_saves(save_data: Dictionary, callback: Callable = Callable()) -> void:
	if user_id == "":
		if callback.is_valid(): callback.call(false, null, "No user")
		return
	var data := SupabaseApi.build_cloud_save_body(user_id, save_data)
	# Utilizamos resolution=merge-duplicates para hacer un UPSERT (Insert o Update si ya existe)
	_send_db_request("cloud_saves", HTTPClient.METHOD_POST, JSON.stringify(data), callback, PackedStringArray(["Prefer: resolution=merge-duplicates"]))

func pull_cloud_saves(callback: Callable) -> void:
	if user_id == "":
		callback.call(false, null, "No user")
		return
	_send_db_request("cloud_saves?select=save_data&user_id=eq.%s" % user_id, HTTPClient.METHOD_GET, "", func(success, resp_json, error):
		if success and typeof(resp_json) == TYPE_ARRAY and resp_json.size() > 0:
			callback.call(true, resp_json[0]["save_data"], "")
		else:
			callback.call(false, null, error)
	)
