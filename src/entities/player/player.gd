class_name Player
extends CharacterBody2D

@export var speed: float = 60.0
@export var control_enabled: bool = true

var input_vector: Vector2 = Vector2.ZERO

@onready var animation_tree: AnimationTree = $AnimationTree

func _ready() -> void:
	animation_tree.active = true
	
	# Si hay un spawn de destino configurado globalmente, nos posicionamos allí
	if Global.target_spawn_name != "":
		var spawn_point := get_tree().current_scene.find_child(Global.target_spawn_name, true, false) as Marker2D
		if spawn_point:
			global_position = spawn_point.global_position
		Global.target_spawn_name = ""
		
	# Conexión automática con el gestor de escenas para deshabilitar controles durante fundidos
	SceneManager.transition_started.connect(_on_transition_started)
	SceneManager.transition_finished.connect(_on_transition_finished)

func _physics_process(_delta: float) -> void:
	if control_enabled:
		get_input()
		animate_player()
	else:
		velocity = Vector2.ZERO
		# Forzar animación idle cuando no hay control
		animation_tree.set("parameters/conditions/idle", true)
		animation_tree.set("parameters/conditions/walk", false)
		
	move_and_slide()

func get_input() -> void:
	# Usamos el vector de entrada directamente (get_vector ya viene normalizado)
	input_vector = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = input_vector * speed

func animate_player() -> void:
	if velocity == Vector2.ZERO:
		animation_tree.set("parameters/conditions/idle", true)
		animation_tree.set("parameters/conditions/walk", false)
	else:
		animation_tree.set("parameters/conditions/idle", false)
		animation_tree.set("parameters/conditions/walk", true)
		
		# Solo intentamos asignar si el parámetro existe en el árbol
		animation_tree.set("parameters/walk/blend_position", input_vector)
		animation_tree.set("parameters/idle/blend_position", input_vector)

func _on_transition_started() -> void:
	control_enabled = false

func _on_transition_finished() -> void:
	control_enabled = true
