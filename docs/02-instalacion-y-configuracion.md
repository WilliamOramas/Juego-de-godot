# Parte 2 — Instalación y configuración

## Requisitos

- **Godot Engine 4.2+** (proyecto probado en 4.6).
- Cuenta en [Supabase](https://supabase.com) (para login, guardado en nube y telemetría).
- Opcional: [DB Browser for SQLite](https://sqlitebrowser.org/) para demos académicas offline.

## Clonar y abrir el proyecto

```bash
git clone https://github.com/WilliamOramas/Juego-de-godot.git
cd Juego-de-godot
```

1. Abre **Godot Project Manager** → **Import** → selecciona `project.godot`.
2. Pulsa **F5** para ejecutar (escena inicial: `src/menu/splash_screen.tscn`).

## Archivos de configuración local (no van al repositorio)

### `supabase.cfg`

Crea en la raíz del proyecto:

```ini
[supabase]
url="https://TU_PROYECTO.supabase.co"
key="TU_ANON_KEY"
```

Sin este archivo el juego funciona en **modo local**, pero no habrá login ni guardado en nube.

### `ai.cfg`

Opcional, para diálogos con IA en NPCs:

```ini
[ai]
api_key="TU_API_KEY"
```

## Base de datos en Supabase

### Primera vez

1. Crea un proyecto en Supabase.
2. En **SQL Editor**, ejecuta el contenido de [`database_migration_apply.sql`](../database_migration_apply.sql).
3. Verifica con [`database_verification.sql`](../database_verification.sql).

### Desde la línea de comandos (opcional)

```powershell
cd tools
npm install
$env:DATABASE_URL = "postgresql://postgres.TU_REF:TU_PASSWORD@aws-1-REGION.pooler.supabase.com:5432/postgres"
node apply_migration.mjs
node verify_migration.mjs
```

Usa la connection string del **Session pooler** del dashboard de Supabase (puerto 5432).

## Pruebas unitarias

```bash
godot --headless -s res://tests/run_tests.gd
```

O en Windows: `run_tests.bat`

Ver [Parte 7 — Pruebas](07-pruebas.md).

## Documentos relacionados

- [Parte 5 — Integración Supabase](05-integracion-supabase.md)
- [Parte 8 — Guía de presentación](08-guia-presentacion.md)
