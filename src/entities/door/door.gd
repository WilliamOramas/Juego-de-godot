class_name Door
extends Area2D

## Ruta a la escena destino (ej. "res://src/levels/classroom_1.tscn")
@export_file("*.tscn") var target_scene_path: String

## Nombre del SpawnPoint en la escena destino donde el jugador debe aparecer
@export var target_spawn_name: String = ""

## Nombre del SpawnPoint en ESTA escena al que el jugador debe regresar en el futuro (ej. "HallwaySpawnLeft")
@export var return_spawn_name: String = ""

## Si es verdadero, usará el SpawnPoint de retorno dinámico guardado al entrar a este escenario
@export var use_dynamic_return: bool = false

## Si es verdadero, mostrará un cuadro de diálogo confirmando si se desea realizar la transición
@export var require_confirmation: bool = true

## Mensaje a mostrar en el cuadro de diálogo de confirmación
@export var confirmation_message: String = "¿Deseas entrar?"

var _is_ignored: bool = false
var _prompt_instance: Control = null

func _ready() -> void:
	# Conectamos las señales para detectar cuando el jugador entra y sale
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	# Verificamos si el cuerpo que entra es el jugador
	if body is Player:
		if target_scene_path != "":
			if require_confirmation:
				if not _is_ignored:
					_show_prompt()
			else:
				SceneManager.change_scene(target_scene_path, target_spawn_name, return_spawn_name, use_dynamic_return)
		else:
			push_warning("La puerta '%s' no tiene una escena destino configurada en el inspector." % name)

func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		_is_ignored = false
		_remove_prompt()

func _show_prompt() -> void:
	_remove_prompt()
	var prompt_scene = load("res://src/menu/door_prompt.tscn")
	_prompt_instance = prompt_scene.instantiate()
	add_child(_prompt_instance)
	# Posicionar el panel de 66px de ancho centrado sobre la puerta (mitad es -33px)
	_prompt_instance.position = Vector2(-33, -35)
	
	_prompt_instance.setup(
		func():
			_remove_prompt()
			SceneManager.change_scene(target_scene_path, target_spawn_name, return_spawn_name, use_dynamic_return),
		func():
			_is_ignored = true
			_remove_prompt()
	)

func _remove_prompt() -> void:
	if _prompt_instance and is_instance_valid(_prompt_instance):
		_prompt_instance.queue_free()
	_prompt_instance = null
