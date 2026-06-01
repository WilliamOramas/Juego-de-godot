extends CharacterBody2D
class_name NPC

## Textura del spritesheet para el NPC
@export var sprite_texture: Texture2D = preload("res://src/assets/sprites/player_spritesheet.png")

## Frame del sprite para la dirección del NPC cuando está quieto (ej. 5 = abajo, 15 = derecha)
@export var sprite_frame: int = 5

## Color de modulación para cambiar el aspecto del uniforme o cabello
@export var sprite_modulate: Color = Color.WHITE

## Nombre visible del NPC
@export var npc_name: String = ""

## Diálogo principal (primera vez que hablas con el NPC). Varias líneas = varias páginas.
@export var dialog_lines: Array[String] = []

## Diálogo alternativo al volver a hablar con el NPC (si está vacío, repite dialog_lines)
@export var dialog_lines_repeat: Array[String] = []

## (Legacy) Texto de diálogo de una línea — se usa si dialog_lines está vacío
@export var dialog_text: String = "¡Hola!"

## Tipo de comportamiento o rutina lógica para el NPC
@export_enum("Libre (Radio)", "Patrulla Horizontal", "Patrulla Vertical", "Estático") var routine_type: String = "Libre (Radio)"

## Radio de movimiento máximo permitido desde su posición inicial (solo para rutina Libre)
@export var wander_radius: float = 50.0

## Distancia máxima para la rutina de patrulla (Horizontal o Vertical)
@export var patrol_distance: float = 40.0

## Velocidad de movimiento
@export var speed: float = 20.0

## Tiempo máximo permitido para caminar hacia un punto antes de forzar espera (evita atascos en paredes)
@export var max_walk_time: float = 6.0

## Rango de detección físico de proximidad del jugador
@export var detection_radius: float = 45.0

## Tiempo de espera mínimo al llegar a un punto o al iniciar la rutina
@export var wait_time_min: float = 1.0

## Tiempo de espera máximo al llegar a un punto o al iniciar la rutina
@export var wait_time_max: float = 3.0


@onready var sprite: Sprite2D = $Sprite2D
@onready var detection_area: Area2D = $DetectionArea

# Variables de control lógico
var _start_position: Vector2 = Vector2.ZERO
var _target_position: Vector2 = Vector2.ZERO
var _state_timer: float = 0.0
var _walk_timer: float = 0.0
var _is_waiting: bool = true
var _anim_timer: float = 0.0
var _anim_frame: int = 0
var _patrol_dir: float = 1.0 # 1 = derecha/abajo, -1 = izquierda/arriba
var _player_in_range: Player = null # Referencia al jugador en rango de interacción
var _prompt_instance: Control = null

func _ready() -> void:
	# 1. Aplicar textura, frame y modulación
	if sprite_texture:
		sprite.texture = sprite_texture
	sprite.frame = sprite_frame
	sprite.modulate = sprite_modulate
	
	# 3. Ocultar la burbuja flotante legacy (se usa DialogBox ahora)
	if $DialogBubble:
		$DialogBubble.visible = false
		if %DialogLabel:
			%DialogLabel.text = dialog_lines[0] if not dialog_lines.is_empty() else dialog_text
	
	# 4. Redimensionar dinámicamente el rango de detección del jugador
	var detect_shape = detection_area.get_node_or_null("CollisionShape2D")
	if detect_shape and detect_shape.shape is CircleShape2D:
		detect_shape.shape = detect_shape.shape.duplicate() # Evitar compartir el recurso del shape entre instancias
		detect_shape.shape.radius = detection_radius
	
	_start_position = global_position
	_target_position = global_position
	
	detection_area.body_entered.connect(_on_body_entered)
	detection_area.body_exited.connect(_on_body_exited)
	
	# Inicializar tiempos de espera
	_state_timer = randf_range(wait_time_min, wait_time_max)

