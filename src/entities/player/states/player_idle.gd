class_name PlayerIdle
extends PlayerState

func enter(_msg: Dictionary = {}) -> void:
	player.velocity = Vector2.ZERO
	player.animation_tree.set("parameters/conditions/idle", true)
	player.animation_tree.set("parameters/conditions/walk", false)

func physics_update(_delta: float) -> void:
	var input_vector := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if input_vector == Vector2.ZERO:
		return
		
	state_machine.transition_to(&"Move")
