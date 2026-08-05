-- =============================================================================
-- Vital Pixel — Migración incremental (ejecutar en Supabase SQL Editor)
-- No borra datos existentes. Seguro para aplicar sobre la BD en producción.
-- =============================================================================

-- 1. cloud_saves
CREATE TABLE IF NOT EXISTS public.cloud_saves (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    save_data JSONB NOT NULL DEFAULT '{}'::jsonb,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

ALTER TABLE public.cloud_saves ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Usuario gestiona su save" ON public.cloud_saves;
CREATE POLICY "Usuario gestiona su save" ON public.cloud_saves
    FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- 2. progreso_resumen
CREATE TABLE IF NOT EXISTS public.progreso_resumen (
    user_id UUID NOT NULL REFERENCES public.usuarios(id_usuario) ON DELETE CASCADE,
    slot SMALLINT NOT NULL CHECK (slot BETWEEN 0 AND 2),
    ultima_escena TEXT,
    puntaje INTEGER DEFAULT 0,
    escenarios_completados TEXT[] DEFAULT '{}',
    quests_completadas INTEGER DEFAULT 0,
    actualizado_en TIMESTAMPTZ DEFAULT timezone('utc'::text, now()),
    PRIMARY KEY (user_id, slot)
);

ALTER TABLE public.progreso_resumen ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Usuario gestiona su progreso" ON public.progreso_resumen;
CREATE POLICY "Usuario gestiona su progreso" ON public.progreso_resumen
    FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE INDEX IF NOT EXISTS idx_progreso_resumen_user ON public.progreso_resumen(user_id);

-- 3. Seeds escenarios (ids 1-3 alineados con mini_game_manager.gd)
INSERT INTO public.escenarios (id_escenario, nombre, nivel_dificultad, tiempo_base_seg)
VALUES
    (1, 'Desmayo - primeros auxilios', 2, 120),
    (2, 'RCP', 4, 90),
    (3, 'Trivia primeros auxilios', 1, 180)
ON CONFLICT (id_escenario) DO UPDATE SET
    nombre = EXCLUDED.nombre,
    nivel_dificultad = EXCLUDED.nivel_dificultad,
    tiempo_base_seg = EXCLUDED.tiempo_base_seg;

SELECT setval(
    pg_get_serial_sequence('public.escenarios', 'id_escenario'),
    GREATEST((SELECT COALESCE(MAX(id_escenario), 1) FROM public.escenarios), 3)
);

-- 4. Seeds protocolo_maestro
DELETE FROM public.protocolo_maestro WHERE id_escenario IN (1, 2, 3);

INSERT INTO public.protocolo_maestro (id_escenario, orden_logico, descripcion, penalizacion_tiempo) VALUES
    -- Escenario 1: Desmayo
    (1, 1, 'Verificar respuesta del paciente', 5),
    (1, 2, 'Verificar respiración', 5),
    (1, 3, 'Palpar pulso carotídeo', 8),
    (1, 4, 'Llamar al 112', 15),
    (1, 5, 'Elevar piernas', 5),
    (1, 6, 'Aflojar ropa ajustada', 5),
    (1, 7, 'Monitorear signos vitales', 8),
    -- Escenario 2: RCP
    (2, 1, 'Verificar escena segura', 5),
    (2, 2, '30 compresiones torácicas', 10),
    (2, 3, '2 respiraciones de rescate', 10),
    (2, 4, 'Ciclo completo 30:2', 12),
    (2, 5, 'Llamar al 112', 15),
    -- Escenario 3: Trivia
    (3, 1, 'Respuesta correcta a la trivia', 0),
    (3, 2, 'Respuesta incorrecta a la trivia', 8),
    (3, 3, 'Acierto Wordle', 0),
    (3, 4, 'Fallo Wordle', 10);

-- 5. Backfill usuarios desde auth
INSERT INTO public.usuarios (id_usuario, nombre, carrera)
SELECT
    id,
    COALESCE(raw_user_meta_data->>'nombre', split_part(email, '@', 1)),
    raw_user_meta_data->>'carrera'
FROM auth.users
ON CONFLICT (id_usuario) DO NOTHING;

-- 6. Trigger auth -> usuarios
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    INSERT INTO public.usuarios (id_usuario, nombre, carrera)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'nombre', split_part(NEW.email, '@', 1)),
        NEW.raw_user_meta_data->>'carrera'
    )
    ON CONFLICT (id_usuario) DO NOTHING;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();

