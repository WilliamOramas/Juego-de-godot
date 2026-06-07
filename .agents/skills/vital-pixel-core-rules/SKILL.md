---
name: vital-pixel-core-rules
description: Core architectural rules, tech stack (Godot 4, Supabase), and GDScript coding standards for Vital Pixel. Always use this to understand system constraints.
---

# Vital Pixel - Core AI Architecture & Context Rules

**Project:** Vital Pixel
**Engine:** Godot Engine 4.x (GL Compatibility)
**Language:** GDScript
**Backend:** Supabase (PostgreSQL, REST API)
**Genre:** 2D Educational First Aid Simulation for UNEFA students.

## 🏗️ Architecture & File Structure
The project strictly follows a **Feature-Oriented Architecture**. All game code is located inside `src/`:
- `src/entities/`: Game actors (player, NPCs, interactive objects).
- `src/levels/`: Main map scenes (e.g., `school_hallway`).
- `src/minigames/`: First aid interactive scenarios (e.g., CPR, fainting).
- `src/menu/`: UI components, login screens, and the main in-game `PhoneHUD`.
- `src/singleton/`: Global Managers (`EventBus`, `Supabase`, `QuestManager`, `ScoreManager`).
- `database_schema.sql`: PostgreSQL schema definitions, RLS policies, and triggers.
- `supabase.cfg`: Local environment variables for Supabase connection.

## 🧠 Core Systems & Patterns
1. **Event Bus (Decoupled Communication):**
   - NEVER couple UI directly to game logic.
   - ALWAYS use `src/singleton/event_bus.gd` for cross-system communication.
   - Key signals: `minigame_completed`, `dialog_started`, `quest_started`, `scene_changing`.
2. **Backend & Database (Supabase):**
   - `src/singleton/supabase.gd` handles Auth and REST API queries.
   - **Database Triggers:** The DB handles score deduction automatically (e.g., a trigger deducts 10 points in `sesiones` if `telemetria_eventos.es_correcto = false`). Do NOT duplicate this logic in GDScript.
   - **Telemetry:** Minigame actions must be logged using `Supabase.send_telemetry(session_id, action, is_correct, time)`.
3. **In-Game Phone HUD:**
   - The primary UI interface is `src/menu/phone_hud.gd`. It handles push notifications, quest tracking, and minigame launching via different states (`HOME`, `MESSAGE`, `SCENARIO`).

## 💻 GDScript Coding Standards
Enforce the following rules strictly on all GDScript modifications:
1. **Strict Static Typing:** ALL variables, parameters, and return types MUST be typed.
   - `var speed: float = 250.0`
   - `func apply_damage(amount: int) -> void:`
2. **Modern Godot 4.x Syntax:** 
   - Use `await` instead of `yield`.
   - Use `signal_name.connect(callable)` instead of `connect("string", obj, "func")`.
3. **Naming Conventions:**
   - **Files/Folders:** `snake_case.gd`
   - **Classes/Nodes:** `PascalCase` (`class_name PlayerController`)
   - **Variables/Functions:** `snake_case` (`current_health`, `take_damage()`)
   - **Constants/Enums:** `SCREAMING_SNAKE_CASE`
4. **Node References:** Do NOT use hardcoded absolute paths (e.g., `get_node("../../Player")`). Use `@export var target_node: Node` or Unique Scene Nodes (`%NodeName`) with `@onready`.

## 🤖 Required Skills Utilization
- Apply `godot-gdscript-patterns` for state machines, components, and singletons.
- Apply `supabase-postgres-best-practices` when modifying `database_schema.sql` or `supabase.gd`.
- Use `caveman-commit` for commit message generation.
