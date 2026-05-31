# Sesión: Sistema de Diálogo — Vital Pixel

**Fecha:** 2026-05-30
**Motor:** Godot 4 · GDScript · Pixel Art 2.5x (800×600)

---

## Qué se construyó

Sistema completo de diálogo con panel tipo JRPG, efecto typewriter, soporte multipágina, sonidos sincronizados y estado "visto/no visto" por NPC.

### Archivos creados

- `src/menu/dialog_box.tscn` — Panel de diálogo (CanvasLayer, autoload)
- `src/menu/dialog_box.gd` — Lógica: typewriter, páginas, sonido, animación
- `src/menu/interact_prompt.tscn` — Botón imagen "E" (28×28)
- `src/menu/interact_prompt.gd` — Animación pop-in, tecla E

### Archivos modificados

- `src/entities/npc/npc.gd` — `dialog_lines`, `dialog_lines_repeat`, estado visto
- `src/levels/global.gd` — `dialogs_seen: Dictionary` como estado persistente
- `src/levels/classroom_1.tscn` — Compañero + Profesor Méndez (nombres, diálogos multi-línea)
- `src/levels/school_hallway.tscn` — Luis + Pedro (idem)
- `src/levels/infirmary.tscn` — Enfermero (idem)
- `project.godot` — Autoloads: Global, SceneManager, DialogBox

### Funcionalidades

- Panel deslizante (offset_top 0 → -170, cubic, 0.3s)
- Typewriter 0.015s/char, saltable con E
- Diálogos multi-página `Array[String]`
- Nombre NPC en Porky's 12px (oculto si vacío)
- Texto en Coolvetica 16px
- Prompt `▼` cyan parpadeante al completar línea
- Sonido typewriter (rate-limited, se detiene al completar/saltar/cerrar)
- Sonido UI select al abrir/avanzar/cerrar
- Estado `dialogs_seen` por NPC (1ª vez → repeat)
- Prompt E en `y=-82` — sin solapamiento con sprites

### NPCs

| NPC | Ubicación | Diálogo 1ª vez | Diálogo repeat |
|---|---|---|---|
| Compañero | classroom_1 | 3 líneas | 2 líneas |
| Profesor Méndez | classroom_1 | 3 líneas | 2 líneas |
| Luis | school_hallway | 3 líneas | 2 líneas |
| Pedro | school_hallway | 3 líneas | 2 líneas |
| Enfermero | infirmary | 3 líneas | 2 líneas |

---

## Actualización posterior: Puertas con botón E

Se unificó la interacción de puertas al mismo sistema que NPCs: botón E.

### Cambios

- `src/entities/door/door.gd` — Reescrito: eliminados `require_confirmation`, `confirmation_message`, `_is_ignored`. Ahora instancia `interact_prompt.tscn` (icono E 28×28) en lugar de `door_prompt.tscn`. Transición con `SceneManager.change_scene()` al pulsar E.
- `src/menu/door_prompt.tscn` — Eliminado (reemplazado por `interact_prompt.tscn`)
- `src/menu/door_prompt.gd` — Eliminado

### Archivos limpiados (propiedades obsoletas)

- `src/levels/classroom_1.tscn` — `require_confirmation` removido
- `src/levels/classroom_2.tscn` — `require_confirmation` removido
- `src/levels/school_hallway.tscn` — `confirmation_message` removido (3 puertas)
- `src/levels/infirmary.tscn` — `require_confirmation` removido

### Flujo final

```
Jugador entra en área de Door → icono E aparece (pop-in)
Jugador pulsa E → SceneManager.change_scene() con fade
Jugador sale del área → icono E desaparece
```

### Ventajas

- Consistencia total: misma tecla (E), mismo icono, misma mecánica que NPCs
- Sin transiciones automáticas ni panel SÍ/NO
- Cero UI nueva: reutiliza `InteractPrompt` sin cambios

### Assets

- **Fuentes:** Porky's (12px, nombres NPC), Coolvetica (16px, diálogo)
- **Sonidos:** `magiaz-teclado-371741.mp3` (typewriter, -15dB), `emilianodleon-select-button-ui-395763.mp3` (select)
- **Sprites:** `E-Photoroom.png` (28×28 prompt interactuar), spritesheets NPC (171×433, 5×4 frames)

---

## Próximos pasos posibles

- Eventos al finalizar diálogo (abrir puerta, recibir objeto)
- Diálogos con ramas/elecciones
- Archivos JSON externos para muchos NPCs
- Retratos de personajes en el panel
- Log de diálogos vistos
