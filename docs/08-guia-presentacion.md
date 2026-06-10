# Parte 8 — Guía de presentación académica

Material para el curso de **Bases de Datos Avanzadas**: demostrar triggers, transacciones, normalización parcial y equivalencia SQLite ↔ PostgreSQL.

## Contenido en el repositorio

Todo está en [`docs/demo_academica/`](demo_academica/README.md):

| Recurso | Descripción |
|---------|-------------|
| `demo_sqlite_local/vital_pixel_demo.db` | Base SQLite lista para DB Browser |
| `demo_sqlite_local/sqlite_recreates_schema.sql` | Script para recrear esquema |
| `demo_sqlite_local/demo_transacciones.sql` | Transacciones en SQLite |
| `demo_postgres_triggers.sql` | Demos de triggers en PostgreSQL |
| `demo_postgres_transacciones.sql` | Demos de transacciones en PostgreSQL |

## Guion sugerido (~5 minutos)

1. **Contexto** — Vital Pixel guarda partidas en JSON y resume progreso en tablas normalizadas.
2. **SQLite offline** — Abrir `.db`, mostrar tablas y ejecutar `demo_transacciones.sql`.
3. **Supabase en vivo** — Login en el juego → jugar minijuego → ver filas en `sesiones`, `telemetria_eventos`, `cloud_saves`, `progreso_resumen`.
4. **Triggers** — Mostrar penalización de puntaje al insertar telemetría incorrecta; sync automático a `progreso_resumen`.
5. **Transacción** — RPC `finalizar_sesion_transaccional`: no cierra sesión sin telemetría.
6. **Dashboard** — `SELECT * FROM v_dashboard_jugador;`

## Consultas rápidas para proyectar

```sql
-- Estado del jugador
SELECT * FROM progreso_resumen;

-- Última sesión con detalle
SELECT * FROM v_dashboard_jugador ORDER BY fecha_hora DESC LIMIT 5;

-- Protocolo del escenario desmayo
SELECT orden_logico, descripcion, penalizacion_tiempo
FROM protocolo_maestro WHERE id_escenario = 1 ORDER BY orden_logico;
```

Verificación completa: [`database_verification.sql`](../database_verification.sql) en la raíz del repo.

## Puntos clave para el profesor

- **RLS** — cada jugador solo ve sus datos (`auth.uid()`).
- **Integridad** — triggers antes de cerrar sesión y al actualizar puntaje.
- **Híbrido JSON + relacional** — `cloud_saves` para flexibilidad del juego; `progreso_resumen` para consultas SQL.
- **Camino futuro** — normalizar más campos del JSON en tablas dedicadas (Camino B del diseño).

## Documentos relacionados

- [demo_academica/README.md](demo_academica/README.md) — guion detallado del compañero
- [Parte 4 — Base de datos](04-base-de-datos.md)
