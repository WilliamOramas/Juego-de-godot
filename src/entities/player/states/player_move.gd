class_name PlayerMove
extends PlayerState

func enter(_msg: Dictionary = {}) -> void:
	player.animation_tree.set("parameters/conditions/idle", false)
	player.animation_tree.set("parameters/conditions/walk", true)

func physics_update(_delta: float) -> void:
	var input_vector := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if input_vector == Vector2.ZERO:
		state_machine.transition_to(&"Idle")
		return
		
	player.velocity = input_vector * player.speed
	
	# Actualizamos la dirección de mezcla de la animación en base a la entrada
	player.animation_tree.set("parameters/walk/blend_position", input_vector)
	player.animation_tree.set("parameters/idle/blend_position", input_vector)
