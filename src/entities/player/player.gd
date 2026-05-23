extends CharacterBody2D

@export var speed: float = 60.0
var input_vector: Vector2 = Vector2.ZERO

@onready var animationTree: AnimationTree = $AnimationTree

func _ready() -> void:
	animationTree.active = true

func _physics_process(_delta: float) -> void:
	get_input()
	animate_player()
	move_and_slide()

func get_input() -> void:
	# Usamos el vector de entrada directamente
	input_vector = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = input_vector * speed # get_vector ya viene normalizado

func animate_player() -> void:
	if velocity == Vector2.ZERO:
		animationTree.set("parameters/conditions/idle", true)
		animationTree.set("parameters/conditions/walk", false)
	else:
		animationTree.set("parameters/conditions/idle", false)
		animationTree.set("parameters/conditions/walk", true)
		
		# Solo intentamos asignar si el parámetro existe para evitar el error E 0:00:00:831
		# Comentarios dejados por el Sr Williams
		# Todav{ia ando esperando que se instale discord en el phone.
		# 
		# IMPORTANTE: Revisa que en el Tree tus nodos se llamen 'idle' y 'walk' en minúsculas
		animationTree.set("parameters/walk/blend_position", input_vector)
		animationTree.set("parameters/idle/blend_position", input_vector)
