class_name State
extends Node

## Referencia a la máquina de estados a la que pertenece
var state_machine: StateMachine

## Se llama al entrar a este estado. 'msg' puede usarse para pasar parámetros
func enter(_msg: Dictionary = {}) -> void:
	pass

## Se llama al salir de este estado
func exit() -> void:
	pass

## Se llama en la actualización del proceso normal (_process)
func update(_delta: float) -> void:
	pass

## Se llama en la actualización del proceso físico (_physics_process)
func physics_update(_delta: float) -> void:
	pass

## Se llama para procesar eventos de entrada no manejados (_unhandled_input)
func handle_input(_event: InputEvent) -> void:
	pass
