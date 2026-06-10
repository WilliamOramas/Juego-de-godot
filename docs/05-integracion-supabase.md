# Parte 5 — Integración Supabase

## Configuración en Godot

El singleton `Supabase` (`src/singleton/supabase.gd`) lee `supabase.cfg` en la raíz:

```ini
[supabase]
url="https://xxxx.supabase.co"
key="eyJ..."   # anon public key
```

Si el archivo no existe, `is_logged_in()` siempre es falso y el juego opera solo con guardado local.

## Autenticación

| Método | Endpoint | Uso en UI |
|--------|----------|-----------|
| `login(email, password)` | `auth/v1/token?grant_type=password` | `login_panel.gd` |
| `register(email, password)` | `auth/v1/signup` | Registro |
| `logout()` | Limpia token en memoria | Menú |

Tras login exitoso:

1. `login_panel` llama `upsert_usuario(nombre, carrera)` → tabla `usuarios`.
2. `MiniGameManager` carga `escenarios` desde la BD.
3. `SaveManager` puede sincronizar `cloud_saves`.

Señal: `auth_completed(success, message)`.

## Capa de dominio (`src/domain/`)

La lógica HTTP está separada en clases estáticas:

- **`SupabaseApi`** — URLs, headers y cuerpos JSON para REST y RPC.
- **`CloudSaveMapper`** — Lee campos del JSON de partida para `progreso_resumen`.
- **`GameProtocol`** — Mapea `game_id` → `id_escenario` y calcula resultado de sesión.

Esto permite probar payloads sin levantar Godot (ver [Parte 7](07-pruebas.md)).

## Flujo de una sesión de minijuego

```text
1. MiniGameManager.launch_minigame()
       ↓
2. Supabase.start_session(id_escenario)  → INSERT sesiones
       ↓
3. Jugador realiza pasos
       ↓
4. ScoreManager.record_minigame_step()
       → Supabase.send_telemetry(id_sesion, accion, es_correcto, tiempo)
       ↓
5. Al terminar: ScoreManager.record_minigame_result()
       → GameProtocol.resolve_session_result()
       → Supabase.finish_session()  → RPC finalizar_sesion_transaccional
```

### Alineación protocolo ↔ minijuegos

Las cadenas `protocolo_accion` en los minijuegos deben coincidir con `protocolo_maestro.descripcion`:

- `mini_fainting_first_aid.gd` — escenario 1 (desmayo).
- `mini_cpr.gd` — escenario 2 (RCP).
- Trivia — escenario 3.

Si no coinciden, la telemetría se guarda pero el trigger de penalización no encuentra el paso.

## Guardado en la nube

| Método | Tabla | Descripción |
|--------|-------|-------------|
| `push_cloud_saves(save_data)` | `cloud_saves` | UPSERT del JSON completo |
| `pull_cloud_saves(callback)` | `cloud_saves` | Descarga al iniciar slot nube |

`SaveManager.sync_to_cloud()` / `sync_from_cloud()` orquestan esto con el estado de `Global`, `QuestManager`, `JournalManager` y `ScoreManager`.

Al guardar en nube, el trigger `trg_sync_progreso_desde_cloud_save` actualiza `progreso_resumen` automáticamente.

## Consultas de lectura

| Método | Recurso |
|--------|---------|
| `fetch_escenarios(callback)` | `GET /escenarios` |
| `fetch_protocolo(id_escenario, callback)` | `GET /protocolo_maestro?id_escenario=eq.N` |

## Headers HTTP

Todas las peticiones autenticadas incluyen:

- `apikey` — anon key.
- `Authorization: Bearer <access_token>`.
- `Content-Type: application/json`.
- `Prefer: return=representation` en escrituras cuando se necesita el cuerpo de respuesta.

## Errores frecuentes

| Síntoma | Causa probable |
|---------|----------------|
| Login OK pero sin saves | Falta política RLS o `user_id` no coincide |
| Puntaje no baja | Acción no coincide con `protocolo_maestro` |
| RPC falla al cerrar sesión | Sesión sin eventos de telemetría |
| Migración no conecta | Usar pooler Supabase, no host directo IPv6 |

## Documentos relacionados

- [Parte 2 — Instalación](02-instalacion-y-configuracion.md)
- [Parte 4 — Base de datos](04-base-de-datos.md)
