class_name SupabaseApi
extends RefCounted

static func build_escenarios_endpoint() -> String:
	return "escenarios?select=*"


static func build_protocolo_endpoint(id_escenario: int) -> String:
	return "protocolo_maestro?select=*&id_escenario=eq.%d&order=orden_logico" % id_escenario


static func build_usuario_patch_endpoint(user_id: String) -> String:
	return "usuarios?id_usuario=eq.%s" % user_id


static func build_finish_session_rpc_body(id_sesion: int, resultado: String) -> Dictionary:
	return {
		"p_id_sesion": id_sesion,
		"p_resultado": resultado,
	}


static func build_telemetry_body(
	id_sesion: int,
	accion: String,
	es_correcto: bool,
	tiempo: float,
	salud: String = ""
) -> Dictionary:
	return {
		"id_sesion": id_sesion,
		"accion_realizada": accion,
		"es_correcto": es_correcto,
		"tiempo_seg": tiempo,
		"estado_salud_momento": salud,
	}


static func build_cloud_save_body(user_id: String, save_data: Dictionary) -> Dictionary:
	return {
		"user_id": user_id,
		"save_data": save_data,
	}
