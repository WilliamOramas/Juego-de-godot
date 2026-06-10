-- =============================================================================
-- Vital Pixel — Consultas de verificación (antes y después de la migración)
-- =============================================================================

-- Estado general de tablas
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY 1;

-- Datos maestros
SELECT * FROM public.escenarios ORDER BY id_escenario;

SELECT id_escenario, orden_logico, descripcion, penalizacion_tiempo
FROM public.protocolo_maestro
ORDER BY id_escenario, orden_logico;

-- Perfiles vinculados a auth
SELECT u.id_usuario, u.nombre, u.carrera, u.fecha_registro, a.email
FROM public.usuarios u
JOIN auth.users a ON a.id = u.id_usuario;

-- Sesiones recientes
SELECT s.id_sesion, e.nombre AS escenario, s.puntaje_final, s.resultado, s.fecha_hora
FROM public.sesiones s
JOIN public.escenarios e USING (id_escenario)
ORDER BY s.fecha_hora DESC
LIMIT 10;

-- Telemetría reciente
SELECT t.id_evento, t.accion_realizada, t.es_correcto, t.tiempo_seg, s.id_sesion
FROM public.telemetria_eventos t
JOIN public.sesiones s USING (id_sesion)
ORDER BY t.id_evento DESC
LIMIT 20;

-- Cloud saves y redistribución
SELECT user_id, jsonb_object_keys(save_data) AS slot_key
FROM public.cloud_saves;

SELECT * FROM public.progreso_resumen
ORDER BY actualizado_en DESC;

-- Vista demo para presentación
SELECT * FROM public.v_dashboard_jugador
ORDER BY fecha_hora DESC
LIMIT 20;

-- Triggers activos
SELECT tgname, relname AS tabla
FROM pg_trigger t
JOIN pg_class c ON c.oid = t.tgrelid
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'public'
  AND NOT t.tgisinternal
ORDER BY relname, tgname;
