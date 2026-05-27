extends Node

signal transition_started
signal transition_finished

## Bandera de control para evitar múltiples activaciones y sincronizar estados de entidades
var is_transitioning: bool = false

@onready var fade_overlay: CanvasLayer
@onready var color_rect: ColorRect

func _ready() -> void:
	# Creamos la capa de transición dinámicamente en tiempo de ejecución
	fade_overlay = CanvasLayer.new()
	fade_overlay.layer = 100 # Se dibuja por encima de todo
	
	color_rect = ColorRect.new()
	color_rect.color = Color(0, 0, 0, 0) # Negro completamente transparente al inicio
	color_rect.anchors_preset = Control.PRESET_FULL_RECT
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	fade_overlay.add_child(color_rect)
	add_child(fade_overlay)

func change_scene(target_path: String, target_spawn: String = "", return_spawn: String = "", use_dynamic_return: bool = false) -> void:
	if is_transitioning:
		return
	is_transitioning = true
	
	transition_started.emit()
	color_rect.mouse_filter = Control.MOUSE_FILTER_ALL
	
	# Transición de salida: Fundido a negro (Alpha 1.0)
	var tween: Tween = create_tween()
	tween.tween_property(color_rect, "color:a", 1.0, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await tween.finished
	
	# Configuración declarativa de spawn en el Autoload Global
	Global.target_spawn_name = Global.return_spawn_name if use_dynamic_return else target_spawn
	Global.return_spawn_name = return_spawn if return_spawn != "" else Global.return_spawn_name
		
	# Cambiamos la escena actual
	var error: Error = get_tree().change_scene_to_file(target_path)
	if error != OK:
		_abort_transition(error, target_path)
		return
		
	# Esperamos a que la escena se inicialice y procese un frame
	await get_tree().process_frame
	
	# Transición de entrada: Volver a transparente (Alpha 0.0)
	tween = create_tween()
	tween.tween_property(color_rect, "color:a", 0.0, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await tween.finished
	
	# Permitir interacciones de nuevo y limpiar bandera
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	is_transitioning = false
	transition_finished.emit()

func _abort_transition(error: Error, path: String) -> void:
	push_error("Error al cambiar de escena a: %s (Código de error: %d)" % [path, error])
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	color_rect.color.a = 0.0
	is_transitioning = false
	transition_finished.emit()
