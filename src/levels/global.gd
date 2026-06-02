extends Node

const INTERACT_PROMPT_PATH: String = "res://src/menu/interact_prompt.tscn"

## Almacena el nombre del SpawnPoint de destino para posicionar al jugador al cargar escenas
var target_spawn_name: String = ""

## Almacena el SpawnPoint de retorno dinámico cuando el jugador regrese al nivel anterior
var return_spawn_name: String = ""

## Indica si el audio del juego está silenciado
var is_muted: bool = false

## Registro de NPCs con los que ya habló el jugador (key = npc_nombre)
var dialogs_seen: Dictionary = {}

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
