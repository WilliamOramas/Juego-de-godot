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
	EventBus.dialog_started.connect(func(): control_enabled = false)
	EventBus.dialog_finished.connect(func(): control_enabled = true)

func _physics_process(_delta: float) -> void:
	if control_enabled:
		get_input()
		animate_player(_delta)
	elif _is_approaching:
		velocity = Vector2.ZERO
	else:
		velocity = Vector2.ZERO
		animation_tree.set("parameters/conditions/idle", true)
		animation_tree.set("parameters/conditions/walk", false)
		
	move_and_slide()

func get_input() -> void:
	input_vector = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var current_speed: float = run_speed if Input.is_key_pressed(KEY_SHIFT) and input_vector != Vector2.ZERO else speed
	velocity = input_vector * current_speed

func animate_player(delta: float = 0.0) -> void:
	if velocity == Vector2.ZERO:
		animation_tree.set("parameters/conditions/idle", true)
		animation_tree.set("parameters/conditions/walk", false)
		step_timer = 0.3
	else:
		animation_tree.set("parameters/conditions/idle", false)
		animation_tree.set("parameters/conditions/walk", true)

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

func approach_position(target: Vector2) -> void:
	control_enabled = false
	_is_approaching = true
	var dir := (target - global_position).normalized()
	animation_tree.set("parameters/walk/blend_position", dir)
	animation_tree.set("parameters/conditions/idle", false)
	animation_tree.set("parameters/conditions/walk", true)
	var tween := create_tween().set_trans(Tween.TRANS_QUINT)
	tween.tween_property(self, "global_position", target, AnimHelper.PLAYER_APPROACH)
	await tween.finished
	animation_tree.set("parameters/conditions/idle", true)
	animation_tree.set("parameters/conditions/walk", false)
	_is_approaching = false
	control_enabled = true

func set_camera_limits(left: int, top: int, right: int, bottom: int) -> void:
	var cam: Camera2D = $Camera2D
	cam.limit_left = left
	cam.limit_top = top
	cam.limit_right = right
	cam.limit_bottom = bottom
