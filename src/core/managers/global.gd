extends Node

const INTERACT_PROMPT_PATH: String = "res://src/features/menu/features/dialog/interact_prompt.tscn"

## Almacena el nombre del SpawnPoint de destino para posicionar al jugador al cargar escenas
var target_spawn_name: String = ""

## Almacena el SpawnPoint de retorno dinámico cuando el jugador regrese al nivel anterior
var return_spawn_name: String = ""

## Indica si el audio del juego está silenciado
var is_muted: bool = false

## Registro de NPCs con los que ya habló el jugador (key = npc_nombre)
var dialogs_seen: Dictionary = {}

## Posición guardada del jugador para restaurar al continuar partida
var saved_player_position: Vector2 = Vector2.ZERO

## Indica si hay una posición guardada pendiente de restaurar
var pending_position_restore: bool = false

## Indica si el estudiante murió durante un minijuego
var student_died: bool = false

## Posición a la que el jugador debe acercarse antes del minijuego de primeros auxilios
var fainting_approach_pos: Vector2 = Vector2.ZERO

## Registro de minijuegos/escenarios ya completados (key = scenario_id)
var completed_scenarios: Dictionary = {}

## Progreso narrativo del reto del profesor Méndez (classroom_1)
var professor_challenge: Dictionary = {
	"show_enrique": false,
	"trivia_tied": false,
	"first_arc_complete": false,
	"last_trivia_result": "",
	"replay_sessions": 0,
}


func normalize_professor_challenge() -> void:
	var defaults: Dictionary = {
		"show_enrique": false,
		"trivia_tied": false,
		"first_arc_complete": false,
		"last_trivia_result": "",
		"replay_sessions": 0,
	}
	var had_first_arc_key: bool = professor_challenge.has("first_arc_complete")
	var had_last_trivia_key: bool = professor_challenge.has("last_trivia_result")
	for key: Variant in defaults.keys():
		if not professor_challenge.has(key):
			professor_challenge[key] = defaults[key]

	var results: Dictionary = ScoreManager.get_minigame_results()
	var tied: bool = bool(professor_challenge.get("trivia_tied", false))

	if not had_first_arc_key:
		professor_challenge["first_arc_complete"] = results.has("wordle") or (results.has("trivia") and not tied)

	if not had_last_trivia_key or String(professor_challenge.get("last_trivia_result", "")).is_empty():
		if last_minigame_outcome.get("game_id") == "trivia":
			professor_challenge["last_trivia_result"] = String(last_minigame_outcome.get("result", ""))
		elif results.has("trivia"):
			if tied:
				professor_challenge["last_trivia_result"] = "tie"
			elif bool(results["trivia"].get("passed", false)):
				professor_challenge["last_trivia_result"] = "win"
			else:
				professor_challenge["last_trivia_result"] = "loss"

## Último resultado detallado de un minijuego (game_id + result: win|loss|tie)
var last_minigame_outcome: Dictionary = {}

## Activa o desactiva el silenciado global del juego (Master bus)
func set_mute(muted: bool) -> void:
	is_muted = muted
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), muted)
	if SaveManager:
		SaveManager.save_settings()

## Marca un NPC como visto
func mark_dialog_seen(key: String) -> void:
	dialogs_seen[key] = true
	if SaveManager:
		SaveManager.mark_dirty()