-- 7. Inicializar puntaje al crear sesión
CREATE OR REPLACE FUNCTION public.inicializar_puntaje_sesion_fn()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.puntaje_final IS NULL THEN
        NEW.puntaje_final := 100;
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_inicializar_puntaje_sesion ON public.sesiones;
CREATE TRIGGER trg_inicializar_puntaje_sesion
    BEFORE INSERT ON public.sesiones
    FOR EACH ROW
    EXECUTE FUNCTION public.inicializar_puntaje_sesion_fn();

-- 8. Penalización según protocolo_maestro
CREATE OR REPLACE FUNCTION public.actualizar_puntaje_final_fn()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_penalizacion REAL := 10;
    v_id_escenario BIGINT;
BEGIN
    IF NEW.es_correcto = false THEN
        SELECT s.id_escenario INTO v_id_escenario
        FROM public.sesiones s
        WHERE s.id_sesion = NEW.id_sesion;

        SELECT p.penalizacion_tiempo INTO v_penalizacion
        FROM public.protocolo_maestro p
        WHERE p.id_escenario = v_id_escenario
          AND p.descripcion = NEW.accion_realizada
        LIMIT 1;

        IF v_penalizacion IS NULL THEN
            v_penalizacion := 10;
        END IF;

        UPDATE public.sesiones
        SET puntaje_final = GREATEST(COALESCE(puntaje_final, 100) - v_penalizacion::INTEGER, 0)
        WHERE id_sesion = NEW.id_sesion;
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_actualizar_puntaje_final ON public.telemetria_eventos;
CREATE TRIGGER trg_actualizar_puntaje_final
    AFTER INSERT ON public.telemetria_eventos
    FOR EACH ROW
    EXECUTE FUNCTION public.actualizar_puntaje_final_fn();

-- 9. Sync cloud_saves -> progreso_resumen
CREATE OR REPLACE FUNCTION public.sync_progreso_desde_cloud_save_fn()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    slot_key TEXT;
    slot_num SMALLINT;
    slot_data JSONB;
    completed JSONB;
    escenarios_arr TEXT[];
BEGIN
    FOR slot_key IN SELECT jsonb_object_keys(NEW.save_data)
    LOOP
        IF slot_key LIKE 'slot_%' THEN
            slot_num := substring(slot_key from 6)::SMALLINT;
            slot_data := NEW.save_data -> slot_key;
            completed := slot_data -> 'completed_scenarios';

            SELECT COALESCE(array_agg(e.key), '{}')
            INTO escenarios_arr
            FROM jsonb_each(COALESCE(completed, '{}'::jsonb)) AS e(key, val)
            WHERE val::text = 'true';

            INSERT INTO public.progreso_resumen (
                user_id, slot, ultima_escena, puntaje,
                escenarios_completados, quests_completadas, actualizado_en
            )
            VALUES (
                NEW.user_id,
                slot_num,
                slot_data ->> 'last_scene',
                COALESCE(FLOOR((slot_data -> 'score_stats' ->> 'score')::numeric), 0)::integer,
                COALESCE(escenarios_arr, '{}'),
                COALESCE(FLOOR((slot_data -> 'score_stats' ->> 'quests_completed')::numeric), 0)::integer,
                timezone('utc'::text, now())
            )
            ON CONFLICT (user_id, slot) DO UPDATE SET
                ultima_escena = EXCLUDED.ultima_escena,
                puntaje = EXCLUDED.puntaje,
                escenarios_completados = EXCLUDED.escenarios_completados,
                quests_completadas = EXCLUDED.quests_completadas,
                actualizado_en = EXCLUDED.actualizado_en;
        END IF;
    END LOOP;

    RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.touch_cloud_save_updated_at_fn()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at := timezone('utc'::text, now());
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_touch_cloud_save_updated_at ON public.cloud_saves;
CREATE TRIGGER trg_touch_cloud_save_updated_at
    BEFORE INSERT OR UPDATE OF save_data ON public.cloud_saves
    FOR EACH ROW
    EXECUTE FUNCTION public.touch_cloud_save_updated_at_fn();

