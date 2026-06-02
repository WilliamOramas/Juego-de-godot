extends Node2D

@export var camera_left: int = 0
@export var camera_top: int = 0
@export var camera_right: int = 853
@export var camera_bottom: int = 749

func _ready() -> void:
	var player = get_node_or_null("Player")
	if player and player.has_method("set_camera_limits"):
		player.set_camera_limits(camera_left, camera_top, camera_right, camera_bottom)
