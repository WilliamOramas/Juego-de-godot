# Parte 3 — Arquitectura de software

## Enfoque general

El proyecto usa **arquitectura orientada a funcionalidades**: cada sistema vive en `src/` agrupado por rol (entidades, niveles, menús, singletons).

La comunicación entre sistemas evita acoplamiento directo UI ↔ lógica mediante el **EventBus** y **singletons** (autoloads).

## Estructura de carpetas

```text
res://
├── src/
│   ├── assets/          # Sprites, sonidos, fuentes
│   ├── domain/          # Lógica pura (protocolo, API REST, mapper de saves)
│   ├── entities/        # Jugador, NPCs, puertas, triggers de minijuegos
│   ├── levels/          # Escenas de mapas (pasillo, aulas, enfermería)
│   ├── menu/            # UI: menús, login, phone HUD, diálogos
│   ├── minigames/       # Desmayo, RCP, trivia
│   ├── quests/          # Datos de misiones (.tres)
│   ├── singleton/       # Managers globales
│   └── utils/           # Helpers compartidos
├── tests/               # Pruebas unitarias headless
├── tools/               # Scripts Node para migración Supabase
├── docs/                # Documentación
├── tools/db/database_schema.sql
└── tools/db/database_migration_apply.sql
```

## Autoloads (`project.godot`)

| Singleton | Ruta | Responsabilidad |
|-----------|------|-----------------|
| `Global` | `src/core/managers/global.gd` | Estado de partida: diálogos vistos, escenarios completados, posición |
| `SaveManager` | `src/core/managers/save_manager.gd` | Slots locales/nube, settings, sync Supabase |
| `EventBus` | `src/core/managers/event_bus.gd` | Señales globales desacopladas |
| `SceneManager` | `src/core/managers/scene_manager.gd` | Cambio de escenas, transiciones, pausa |
| `DialogBox` | `src/features/menu/dialog_box.tscn` | Diálogos JRPG |
| `AiDialogBox` | `src/features/menu/ai_dialog_box.tscn` | Diálogos con IA |
| `AiClient` | `src/core/infrastructure/ai/ai_client.gd` | Peticiones HTTP a API de IA |
| `QuestManager` | `src/core/managers/quest_manager.gd` | Misiones y objetivos |
| `MiniGameManager` | `src/core/managers/mini_game_manager.gd` | Lanzamiento de minijuegos + sesión BD |
| `ScoreManager` | `src/core/managers/score_manager.gd` | Puntaje, telemetría, notas |
| `JournalManager` | `src/core/managers/journal_manager.gd` | Bitácora del jugador |
| `PhoneHud` | `src/features/menu/phone_hud.tscn` | Interfaz de teléfono en juego |
| `Supabase` | `src/core/infrastructure/supabase/supabase.gd` | Auth y REST API |

## EventBus — señales principales

```text
dialog_started / dialog_finished
scene_changing / scene_changed
minigame_started / minigame_completed
quest_started / objective_advanced / quest_completed
student_died
score_updated
journal_entry_added
```

**Regla:** los sistemas emiten eventos; los listeners reaccionan. No llamar UI desde la lógica de minijuegos directamente.

## Capa `src/core/models/`

Lógica sin dependencia de nodos Godot, reutilizable y testeable:

| Archivo | Función |
|---------|---------|
| `game_protocol.gd` | Pasos del `protocolo_maestro` y resultado de sesión |
| `supabase_api.gd` | Construcción de endpoints y payloads REST |
| `cloud_save_mapper.gd` | Extracción de resumen desde JSON de partida |

## Flujo de escena típico

```text
splash_screen → main_menu → (login opcional) → school_hallway → ...
                      ↓
              slot_selector (local / nube)
```

## Documentos relacionados

- [Parte 6 — Sistemas del juego](06-sistemas-del-juego.md)
- [dialog-system.md](dialog-system.md)
