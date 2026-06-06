extends Node

signal auth_completed(success: bool, message: String)

const CONFIG_PATH: String = "res://supabase.cfg"

var supabase_url: String = ""
var supabase_key: String = ""
var access_token: String = ""
var user_id: String = ""

var _http_request: HTTPRequest
var _is_login_request: bool = true

func _ready() -> void:
	_load_config()
	_http_request = HTTPRequest.new()
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
	if result != HTTPRequest.RESULT_SUCCESS:
		auth_completed.emit(false, "Error de red.")
		return
		
	var response_text = body.get_string_from_utf8()
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
		if typeof(json) == TYPE_DICTIONARY and json.has("error_description"):
			error_msg = json["error_description"]
		elif typeof(json) == TYPE_DICTIONARY and json.has("msg"):
			error_msg = json["msg"]
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
				if typeof(json) == TYPE_DICTIONARY and json.has("message"):
					error_msg = json["message"]
				else:
					error_msg = "Error HTTP %d" % response_code
		else:
			error_msg = "Error de red"
			
		if callback.is_valid():
			callback.call(success, json, error_msg)
			
		http.queue_free() # Auto-destrucción del nodo temporal
	)
	
	var url = supabase_url + "/rest/v1/" + endpoint
	http.request(url, headers, method, body)

func fetch_escenarios(callback: Callable) -> void:
	_send_db_request("escenarios?select=*", HTTPClient.METHOD_GET, "", callback)

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
			callback.call(true, id_sesion, "")
		else:
			callback.call(false, null, error)
	)

func send_telemetry(id_sesion: int, accion: String, es_correcto: bool, tiempo: float, salud: String = "") -> void:
	var data = {
		"id_sesion": id_sesion,
		"accion_realizada": accion,
		"es_correcto": es_correcto,
		"tiempo_seg": tiempo,
		"estado_salud_momento": salud
	}
	_send_db_request("telemetria_eventos", HTTPClient.METHOD_POST, JSON.stringify(data))

func finish_session(id_sesion: int, resultado: String, callback: Callable = Callable()) -> void:
	var data = {
		"resultado": resultado
	}
	_send_db_request("sesiones?id_sesion=eq.%d" % id_sesion, HTTPClient.METHOD_PATCH, JSON.stringify(data), callback)

# --- CLOUD SAVES ---
func push_cloud_saves(save_data: Dictionary, callback: Callable = Callable()) -> void:
	if user_id == "":
		if callback.is_valid(): callback.call(false, null, "No user")
		return
	var data = {
		"user_id": user_id,
		"save_data": save_data
	}
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
