# Demo académica — Vital Pixel

Material para presentar **triggers**, **transacciones** y el **modelo relacional** al profesor.

## Dos capas (mensaje clave)

| Capa | Motor | Uso |
|------|-------|-----|
| **Laboratorio** | SQLite + DB Browser | Offline, triggers y `BEGIN/COMMIT/ROLLBACK` en clase |
| **Producción** | PostgreSQL / Supabase | Juego Godot en vivo, RLS, RPC, `cloud_saves`, `progreso_resumen` |

Mismo diseño conceptual (`usuarios` → `sesiones` → `telemetria_eventos`), distinta implementación.

## SQLite local (trabajo del compañero, adaptado)

1. Instalar [DB Browser for SQLite](https://sqlitebrowser.org/).
2. Abrir `demo_sqlite_local/vital_pixel_demo.sqbpro` (apunta a `vital_pixel_demo.db`).
3. O recrear desde cero: ejecutar `sqlite_recreates_schema.sql` y luego `demo_transacciones.sql`.

Archivos:

- `vital_pixel_demo.db` — base del compañero (renombrada, ~28 KB)
- `vital_pixel_demo.sqbpro` — proyecto con consultas de demo ya guardadas
- `sqlite_recreates_schema.sql` — schema + triggers en texto (portable)
- `demo_transacciones.sql` — COMMIT vs ROLLBACK

## PostgreSQL / Supabase (producción)

Ejecutar en **SQL Editor** de Supabase (con al menos un usuario que haya jugado logueado):

1. `demo_postgres_triggers.sql` — penalización por protocolo, puntaje negativo, vista dashboard
2. `demo_postgres_transacciones.sql` — RPC `finalizar_sesion_transaccional`, rollback por excepción, `BEGIN/COMMIT`

Esquema completo del juego: [`../tools/db/database_schema.sql`](../tools/db/database_schema.sql)  
Migración aplicada: [`../tools/db/database_migration_apply.sql`](../tools/db/database_migration_apply.sql)

## Guión rápido (5 min)

1. **ER** — Mostrar tablas en DB Browser y en Supabase Table Editor.
2. **Trigger** — Insertar telemetría incorrecta → ver `puntaje_final` bajar (SQLite o Supabase).
3. **Transacción** — SQLite: SQL 13 vs 14; Supabase: bloque DO con RPC y rollback.
4. **Integración** — Jugar minijuego logueado → `SELECT * FROM v_dashboard_jugador`.
5. **Normalización** — Guardar partida → `SELECT * FROM progreso_resumen` (JSON redistribuido).

## Equivalencia SQLite ↔ PostgreSQL

| SQLite (compañero) | PostgreSQL (proyecto) |
|--------------------|------------------------|
| `RAISE(ABORT, ...)` | `RAISE EXCEPTION` |
| `es_correcto = 0` | `es_correcto = false` |
| `id_usuario INTEGER` | `id_usuario UUID` + `auth.users` |
| Triggers en `.sqbpro` | `tools/db/database_migration_apply.sql` |
| `BEGIN … COMMIT` manual | `finalizar_sesion_transaccional()` + bloques `DO` |
