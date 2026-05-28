# PROVISIONAL: Todo el sistema de NPCs, diálogos, movimiento y rutinas en este PR es temporal/provisional.
extends CharacterBody2D
class_name NPC

## Textura del spritesheet para el NPC
@export var sprite_texture: Texture2D = preload("res://src/assets/sprites/player_spritesheet.png")

## Frame del sprite para la dirección del NPC cuando está quieto (ej. 5 = abajo, 15 = derecha)
@export var sprite_frame: int = 5

## Color de modulación para cambiar el aspecto del uniforme o cabello
@export var sprite_modulate: Color = Color.WHITE

## Texto de diálogo que dirá el NPC al acercarse
@export var dialog_text: String = "¡Hola!"

## Tipo de comportamiento o rutina lógica para el NPC
@export_enum("Libre (Radio)", "Patrulla Horizontal", "Estático") var routine_type: String = "Libre (Radio)"

## Radio de movimiento máximo permitido desde su posición inicial (solo para rutina Libre)
@export var wander_radius: float = 50.0

## Velocidad de movimiento
@export var speed: float = 20.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var dialog_bubble: PanelContainer = $DialogBubble
@onready var dialog_label: Label = %DialogLabel
@onready var detection_area: Area2D = $DetectionArea

# Variables de control lógico
var _start_position: Vector2 = Vector2.ZERO
var _target_position: Vector2 = Vector2.ZERO
var _state_timer: float = 0.0
var _is_waiting: bool = true
var _anim_timer: float = 0.0
var _anim_frame: int = 0
var _patrol_dir: float = 1.0 # 1 = derecha, -1 = izquierda (para Patrulla Horizontal)

func _ready() -> void:
	# Aplicar textura, frame y modulación
	if sprite_texture:
		sprite.texture = sprite_texture
	sprite.frame = sprite_frame
	sprite.modulate = sprite_modulate
	dialog_label.text = dialog_text
	dialog_bubble.visible = false
	
	_start_position = global_position
	_target_position = global_position
	
	detection_area.body_entered.connect(_on_body_entered)
	detection_area.body_exited.connect(_on_body_exited)
	
	# Inicializar tiempos de espera
	_state_timer = randf_range(1.0, 3.0)

func _physics_process(delta: float) -> void:
	if routine_type == "Estático":
		velocity = Vector2.ZERO
		sprite.frame = sprite_frame
		sprite.flip_h = false
		return
		
	# Procesar temporizadores y cambio de objetivos
	if _is_waiting:
		velocity = Vector2.ZERO
		sprite.frame = sprite_frame
		sprite.flip_h = false
		
		_state_timer -= delta
		if _state_timer <= 0.0:
			_is_waiting = false
			_select_new_target()
	else:
		# Mover hacia el objetivo
		var to_target = _target_position - global_position
		if to_target.length() < 5.0:
			# Llegó al objetivo, comenzar a esperar
			_is_waiting = true
			_state_timer = randf_range(2.0, 4.0)
		else:
			# Seguir caminando hacia el objetivo
			var move_dir = to_target.normalized()
			velocity = move_dir * speed
			move_and_slide()
			
			# Animación provisional del movimiento
			_anim_timer += delta
			if _anim_timer >= 0.15:
				_anim_timer = 0.0
				_anim_frame = (_anim_frame + 1) % 5
				
				if abs(move_dir.x) > abs(move_dir.y):
					# Caminar izquierda/derecha (frames 10-14)
					sprite.frame = 10 + _anim_frame
					sprite.flip_h = move_dir.x < 0
				else:
					# Caminar arriba/abajo (frames 0-4)
					sprite.frame = _anim_frame
					sprite.flip_h = false

func _select_new_target() -> void:
	if routine_type == "Libre (Radio)":
		# Seleccionar un punto aleatorio dentro del radio respecto a su posición de inicio
		var angle = randf_range(0.0, TAU)
		var distance = randf_range(10.0, wander_radius)
		_target_position = _start_position + Vector2(cos(angle), sin(angle)) * distance
	elif routine_type == "Patrulla Horizontal":
		# Alternar entre caminar hacia la derecha e izquierda
		_patrol_dir = -_patrol_dir
		_target_position = _start_position + Vector2(40.0 * _patrol_dir, 0.0)

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		dialog_bubble.visible = true

func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		dialog_bubble.visible = false
