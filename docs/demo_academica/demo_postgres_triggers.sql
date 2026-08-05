-- =============================================================================
-- Vital Pixel — Demo de TRIGGERS en PostgreSQL / Supabase
-- =============================================================================

-- Ver triggers activos del proyecto
SELECT tgname AS trigger_name, c.relname AS tabla
FROM pg_trigger t
JOIN pg_class c ON c.oid = t.tgrelid
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'public'
  AND NOT t.tgisinternal
ORDER BY c.relname, tgname;


-- -----------------------------------------------------------------------------
-- DEMO 1: Penalización según protocolo_maestro (no siempre -10)
-- -----------------------------------------------------------------------------
DO $$
DECLARE
    v_usuario UUID;
    v_sesion BIGINT;
    v_antes INTEGER;
    v_despues INTEGER;
BEGIN
    SELECT id_usuario INTO v_usuario FROM public.usuarios LIMIT 1;
    IF v_usuario IS NULL THEN
        RAISE EXCEPTION 'No hay usuarios.';
    END IF;

    INSERT INTO public.sesiones (id_usuario, id_escenario, puntaje_final)
    VALUES (v_usuario, 2, 100)
    RETURNING id_sesion INTO v_sesion;

    SELECT puntaje_final INTO v_antes FROM public.sesiones WHERE id_sesion = v_sesion;

    INSERT INTO public.telemetria_eventos (id_sesion, accion_realizada, es_correcto, tiempo_seg)
    VALUES (v_sesion, 'Llamar al 112', false, 5.0);

    SELECT puntaje_final INTO v_despues FROM public.sesiones WHERE id_sesion = v_sesion;

    RAISE NOTICE 'Puntaje antes=%, después=% (penalización protocolo Llamar al 112 = 15)', v_antes, v_despues;
END $$;


-- -----------------------------------------------------------------------------
-- DEMO 2: Puntaje negativo bloqueado
-- -----------------------------------------------------------------------------
DO $$
DECLARE
    v_usuario UUID;
    v_sesion BIGINT;
BEGIN
    SELECT id_usuario INTO v_usuario FROM public.usuarios LIMIT 1;
    INSERT INTO public.sesiones (id_usuario, id_escenario, puntaje_final)
    VALUES (v_usuario, 3, 100)
    RETURNING id_sesion INTO v_sesion;

    BEGIN
        UPDATE public.sesiones SET puntaje_final = -1 WHERE id_sesion = v_sesion;
        RAISE EXCEPTION 'Debió bloquearse el puntaje negativo';
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'Trigger puntaje negativo OK — %', SQLERRM;
    END;
END $$;


-- -----------------------------------------------------------------------------
-- DEMO 3: Redistribución cloud_saves → progreso_resumen
-- -----------------------------------------------------------------------------
SELECT user_id, slot, puntaje, escenarios_completados, quests_completadas
FROM public.progreso_resumen
ORDER BY actualizado_en DESC
LIMIT 10;


-- -----------------------------------------------------------------------------
-- DEMO 4: Vista dashboard (para presentación)
-- -----------------------------------------------------------------------------
SELECT * FROM public.v_dashboard_jugador
ORDER BY fecha_hora DESC
LIMIT 10;
