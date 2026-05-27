class_name StateMachine
extends Node

## Emite una señal cuando cambiamos de un estado a otro
signal state_changed(from_state: StringName, to_state: StringName)

## Estado inicial de la máquina
@export var initial_state: State

## Estado actual activo
var current_state: State
var states: Dictionary = {}

func _ready() -> void:
	for child in get_children():
		if child is State:
			states[child.name] = child
			child.state_machine = self
			
	if owner:
		await owner.ready
		
	if initial_state and not current_state:
		current_state = initial_state
		current_state.enter()

## Delega la actualización normal al estado activo
func update(delta: float) -> void:
	if not current_state:
		return
	current_state.update(delta)

## Delega la actualización física al estado activo
func physics_update(delta: float) -> void:
	if not current_state:
		return
	current_state.physics_update(delta)

## Delega la entrada de eventos al estado activo
func handle_input(event: InputEvent) -> void:
	if not current_state:
		return
	current_state.handle_input(event)

## Realiza la transición de un estado a otro pasándole argumentos opcionales en 'msg'
func transition_to(state_name: StringName, msg: Dictionary = {}) -> void:
	if not states.has(state_name):
		push_error("El estado '%s' no está registrado en la máquina de estados." % state_name)
		return

	if current_state:
		current_state.exit()

	var previous_state := current_state
	current_state = states[state_name]
	current_state.enter(msg)

	state_changed.emit(previous_state.name if previous_state else &"", current_state.name)
