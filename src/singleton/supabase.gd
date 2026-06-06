extends Node

signal auth_completed(success: bool, message: String)

const CONFIG_PATH: String = "res://supabase.cfg"

var supabase_url: String = ""
var supabase_key: String = ""
var access_token: String = ""

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

func _on_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS:
		auth_completed.emit(false, "Error de red.")
		return
		
	var response_text = body.get_string_from_utf8()
	var json = JSON.parse_string(response_text)
	
	if response_code >= 200 and response_code < 300:
		if typeof(json) == TYPE_DICTIONARY and json.has("access_token") and _is_login_request:
			access_token = json["access_token"]
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
