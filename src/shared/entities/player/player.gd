extends CharacterBody2D
class_name Player
# collision_layer = 3 en player.tscn → Capas 1 (Mundo) + 2 (Player)

@export var speed: float = 60.0
@export var run_speed: float = 120.0
@export var control_enabled: bool = true

var input_vector: Vector2 = Vector2.ZERO

@onready var animation_tree: AnimationTree = $AnimationTree
@onready var step_sound: AudioStreamPlayer = $StepSound

var _is_approaching: bool = false
var _walk_target: Vector2

var step_timer: float = 0.0

func _ready() -> void:
	animation_tree.active = true
	add_to_group("player")
	
	# Posicionar al jugador según prioridad: 1) spawn de destino, 2) posición guardada (Continue), 3) posición por defecto
	if Global.target_spawn_name != "":
		var spawn_point := get_tree().current_scene.find_child(Global.target_spawn_name, true, false) as Marker2D
		if spawn_point:
			global_position = spawn_point.global_position
		Global.target_spawn_name = ""
	elif Global.pending_position_restore:
		global_position = Global.saved_player_position
		Global.pending_position_restore = false

	# Conexión automática con el gestor de escenas para deshabilitar controles durante fundidos
	SceneManager.transition_started.connect(_on_transition_started)
	SceneManager.transition_finished.connect(_on_transition_finished)
	EventBus.dialog_started.connect(_on_dialog_started)
	EventBus.dialog_finished.connect(_on_dialog_finished)

func _physics_process(_delta: float) -> void:
	if control_enabled:
		get_input()
		animate_player(_delta)
	elif _is_approaching:
		var dir = (_walk_target - global_position).normalized()
		velocity = dir * speed
		input_vector = dir
		animate_player(_delta)
	else:
		velocity = Vector2.ZERO
		animate_player(_delta)
		
	move_and_slide()

func get_input() -> void:
	input_vector = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var current_speed: float = run_speed if Input.is_key_pressed(KEY_SHIFT) and input_vector != Vector2.ZERO else speed
	velocity = input_vector * current_speed

func animate_player(delta: float = 0.0) -> void:
	var is_idle = velocity == Vector2.ZERO
	animation_tree.set("parameters/conditions/idle", is_idle)
	animation_tree.set("parameters/conditions/walk", not is_idle)
	
	if is_idle:
		step_timer = 0.3
	else:
		var is_running := Input.is_key_pressed(KEY_SHIFT)
		var step_interval := 0.18 if is_running else 0.3

		if delta > 0.0:
			step_timer += delta
			if step_timer >= step_interval:
				step_timer = 0.0
				if step_sound:
					step_sound.pitch_scale = randf_range(0.85, 1.15)
					step_sound.play()

		# Solo intentamos asignar si el parámetro existe en el árbol
		animation_tree.set("parameters/walk/blend_position", input_vector)
		animation_tree.set("parameters/idle/blend_position", input_vector)

func _on_transition_started() -> void:
	control_enabled = false

func _on_transition_finished() -> void:
	control_enabled = true

func _on_dialog_started() -> void:
	control_enabled = false

func _on_dialog_finished() -> void:
	control_enabled = true

func _exit_tree() -> void:
	EventBus.dialog_started.disconnect(_on_dialog_started)
	EventBus.dialog_finished.disconnect(_on_dialog_finished)

func walk_to(target: Vector2) -> void:
	control_enabled = false
	_is_approaching = true
	_walk_target = target
	var walk_frames := 0
	while _is_approaching and is_instance_valid(self) and is_inside_tree() \
			and global_position.distance_squared_to(target) > 16.0:
		walk_frames += 1
		if walk_frames > 300:
			break
		await get_tree().physics_frame
	_is_approaching = false
	velocity = Vector2.ZERO
	animate_player(0.0)
	control_enabled = true

func set_camera_limits(left: int, top: int, right: int, bottom: int) -> void:
	var cam: Camera2D = $Camera2D
	cam.limit_left = left
	cam.limit_top = top
	cam.limit_right = right
	cam.limit_bottom = bottom
