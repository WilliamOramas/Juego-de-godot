# Documentación — Vital Pixel

Índice de la documentación del proyecto, organizada por partes.

| Parte | Archivo | Contenido |
|-------|---------|-----------|
| 1 | [01-introduccion.md](01-introduccion.md) | Contexto, objetivos, equipo, tecnologías |
| 2 | [02-instalacion-y-configuracion.md](02-instalacion-y-configuracion.md) | Godot, `supabase.cfg`, `ai.cfg`, migración BD |
| 3 | [03-arquitectura-software.md](03-arquitectura-software.md) | Carpetas, autoloads, EventBus, patrones |
| 4 | [04-base-de-datos.md](04-base-de-datos.md) | Modelo ER, tablas, triggers, transacciones, RLS |
| 5 | [05-integracion-supabase.md](05-integracion-supabase.md) | Auth, cloud saves, telemetría, flujo con el juego |
| 6 | [06-sistemas-del-juego.md](06-sistemas-del-juego.md) | Guardado, misiones, minijuegos, diario, puntuación |
| 7 | [07-pruebas.md](07-pruebas.md) | Pruebas unitarias GDScript |
| 8 | [08-guia-presentacion.md](08-guia-presentacion.md) | Demo académica (SQLite + Supabase) |

### Documentación adicional existente

- [dialog-system.md](dialog-system.md) — API del sistema de diálogos
- [demo_academica/README.md](demo_academica/README.md) — Scripts y guion para el profesor

### Archivos SQL de referencia (raíz del repo)

| Archivo | Uso |
|---------|-----|
| `database_schema.sql` | Esquema completo (instalación desde cero) |
| `database_migration_apply.sql` | Migración incremental en Supabase |
| `database_verification.sql` | Consultas de verificación |
