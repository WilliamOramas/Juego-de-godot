# Parte 7 — Pruebas unitarias

## Objetivo

Validar la lógica de dominio y managers **sin ejecutar el juego completo**, en modo headless de Godot.

## Ejecutar

Desde la raíz del proyecto:

```bash
godot --headless -s res://tests/run_tests.gd
```

Windows:

```bat
run_tests.bat
```

Código de salida: `0` si todos pasan, `1` si hay fallos.

## Estructura

```text
tests/
├── run_tests.gd              # Punto de entrada (SceneTree)
├── framework/
│   └── test_runner.gd        # assert_eq, assert_true, summary
└── unit/
    ├── test_cloud_save_mapper.gd
    ├── test_game_protocol.gd
    ├── test_supabase_api.gd
    └── test_score_manager.gd
```

## Suites actuales

| Suite | Qué verifica |
|-------|----------------|
| `test_cloud_save_mapper` | Extracción de slot, escena, puntaje y quests del JSON |
| `test_game_protocol` | Mapeo game_id → escenario, resultado Salvado/Fallecido |
| `test_supabase_api` | Endpoints REST, payloads de telemetría y RPC |
| `test_score_manager` | Cálculo de puntaje, penalizaciones, serialización |

## Añadir un test

1. Crear `tests/unit/test_mi_modulo.gd` con función estática `run(runner)`.
2. Registrar en `tests/run_tests.gd` con `preload` y llamada a `.run(runner)`.
3. Usar `runner.assert_eq(actual, expected, "mensaje")` y similares.

## Qué no cubren estas pruebas

- Integración real con Supabase (requiere red y credenciales).
- UI, input y escenas `.tscn`.
- Triggers de PostgreSQL (ver `tools/db/database_verification.sql` y demo académica).

## Documentos relacionados

- [Parte 2 — Instalación](02-instalacion-y-configuracion.md)
- [Parte 5 — Integración Supabase](05-integracion-supabase.md)
