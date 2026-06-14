extends RefCounted

const SupabaseApiScript = preload("res://src/core/infrastructure/supabase/supabase_api.gd")


static func run(runner) -> void:
	runner.run_suite("SupabaseApi", func() -> void:
		_test_endpoints(runner)
		_test_payloads(runner)
	)


static func _test_endpoints(runner) -> void:
	runner.assert_eq(SupabaseApiScript.build_escenarios_endpoint(), "escenarios?select=*")
	runner.assert_eq(
		SupabaseApiScript.build_protocolo_endpoint(2),
		"protocolo_maestro?select=*&id_escenario=eq.2&order=orden_logico"
	)
	runner.assert_eq(
		SupabaseApiScript.build_usuario_patch_endpoint("11111111-1111-1111-1111-111111111111"),
		"usuarios?id_usuario=eq.11111111-1111-1111-1111-111111111111"
	)


static func _test_payloads(runner) -> void:
	var rpc_body = SupabaseApiScript.build_finish_session_rpc_body(42, "Salvado")
	runner.assert_eq(rpc_body["p_id_sesion"], 42)
	runner.assert_eq(rpc_body["p_resultado"], "Salvado")

	var telemetry = SupabaseApiScript.build_telemetry_body(9, "Llamar al 112", false, 3.5, "Crítico")
	runner.assert_eq(telemetry["id_sesion"], 9)
	runner.assert_eq(telemetry["accion_realizada"], "Llamar al 112")
	runner.assert_false(telemetry["es_correcto"])
	runner.assert_eq(telemetry["tiempo_seg"], 3.5)
	runner.assert_eq(telemetry["estado_salud_momento"], "Crítico")

	var cloud_body = SupabaseApiScript.build_cloud_save_body("user-1", {"slot_0": {}})
	runner.assert_eq(cloud_body["user_id"], "user-1")
	runner.assert_true(cloud_body["save_data"].has("slot_0"))
