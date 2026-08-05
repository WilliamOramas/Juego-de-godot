-- =============================================================================
-- Vital Pixel — Demo TRANSACCIONES en SQLite (DB Browser)
-- Abrir vital_pixel_demo.db o ejecutar sqlite_recreates_schema.sql antes
-- =============================================================================

-- Demo compañero: COMMIT exitoso (equivalente SQL 13 del .sqbpro)
BEGIN TRANSACTION;

INSERT INTO telemetria_eventos (id_sesion, accion_realizada, es_correcto, tiempo_seg, estado_salud_momento)
VALUES (1, 'Verificar vía aérea', 1, 10.5, 'Inconsciente');

INSERT INTO telemetria_eventos (id_sesion, accion_realizada, es_correcto, tiempo_seg, estado_salud_momento)
VALUES (1, 'Iniciar RCP', 1, 15.0, 'Inconsciente');

UPDATE sesiones
SET resultado = 'Salvado'
WHERE id_sesion = 1;

COMMIT;

SELECT id_sesion, puntaje_final, resultado FROM sesiones WHERE id_sesion = 1;


-- Demo compañero: ROLLBACK (equivalente SQL 14)
-- Ejecutar en pestaña separada si la sesión 1 ya está cerrada:
--   INSERT INTO sesiones (id_usuario, id_escenario, puntaje_final) VALUES (1, 2, 100);

BEGIN TRANSACTION;

INSERT INTO telemetria_eventos (id_sesion, accion_realizada, es_correcto, tiempo_seg, estado_salud_momento)
VALUES (
    (SELECT id_sesion FROM sesiones WHERE resultado IS NULL ORDER BY id_sesion DESC LIMIT 1),
    'Aplicar torniquete incorrecto',
    0,
    20.0,
    'Crítico'
);

ROLLBACK;

-- El puntaje no debe cambiar respecto al estado previo a la transacción abortada
SELECT id_sesion, puntaje_final, resultado
FROM sesiones
ORDER BY id_sesion DESC
LIMIT 3;
