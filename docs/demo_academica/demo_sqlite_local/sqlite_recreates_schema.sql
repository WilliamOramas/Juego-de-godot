-- =============================================================================
-- Vital Pixel — SQLite local (laboratorio / DB Browser)
-- Recrea el modelo simplificado + triggers del compañero, alineado al juego
-- =============================================================================

PRAGMA foreign_keys = ON;

DROP TABLE IF EXISTS telemetria_eventos;
DROP TABLE IF EXISTS sesiones;
DROP TABLE IF EXISTS protocolo_maestro;
DROP TABLE IF EXISTS escenarios;
DROP TABLE IF EXISTS usuarios;

CREATE TABLE usuarios (
    id_usuario INTEGER PRIMARY KEY,
    nombre TEXT NOT NULL,
    carrera TEXT,
    fecha_registro TEXT DEFAULT (datetime('now'))
);

CREATE TABLE escenarios (
    id_escenario INTEGER PRIMARY KEY,
    nombre TEXT NOT NULL,
    nivel_dificultad INTEGER CHECK (nivel_dificultad BETWEEN 1 AND 5),
    tiempo_base_seg INTEGER
);

CREATE TABLE protocolo_maestro (
    id_paso INTEGER PRIMARY KEY AUTOINCREMENT,
    id_escenario INTEGER NOT NULL REFERENCES escenarios(id_escenario),
    orden_logico INTEGER NOT NULL,
    descripcion TEXT NOT NULL,
    penalizacion_tiempo REAL DEFAULT 0
);

CREATE TABLE sesiones (
    id_sesion INTEGER PRIMARY KEY AUTOINCREMENT,
    id_usuario INTEGER NOT NULL REFERENCES usuarios(id_usuario),
    id_escenario INTEGER NOT NULL REFERENCES escenarios(id_escenario),
    fecha_hora TEXT DEFAULT (datetime('now')),
    puntaje_final INTEGER,
    resultado TEXT CHECK (resultado IN ('Salvado', 'Fallecido'))
);

CREATE TABLE telemetria_eventos (
    id_evento INTEGER PRIMARY KEY AUTOINCREMENT,
    id_sesion INTEGER NOT NULL REFERENCES sesiones(id_sesion),
    accion_realizada TEXT NOT NULL,
    es_correcto INTEGER NOT NULL CHECK (es_correcto IN (0, 1)),
    tiempo_seg REAL NOT NULL,
    estado_salud_momento TEXT
);

-- Seeds alineados al juego (enteros para laboratorio)
INSERT INTO usuarios (id_usuario, nombre, carrera) VALUES
    (1, 'Estudiante Prueba', 'Enfermería UNEFA');

INSERT INTO escenarios (id_escenario, nombre, nivel_dificultad, tiempo_base_seg) VALUES
    (1, 'Desmayo - primeros auxilios', 2, 120),
    (2, 'RCP', 4, 90),
    (3, 'Trivia primeros auxilios', 1, 180);

INSERT INTO protocolo_maestro (id_escenario, orden_logico, descripcion, penalizacion_tiempo) VALUES
    (2, 1, 'Verificar escena segura', 5),
    (2, 2, '30 compresiones torácicas', 10),
    (2, 3, '2 respiraciones de rescate', 10),
    (2, 4, 'Ciclo completo 30:2', 12),
    (2, 5, 'Llamar al 112', 15);

INSERT INTO sesiones (id_sesion, id_usuario, id_escenario, puntaje_final) VALUES
    (1, 1, 2, 100);

-- Triggers (sintaxis SQLite — equivalente conceptual a PostgreSQL)
CREATE TRIGGER trg_validar_puntaje_negativo_update
BEFORE UPDATE OF puntaje_final ON sesiones
FOR EACH ROW
WHEN NEW.puntaje_final < 0
BEGIN
    SELECT RAISE(ABORT, 'Error de Juego: El puntaje final no puede ser negativo.');
END;

CREATE TRIGGER trg_validar_puntaje_negativo_insert
BEFORE INSERT ON sesiones
FOR EACH ROW
WHEN NEW.puntaje_final < 0
BEGIN
    SELECT RAISE(ABORT, 'No se puede insertar una sesión con puntaje negativo');
END;

CREATE TRIGGER trg_actualizar_puntaje_final
AFTER INSERT ON telemetria_eventos
FOR EACH ROW
WHEN NEW.es_correcto = 0
BEGIN
    UPDATE sesiones
    SET puntaje_final = COALESCE(puntaje_final, 100) - 10
    WHERE id_sesion = NEW.id_sesion;
END;

CREATE TRIGGER trg_validar_eventos_al_cerrar
BEFORE UPDATE ON sesiones
FOR EACH ROW
WHEN NEW.resultado IS NOT NULL AND (
    SELECT COUNT(*) FROM telemetria_eventos WHERE id_sesion = NEW.id_sesion
) = 0
BEGIN
    SELECT RAISE(ABORT, 'No se puede finalizar sesión sin eventos de telemetría');
END;