func _physics_process(delta: float) -> void:
	# 1. Si el jugador está interactuando (en rango), el NPC se detiene y lo mira
	if _player_in_range != null:
		velocity = Vector2.ZERO
		# move_and_slide() # Quitamos move_and_slide() para evitar atascos físicos ("efecto pegado")
		
		var to_player = _player_in_range.global_position - global_position
		if abs(to_player.x) > abs(to_player.y):
			if to_player.x > 0:
				sprite.frame = 15 # Mirar arriba/derecha
			else:
				sprite.frame = 5  # Mirar abajo/izquierda
		else:
			if to_player.y > 0:
				sprite.frame = 5  # Mirar abajo/izquierda
			else:
				sprite.frame = 15 # Mirar arriba/derecha
		sprite.flip_h = false
		return

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
			_walk_timer = 0.0
			_select_new_target()
	else:
		# Incrementar temporizador de caminata para evitar atascos permanentes
		_walk_timer += delta
		if _walk_timer >= max_walk_time:
			_is_waiting = true
			_state_timer = randf_range(wait_time_min, wait_time_max)
			# Guardar última dirección para la pose estática
			if velocity.x < 0 or velocity.y > 0:
				sprite_frame = 5
			else:
				sprite_frame = 15
			return

		# Mover hacia el objetivo
		var to_target = _target_position - global_position
		if to_target.length() < 5.0:
			# Llegó al objetivo, comenzar a esperar
			_is_waiting = true
			_state_timer = randf_range(wait_time_min, wait_time_max)
			# Guardar última dirección para la pose estática
			if velocity.x < 0 or velocity.y > 0:
				sprite_frame = 5
			else:
				sprite_frame = 15
		else:
			# Seguir caminando hacia el objetivo
			var move_dir = to_target.normalized()
			velocity = move_dir * speed
			move_and_slide()
			
			# Animación del movimiento coordinada con las 4 direcciones
			_anim_timer += delta
			# Escalar la velocidad de animación proporcionalmente a la velocidad física
			var anim_speed_factor := 0.15
			if speed > 0.0:
				anim_speed_factor = 0.15 * (20.0 / speed)
			if _anim_timer >= anim_speed_factor:
				_anim_timer = 0.0
				_anim_frame = (_anim_frame + 1) % 5
				
				if move_dir.x < 0 or move_dir.y > 0:
					# Izquierda o Abajo (frames 0-4, sin flip)
					sprite.frame = _anim_frame
				else:
					# Derecha o Arriba (frames 10-14, sin flip)
					sprite.frame = 10 + _anim_frame
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
		_target_position = _start_position + Vector2(patrol_distance * _patrol_dir, 0.0)
	elif routine_type == "Patrulla Vertical":
		# Alternar entre caminar hacia abajo y arriba
		_patrol_dir = -_patrol_dir
		_target_position = _start_position + Vector2(0.0, patrol_distance * _patrol_dir)

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		_player_in_range = body
		_show_prompt()

func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		if _player_in_range == body:
			_player_in_range = null
		_remove_prompt()
		DialogBox.hide_dialog()

func _show_prompt() -> void:
	_remove_prompt()
	var prompt_scene = load(Global.INTERACT_PROMPT_PATH)
	if prompt_scene:
		_prompt_instance = prompt_scene.instantiate()
		add_child(_prompt_instance)
		_prompt_instance.position = Vector2(-14, -82)

		_prompt_instance.setup(_on_interact_pressed)

func _remove_prompt() -> void:
	if _prompt_instance and is_instance_valid(_prompt_instance):
		_prompt_instance.queue_free()
	_prompt_instance = null

func _on_interact_pressed() -> void:
	if DialogBox.is_open:
		return

	var key = "npc_" + name
	var is_first = not Global.dialogs_seen.has(key)
	var lines: Array[String]

	if is_first:
		lines = dialog_lines.duplicate() if not dialog_lines.is_empty() else [dialog_text]
	else:
		lines = dialog_lines_repeat.duplicate() if not dialog_lines_repeat.is_empty() else (dialog_lines.duplicate() if not dialog_lines.is_empty() else [dialog_text])

	Global.dialogs_seen[key] = true

	if _prompt_instance and _prompt_instance.has_method("set_button_visible"):
		_prompt_instance.set_button_visible(false)

	if DialogBox.dialog_finished.is_connected(_on_dialog_finished):
		DialogBox.dialog_finished.disconnect(_on_dialog_finished)
	DialogBox.dialog_finished.connect(_on_dialog_finished)
	DialogBox.show_dialog(npc_name, lines)

func _on_dialog_finished() -> void:
	DialogBox.dialog_finished.disconnect(_on_dialog_finished)
	if _prompt_instance and is_instance_valid(_prompt_instance) and _prompt_instance.has_method("set_button_visible"):
		_prompt_instance.set_button_visible(true)
