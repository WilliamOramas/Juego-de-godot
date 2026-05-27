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

func _ready() -> void:
	# Conectamos la señal para detectar cuando entra un cuerpo físico
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	# Verificamos si el cuerpo que entra es el jugador
	if body is Player:
		if target_scene_path != "":
			# Delegamos la carga y la transición de pantalla al gestor global
			SceneManager.change_scene(target_scene_path, target_spawn_name, return_spawn_name, use_dynamic_return)
		else:
			push_warning("La puerta '%s' no tiene una escena destino configurada en el inspector." % name)
