# Parte 6 — Sistemas del juego

## Guardado (`SaveManager`)

- **3 slots** (0–2), cada uno en local (`user://save_N.json`) o nube.
- `flush()` — guarda con debounce cuando cambia el estado.
- `load_game(slot, is_cloud)` — restaura escena, posición, misiones, diario y puntaje.
- `reset_game()` — borra slot local o remoto.

Datos persistidos en el JSON de partida: escena actual, spawn, progreso de misiones, diálogos vistos, resultados de minijuegos, entradas del diario, estadísticas de puntuación.

## Misiones (`QuestManager`)

- Definiciones en `src/quests/*.tres` (`QuestData`).
- Objetivos por tipo: hablar con NPC, llegar a escena, completar minijuego.
- Escucha `EventBus`: `scene_changed`, `minigame_completed`, diálogos.
- Notificaciones en pantalla al avanzar o completar.

## Minijuegos (`MiniGameManager`)

| game_id | Escena | Escenario BD |
|---------|--------|--------------|
| `fainting` | `mini_fainting_first_aid.tscn` | 1 |
| `cpr` | `mini_cpr.tscn` | 2 |
| `trivia` | `mini_trivia.tscn` | 3 |

Al lanzar un minijuego: pausa BGM del nivel, overlay CRT opcional, crea sesión en Supabase si hay login.

## Puntuación (`ScoreManager`)

- Puntaje base **100** (alineado con BD).
- Penalizaciones por pasos incorrectos, muerte del estudiante, tiempo.
- `record_minigame_step()` envía telemetría en tiempo real.
- `get_grade()` — nota cualitativa según porcentaje.
- Se resetea al iniciar partida nueva; se serializa en el save.

## Diario (`JournalManager`)

Registro cronológico de:

- Entradas de minijuegos.
- Resúmenes de diálogos con NPCs.
- Hitos de misiones.
- Mensajes del sistema.

Límite de entradas de diálogo con recorte automático del más antiguo.

## Diálogos

Sistema JRPG con typewriter, multipágina y estado visto/no visto.

Documentación detallada: [dialog-system.md](dialog-system.md).

## Teléfono (`PhoneHud`)

HUD lateral para llamadas de emergencia (112) integrado en escenarios de primeros auxilios.

## IA en NPCs (`AiClient` + `AiDialogBox`)

Opcional. Requiere `config.cfg`. Emite `ai_response_received` / `ai_error_received` vía EventBus.

## Exploración y niveles

| Escena | Descripción |
|--------|-------------|
| `school_hallway.tscn` | Hub principal |
| `classroom_1.tscn`, `classroom_2.tscn` | Aulas con NPCs |
| `infirmary.tscn` | Enfermería |

`SceneManager` gestiona transiciones con fade/wipe y puntos de spawn.

## Triggers de minijuego

- `fainting_trigger.gd` — inicia escenario de desmayo.
- `cpr_trigger.gd` — inicia RCP.

## Flujo de nueva partida

```text
main_menu → slot_selector → (login si nube) → school_hallway
    → SaveManager carga o crea estado
    → QuestManager inicia misión intro si aplica
```

## Documentos relacionados

- [Parte 3 — Arquitectura](03-arquitectura-software.md)
- [Parte 5 — Supabase](05-integracion-supabase.md)
