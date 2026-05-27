class_name Player
extends CharacterBody2D

@export var speed: float = 60.0

@onready var animation_tree: AnimationTree = $AnimationTree
@onready var state_machine: StateMachine = $StateMachine

func _ready() -> void:
	animation_tree.active = true
	_position_at_spawn()
	_connect_scene_manager()

func _unhandled_input(event: InputEvent) -> void:
	state_machine.handle_input(event)

func _process(delta: float) -> void:
	state_machine.update(delta)

func _physics_process(delta: float) -> void:
	state_machine.physics_update(delta)
	move_and_slide()

func _position_at_spawn() -> void:
	if Global.target_spawn_name == "":
		return
		
	var spawn_point := get_tree().current_scene.find_child(Global.target_spawn_name, true, false) as Node2D
	if spawn_point:
		global_position = spawn_point.global_position
	Global.target_spawn_name = ""

func _connect_scene_manager() -> void:
	if not has_node("/root/SceneManager"):
		return
		
	var scene_manager := get_node("/root/SceneManager")
	scene_manager.transition_started.connect(_on_transition_started)
	scene_manager.transition_finished.connect(_on_transition_finished)
	
	if scene_manager.is_transitioning:
		_on_transition_started()

func _on_transition_started() -> void:
	state_machine.transition_to(&"Locked")

func _on_transition_finished() -> void:
	state_machine.transition_to(&"Idle")
