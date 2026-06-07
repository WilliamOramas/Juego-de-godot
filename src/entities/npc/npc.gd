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

## Si el NPC es un chatbot de IA
@export var is_ai: bool = false

## Prompt del sistema para la IA (si is_ai es true)
@export_multiline var ai_system_prompt: String = ""

## Diálogo principal (primera vez que hablas con el NPC). Varias líneas = varias páginas.
@export var dialog_lines: Array[String] = []

## Diálogo alternativo al volver a hablar con el NPC (si está vacío, repite dialog_lines)
@export var dialog_lines_repeat: Array[String] = []

## Diálogo cuando la misión de este NPC está bloqueada por requisitos
@export var dialog_lines_blocked: Array[String] = []

## (Legacy) Texto de diálogo de una línea — se usa si dialog_lines está vacío
@export var dialog_text: String = "¡Hola!"

## Misión que inicia este NPC al hablarle por primera vez
@export var quest_to_start: Resource = null

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
@onready var _anim_player: AnimationPlayer = $AnimationPlayer

# Variables de control lógico
var _start_position: Vector2 = Vector2.ZERO
var _target_position: Vector2 = Vector2.ZERO
var _state_timer: float = 0.0
var _walk_timer: float = 0.0
var _is_waiting: bool = true
var _facing_down: bool = true
var _patrol_dir: float = 1.0 # 1 = derecha/abajo, -1 = izquierda/arriba
var _player_in_range: Player = null # Referencia al jugador en rango de interacción
var _interact: InteractableComponent

func _ready() -> void:
	# 1. Aplicar textura, frame y modulación
	if sprite_texture:
		sprite.texture = sprite_texture
	sprite.frame = sprite_frame
	sprite.modulate = sprite_modulate
	
	_facing_down = sprite_frame == 5
	_play_idle()
	
	# 3. Redimensionar dinámicamente el rango de detección del jugador
	var detect_shape: CollisionShape2D = detection_area.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if detect_shape and detect_shape.shape is CircleShape2D:
		detect_shape.shape = detect_shape.shape.duplicate() # Evitar compartir el recurso del shape entre instancias
		detect_shape.shape.radius = detection_radius
	
	_start_position = global_position
	_target_position = global_position
	
	detection_area.body_entered.connect(_on_body_entered)
	detection_area.body_exited.connect(_on_body_exited)
	
	# Inicializar tiempos de espera
	_state_timer = randf_range(wait_time_min, wait_time_max)

	_interact = InteractableComponent.new()
	add_child(_interact)
	_interact.setup(self, Vector2(-14, -82), _on_interact_pressed)

func _physics_process(delta: float) -> void:
	if _player_in_range != null:
		velocity = Vector2.ZERO
		var to_player: Vector2 = _player_in_range.global_position - global_position
		if abs(to_player.x) > abs(to_player.y):
			_facing_down = to_player.x <= 0
		else:
			_facing_down = to_player.y > 0
		_play_idle()
		return

	if routine_type == "Estático":
		velocity = Vector2.ZERO
		_play_idle()
		return

	if _is_waiting:
		velocity = Vector2.ZERO
		_play_idle()
		_state_timer -= delta
		if _state_timer <= 0.0:
			_is_waiting = false
			_walk_timer = 0.0
			_select_new_target()
	else:
		_walk_timer += delta
		if _walk_timer >= max_walk_time:
			_is_waiting = true
			_state_timer = randf_range(wait_time_min, wait_time_max)
			if velocity.x < 0 or velocity.y > 0:
				_facing_down = true
			else:
				_facing_down = false
			_play_idle()
			return

		var to_target: Vector2 = _target_position - global_position
		if to_target.length() < 5.0:
			_is_waiting = true
			_state_timer = randf_range(wait_time_min, wait_time_max)
			if velocity.x < 0 or velocity.y > 0:
				_facing_down = true
			else:
				_facing_down = false
			_play_idle()
		else:
			var move_dir: Vector2 = to_target.normalized()
			velocity = move_dir * speed
			move_and_slide()
			_facing_down = move_dir.x < 0 or move_dir.y > 0
			_play_walk()

func _play_idle() -> void:
	_anim_player.play("idle_down" if _facing_down else "idle_up")

func _play_walk() -> void:
	var anim: String = "walk_down" if _facing_down else "walk_up"
	var speed_scale: float = speed / 20.0
	_anim_player.play(anim, -1, speed_scale)

func _select_new_target() -> void:
	if routine_type == "Libre (Radio)":
		# Seleccionar un punto aleatorio dentro del radio respecto a su posición de inicio
		var angle: float = randf_range(0.0, TAU)
		var distance: float = randf_range(10.0, wander_radius)
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
		_interact.show_prompt()

func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		if _player_in_range == body:
			_player_in_range = null
		_interact.remove_prompt()
		if DialogBox and DialogBox.is_open:
			DialogBox.hide_dialog()
		if AiDialogBox and AiDialogBox.is_open:
			AiDialogBox.hide_dialog()

func _get_fallback_dialog(is_first: bool) -> Array[String]:
	if is_first and not dialog_lines.is_empty(): return dialog_lines.duplicate()
	if not is_first and not dialog_lines_repeat.is_empty(): return dialog_lines_repeat.duplicate()
	if not dialog_lines.is_empty(): return dialog_lines.duplicate()
	return [dialog_text]

func _on_interact_pressed() -> void:
	if DialogBox.is_open or AiDialogBox.is_open:
		return

	var key: String = "npc_" + name
	var is_first: bool = not Global.dialogs_seen.has(key)
	var lines: Array[String]
	var is_blocked := false

	if quest_to_start != null and quest_to_start is QuestData:
		var qd := quest_to_start as QuestData
		var qid := qd.quest_id
		var needs := qd.requires_quest
		if not QuestManager.is_quest_completed(qid) and not QuestManager.is_quest_active(qid):
			if needs != "" and not QuestManager.is_quest_completed(needs):
				is_blocked = true

	if is_blocked:
		lines = dialog_lines_blocked.duplicate() if not dialog_lines_blocked.is_empty() else [dialog_text]
		# No marcar como visto: la próxima vez seguirá intentando iniciar la quest
	else:
		lines = _get_fallback_dialog(is_first)
		Global.mark_dialog_seen(key)

	_interact.set_button_visible(false)
	if is_ai:
		AiDialogBox.show_dialog(npc_name, lines, ai_system_prompt)
	else:
		DialogBox.show_dialog(npc_name, lines)

	if not is_blocked and is_first and quest_to_start != null and quest_to_start is QuestData:
		var qd := quest_to_start as QuestData
		var started := QuestManager.start_quest(qd)
		if started and qd.objectives.size() > 0:
			var first_obj: QuestObjective = qd.objectives[0] as QuestObjective
			if first_obj.type == QuestObjective.ObjectiveType.TALK_TO_NPC and first_obj.target_id == npc_name:
				QuestManager.advance_objective(qd.quest_id, first_obj.objective_id)

	QuestManager.advance_talk_objectives(npc_name)
