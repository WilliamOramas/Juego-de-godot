class_name PlayerLocked
extends PlayerState

func enter(_msg: Dictionary = {}) -> void:
	player.velocity = Vector2.ZERO
	player.animation_tree.set("parameters/conditions/idle", true)
	player.animation_tree.set("parameters/conditions/walk", false)

# En el estado Locked no procesamos ninguna física ni entrada de movimiento
