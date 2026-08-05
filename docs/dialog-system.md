# Documentación: Sistema de Diálogo — Vital Pixel

## Arquitectura

```
Jugador → DetectionArea (CS) → prompt E visible
   ↓ pulsa E
DialogBox.show_dialog(npcs) → slide_in()
   ↓ typewriter línea 0
   ↓ [ENTER] o E → línea 1
   ↓ [ENTER] o E → ... señal finished
   ↓ slide_out()
   ↓ npc.dialog_finished()
       ↓ marca visto en Global.dialogs_seen
```

### Autoloads (project.godot)

| Nombre | Script/Ruta | Propósito |
|---|---|---|
| Global | `src/core/managers/global.gd` | Estado global (`dialogs_seen`) |
| SceneManager | (integrado) | Transiciones entre escenas |
| DialogBox | `src/features/menu/dialog_box.gd` | Panel de diálogo |

### Escenas

| Escena | Ruta | Tipo |
|---|---|---|
| `dialog_box.tscn` | `src/features/menu/` | CanvasLayer |
| `interact_prompt.tscn` | `src/features/menu/` | PanelContainer |

---

## API

### DialogBox (autoload)

```
show_dialog(npc: Node) → void
```
Muestra el panel e inicia el diálogo. Usa `dialog_lines` (1ª vez) o `dialog_lines_repeat` (2+ vez).
Falls back a `dialog_text` (String legacy) si `dialog_lines` está vacío.

```
hide_dialog() → void
```
Cierra el panel con animación slide-out.

### Señales (en NPC)

```
dialog_finished()
```
Emitida por `npc.gd` cuando el diálogo termina. Útil para encadenar eventos.

### NPC (npc.gd)

| Export | Tipo | Default | Descripción |
|---|---|---|---|
| `npc_name` | String | `""` | Nombre mostrado en el panel |
| `dialog_lines` | Array[String] | `[]` | Diálogo primera vez (multi-línea) |
| `dialog_lines_repeat` | Array[String] | `[]` | Diálogo repeticiones |
| `dialog_text` | String | `""` | (legacy) Diálogo simple |

Si `dialog_lines_repeat` está vacío, se reusa `dialog_lines` en repeticiones.

### Global (autoload)

```
dialgs_seen: Dictionary  # clave: "npc_" + name, valor: true
```

---

## Cómo agregar un nuevo NPC con diálogo

1. Crear escena NPC con `CharacterBody2D`, spritesheet, `DetectionArea`
2. Asignar script `npc.gd`
3. En el inspector:
   - `npc_name`: "Nombre del NPC"
   - `dialog_lines`: `["Línea 1", "Línea 2", "Línea 3"]`
   - `dialog_lines_repeat`: `["Línea repeat 1", "Línea repeat 2"]`
4. (Opcional) Conectar señal `dialog_finished` para eventos

El prompt E aparece automáticamente cuando el jugador entra al `DetectionArea`.

## Puertas

Todas las puertas usan el mismo sistema de interacción que los NPCs: icono **E** + pop-in animation.

### Door (door.gd)

| Export | Tipo | Descripción |
|---|---|---|
| `target_scene_path` | String (archivo .tscn) | Escenario destino |
| `target_spawn_name` | String | SpawnPoint en destino |
| `return_spawn_name` | String | SpawnPoint de retorno |
| `use_dynamic_return` | bool | Usar spawn de retorno dinámico |

### Flujo

```
Jugador entra en body_entered de Door
  → icono E aparece (Vector2(-14, -35))
  → Jugador pulsa E
  → SceneManager.change_scene(target, spawn, return, dynamic)
```

La transición no se ejecuta si `DialogBox.is_open` (jugador en medio de un diálogo).

## Cómo agregar sonidos

Los sonidos se configuran directamente en el nodo `dialog_box.tscn`:
- `AudioTypewriter` → stream, volumen
- `AudioSelect` → stream, volumen

Regenerar archivos `.import` desde Godot si se reemplazan los mp3.

## Notas técnicas

- Typewriter: Timer 0.015s, `one_shot = false`. Se detiene al completar línea, al saltar con E o al cerrar.
- Posición prompt E: `Vector2(-14, -82)` respecto al NPC — sin solapamiento comprobado con 3 spritesheets distintos.
- Clave de estado: `"npc_" + name` (name = nombre del nodo en la escena, fijo).
- Compatibilidad hacia atrás: NPCs existentes con solo `dialog_text` funcionan sin cambios.
- Puertas también usan `InteractPrompt` (Vector2(-14, -35)). Sin `require_confirmation` ni `confirmation_message`.
- No hay conflictos E entre NPC y puerta: las zonas de detección no se superponen en ningún nivel.

---

## Registro de sesión

### 2026-05-30: Implementación completa

1. Creación de `dialog_box.tscn` + `dialog_box.gd` como autoload
2. Animación slide-in/out con cubic Tween
3. Typewriter effect con Timer, skip con E
4. Multipágina: Array[String], E avanza entre líneas
5. Label nombre NPC (Porky's 12px), label texto (Coolvetica 16px)
6. Prompt `▼` cyan al completar línea
7. Reemplazo de botón "E - Interactuar" por imagen `E-Photoroom.png` (28×28)
8. Prompt posicionado en `y=-82` — cero solapamiento
9. Sistema de estado visto/no visto en `global.gd`
10. Diálogos 1ª vez (3 líneas) + repeat (2 líneas) para 5 NPCs
11. Sonido typewriter rate-limited + silencio al saltar/cerrar
12. Sonido UI select en abrir/avanzar/cerrar
13. Compatibilidad legacy (`dialog_text` fallback)
14. Limpieza: `class_name` removido de DialogBox, `dialog_offset` unused removido

### 2026-05-30: Puertas con botón E

1. `door.gd` reescrito: usa `interact_prompt.tscn` en lugar de `door_prompt.tscn`
2. Eliminados exports `require_confirmation`, `confirmation_message`, var `_is_ignored`
3. Eliminados `door_prompt.tscn` + `door_prompt.gd`
4. Limpiadas propiedades obsoletas en 4 escenas de niveles
5. Documentación actualizada (session.md + docs/dialog-system.md)
