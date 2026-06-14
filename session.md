# Bitácora de Desarrollo — Vital Pixel

Esta bitácora documenta las fases más importantes del desarrollo, la evolución arquitectónica y las integraciones avanzadas de Vital Pixel.

---

## 🚀 Hito Actual: Inteligencia Artificial, Telemetría y Clean Architecture (Junio 2026)

El proyecto experimentó una evolución masiva, pasando de un prototipo básico a una arquitectura escalable de Nivel Empresarial, e integrando sistemas backend e Inteligencia Artificial en tiempo real.

### 🏛️ 1. Refactorización a Feature-Oriented Architecture
Se reestructuró todo el código base bajo una estricta **Feature-Oriented Architecture** (Arquitectura Orientada a Funcionalidades). Todo el código está en `src/`:
- **`core/`**: Infraestructura (IA, Supabase, Network) y Managers globales (EventBus, Score, Quest, Journal).
- **`features/`**: Lógica de juego aislada (niveles, menú principal del celular, minijuegos, misiones).
- **`shared/`**: Recursos reutilizables (entidades como NPCs, UI genérica, componentes físicos).
- **Espejo de Pruebas**: El directorio `tests/` fue reflejado exactamente para seguir la misma estructura. Contamos con **129 pruebas unitarias** pasando exitosamente.

### 🧠 2. Integración de IA Generativa (Gemini 1.5)
Se implementó un sistema agnóstico de proveedores de IA para potenciar a los NPCs:
- **`AiClient` & `AiProvider`**: Patrón Strategy que delega las llamadas a la API de `GeminiProvider`.
- **NPCs Dinámicos**: El NPC (ej. Doctor Carlos en la enfermería) ya no solo tiene texto estático, sino que permite interacciones por texto libre con personalidad e historial inyectados vía *System Prompts*.
- **Trivia Generativa (`TriviaQuestionGenerator`)**: Integración de Gemini para crear infinitas preguntas de opción múltiple con JSON tipado basado en escenarios médicos.

### 🛡️ 3. UX de Red y Fallback Mode Silencioso
Para proteger la experiencia del jugador ante fallas de internet o de la API:
- **Fallback Silencioso**: Si falla una petición a la IA, la caja de texto (`AiDialogBox`) oculta automáticamente el campo de entrada y presenta botones de opción múltiple (Badges) con respuestas estáticas locales preconfiguradas.
- **Inmersión Total**: El sistema no imprime textos rojos de error en la UI, garantizando que el usuario sienta que la limitación es parte del flujo normal de un juego RPG.
- **Logs de Desarrollador**: Todos los errores de red se envían a la terminal de Godot con `push_error` para visibilidad técnica sin interrumpir el juego.

### 📊 4. Telemetría y Backend (Supabase)
Conexión directa con PostgreSQL a través de Supabase REST API:
- **Autenticación y Sesiones**: Creación de IDs de sesión únicas al iniciar.
- **Registro de Eventos**: Sistema de telemetría que envía datos analíticos cada vez que el usuario responde una trivia o realiza una acción en un minijuego (`is_correct`, `time`, `action`).
- **Deducción Dinámica**: El `ScoreManager` sincroniza la vida/puntaje del jugador basándose en el éxito o fracaso registrado en los minijuegos.

---

## ⏪ Hito Anterior: Sistema de Diálogo JRPG y Entidades (Mayo 2026)

Previo a la IA, se sentaron las bases de interacción clásicas:

- **Typewriter y UI**: Panel deslizante (offset_top 0 → -170), efecto typewriter a 0.015s/char, soporte multipágina, fuentes Coolvetica y Porky's, sonidos sincronizados.
- **NPCs Clásicos**: Interacciones predefinidas con arreglos `Array[String]` y estado "visto/no visto" gestionado globalmente.
- **Sistema de Interacción Unificado**: Tanto puertas como NPCs instancian el mismo `interact_prompt.tscn` (tecla E), permitiendo transiciones de escena fluidas y sin menús invasivos de confirmación.