DROP TRIGGER IF EXISTS trg_sync_progreso_desde_cloud_save ON public.cloud_saves;
CREATE TRIGGER trg_sync_progreso_desde_cloud_save
    AFTER INSERT OR UPDATE OF save_data ON public.cloud_saves
    FOR EACH ROW
    EXECUTE FUNCTION public.sync_progreso_desde_cloud_save_fn();

-- Backfill progreso_resumen desde cloud_saves existentes
INSERT INTO public.progreso_resumen (user_id, slot, ultima_escena, puntaje, escenarios_completados, quests_completadas, actualizado_en)
SELECT
    cs.user_id,
    substring(slot_key from 6)::SMALLINT AS slot,
    (cs.save_data -> slot_key ->> 'last_scene') AS ultima_escena,
    COALESCE(FLOOR((cs.save_data -> slot_key -> 'score_stats' ->> 'score')::numeric), 0)::integer AS puntaje,
    COALESCE((
        SELECT array_agg(e.key)
        FROM jsonb_each(COALESCE(cs.save_data -> slot_key -> 'completed_scenarios', '{}'::jsonb)) AS e(key, val)
        WHERE val::text = 'true'
    ), '{}') AS escenarios_completados,
    COALESCE(FLOOR((cs.save_data -> slot_key -> 'score_stats' ->> 'quests_completed')::numeric), 0)::integer AS quests_completadas,
    COALESCE(cs.updated_at, timezone('utc'::text, now())) AS actualizado_en
FROM public.cloud_saves cs
CROSS JOIN LATERAL jsonb_object_keys(cs.save_data) AS slot_key
WHERE slot_key LIKE 'slot_%'
ON CONFLICT (user_id, slot) DO UPDATE SET
    ultima_escena = EXCLUDED.ultima_escena,
    puntaje = EXCLUDED.puntaje,
    escenarios_completados = EXCLUDED.escenarios_completados,
    quests_completadas = EXCLUDED.quests_completadas,
    actualizado_en = EXCLUDED.actualizado_en;

-- 10. RPC transaccional para cerrar sesión
CREATE OR REPLACE FUNCTION public.finalizar_sesion_transaccional(
    p_id_sesion BIGINT,
    p_resultado TEXT
)
RETURNS public.sesiones
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
DECLARE
    v_sesion public.sesiones;
    v_event_count INTEGER;
BEGIN
    IF p_resultado NOT IN ('Salvado', 'Fallecido') THEN
        RAISE EXCEPTION 'Resultado inválido: %', p_resultado;
    END IF;

    SELECT COUNT(*) INTO v_event_count
    FROM public.telemetria_eventos
    WHERE id_sesion = p_id_sesion;

    IF v_event_count = 0 THEN
        RAISE EXCEPTION 'No se puede finalizar sesión sin eventos de telemetría';
    END IF;

    UPDATE public.sesiones
    SET
        resultado = p_resultado,
        puntaje_final = COALESCE(puntaje_final, 100),
        fecha_hora = timezone('utc'::text, now())
    WHERE id_sesion = p_id_sesion
    RETURNING * INTO v_sesion;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Sesión % no encontrada', p_id_sesion;
    END IF;

    RETURN v_sesion;
END;
$$;

GRANT EXECUTE ON FUNCTION public.finalizar_sesion_transaccional(BIGINT, TEXT) TO authenticated;

-- 11. Vista demo
CREATE OR REPLACE VIEW public.v_dashboard_jugador AS
SELECT
    u.nombre,
    e.nombre AS escenario,
    s.id_sesion,
    s.puntaje_final,
    s.resultado,
    s.fecha_hora,
    COUNT(t.id_evento) AS total_acciones,
    SUM(CASE WHEN t.es_correcto THEN 1 ELSE 0 END) AS aciertos
FROM public.usuarios u
JOIN public.sesiones s ON s.id_usuario = u.id_usuario
JOIN public.escenarios e ON e.id_escenario = s.id_escenario
LEFT JOIN public.telemetria_eventos t ON t.id_sesion = s.id_sesion
GROUP BY u.nombre, e.nombre, s.id_sesion, s.puntaje_final, s.resultado, s.fecha_hora;

GRANT SELECT ON public.v_dashboard_jugador TO authenticated;
