-- =============================================================================
-- Vital Pixel — Demo de TRANSACCIONES en PostgreSQL / Supabase
-- Ejecutar en SQL Editor (requiere al menos 1 fila en usuarios)
-- =============================================================================

-- -----------------------------------------------------------------------------
-- DEMO A: Transacción exitosa (COMMIT implícito al terminar el bloque)
-- Crea sesión de prueba, registra telemetría y cierra con RPC transaccional
-- -----------------------------------------------------------------------------
DO $$
DECLARE
    v_usuario UUID;
    v_sesion BIGINT;
    v_resultado public.sesiones;
BEGIN
    SELECT id_usuario INTO v_usuario FROM public.usuarios LIMIT 1;
    IF v_usuario IS NULL THEN
        RAISE EXCEPTION 'No hay usuarios. Inicia sesión en el juego al menos una vez.';
    END IF;

    INSERT INTO public.sesiones (id_usuario, id_escenario, puntaje_final)
    VALUES (v_usuario, 2, 100)
    RETURNING id_sesion INTO v_sesion;

    INSERT INTO public.telemetria_eventos (id_sesion, accion_realizada, es_correcto, tiempo_seg, estado_salud_momento)
    VALUES
        (v_sesion, 'Verificar escena segura', true, 5.0, 'Estable'),
        (v_sesion, '30 compresiones torácicas', true, 35.0, 'Crítico'),
        (v_sesion, 'Llamar al 112', false, 8.0, 'Crítico');

    v_resultado := public.finalizar_sesion_transaccional(v_sesion, 'Salvado');

    RAISE NOTICE 'OK — id_sesion=%, puntaje_final=%, resultado=%',
        v_resultado.id_sesion, v_resultado.puntaje_final, v_resultado.resultado;
END $$;

SELECT s.id_sesion, e.nombre AS escenario, s.puntaje_final, s.resultado
FROM public.sesiones s
JOIN public.escenarios e USING (id_escenario)
ORDER BY s.id_sesion DESC
LIMIT 3;


-- -----------------------------------------------------------------------------
-- DEMO B: Transacción fallida (ROLLBACK por excepción del trigger/RPC)
-- Intenta cerrar sesión SIN telemetría → debe abortar
-- -----------------------------------------------------------------------------
DO $$
DECLARE
    v_usuario UUID;
    v_sesion BIGINT;
BEGIN
    SELECT id_usuario INTO v_usuario FROM public.usuarios LIMIT 1;
    IF v_usuario IS NULL THEN
        RAISE EXCEPTION 'No hay usuarios.';
    END IF;

    INSERT INTO public.sesiones (id_usuario, id_escenario, puntaje_final)
    VALUES (v_usuario, 1, 100)
    RETURNING id_sesion INTO v_sesion;

    BEGIN
        PERFORM public.finalizar_sesion_transaccional(v_sesion, 'Salvado');
        RAISE EXCEPTION 'ERROR: debió fallar por falta de telemetría';
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'ROLLBACK esperado — %', SQLERRM;
    END;

    IF (SELECT resultado FROM public.sesiones WHERE id_sesion = v_sesion) IS NOT NULL THEN
        RAISE EXCEPTION 'La sesión no debería haberse cerrado';
    END IF;

    RAISE NOTICE 'OK — sesión % sigue abierta (sin resultado)', v_sesion;
END $$;


-- -----------------------------------------------------------------------------
-- DEMO C: Transacción manual BEGIN / COMMIT (estilo laboratorio)
-- Equivalente al SQL 13 del compañero (SQLite)
-- -----------------------------------------------------------------------------
BEGIN;

INSERT INTO public.telemetria_eventos (id_sesion, accion_realizada, es_correcto, tiempo_seg, estado_salud_momento)
SELECT
    s.id_sesion,
    'Verificar respiración',
    true,
    10.5,
    'Inconsciente'
FROM public.sesiones s
WHERE s.resultado IS NULL
ORDER BY s.id_sesion DESC
LIMIT 1;

INSERT INTO public.telemetria_eventos (id_sesion, accion_realizada, es_correcto, tiempo_seg, estado_salud_momento)
SELECT
    s.id_sesion,
    'Palpar pulso carotídeo',
    true,
    15.0,
    'Inconsciente'
FROM public.sesiones s
WHERE s.resultado IS NULL
ORDER BY s.id_sesion DESC
LIMIT 1;

UPDATE public.sesiones
SET resultado = 'Salvado'
WHERE id_sesion = (
    SELECT id_sesion FROM public.sesiones WHERE resultado IS NULL ORDER BY id_sesion DESC LIMIT 1
);

COMMIT;
