# PROVISIONAL: Toda esta integración de transiciones, menús y SceneManager es provisional para este PR.
extends Node

## Señales de transición para que otros nodos (ej. Player) reaccionen
signal transition_started
signal transition_finished

## Señal emitida cuando el juego se pausa o reanuda
signal game_paused(paused: bool)

## Referencia al overlay de transición (se instancia automáticamente)
var _transition: CanvasLayer = null
var _anim: AnimationPlayer = null

## Flag para evitar cambios de escena dobles
var _changing_scene: bool = false
var _blur_overlay: ColorRect = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var transition_scene = load("res://src/singleton/scene_transition.tscn")
	if not transition_scene:
		push_error("SceneManager: No se pudo cargar scene_transition.tscn")
		return
	_transition = transition_scene.instantiate()
	add_child(_transition)
	_anim = _transition.get_node_or_null("AnimationPlayer")
	if not _anim:
		push_error("SceneManager: No se encontró AnimationPlayer en scene_transition")
		return
	_anim.play("fade_in")

	# Instanciar el shader de barrido temporal de forma dinámica
	var blur_shader = load("res://src/singleton/time_blur.gdshader")
	if blur_shader:
		var mat = ShaderMaterial.new()
		mat.shader = blur_shader
		mat.set_shader_parameter("wipe_progress", 0.0)
		
		_blur_overlay = ColorRect.new()
		_blur_overlay.name = "TimeBlurOverlay"
		_blur_overlay.material = mat
		_blur_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_blur_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_blur_overlay.visible = false
		_transition.add_child(_blur_overlay)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F11:
		var mode = DisplayServer.window_get_mode()
		if mode == DisplayServer.WINDOW_MODE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		get_viewport().set_input_as_handled()
		SaveManager.save_settings()
		return

	# Capturar la tecla Escape/Pause para abrir el menú de pausa
	if event.is_action_pressed("Pause"):
		# No permitir pausar durante la transición de escena, si estamos en el menú principal, o durante un minijuego
		if _changing_scene or get_tree().current_scene == null or get_tree().current_scene is MainMenu or get_tree().current_scene is LoginPanel:
			return
		if MiniGameManager.is_minigame_active():
			return
		if not DialogBox or not is_instance_valid(DialogBox):
			return
		if get_tree().paused:
			DialogBox.show_for_pause()
			pause_game(false)
		else:
			DialogBox.hide_for_pause()
			pause_game(true)

## Cambia de escena con una transición suave de fade negro
## [target_path]: Ruta "res://" a la escena destino
## [target_spawn]: Nombre del SpawnPoint destino (opcional)
## [return_spawn]: Nombre del SpawnPoint de retorno (opcional)
## [use_dynamic_return]: Si se debe usar el spawn de retorno dinámico guardado
func change_scene(target_path: String, target_spawn: String = "", return_spawn: String = "", use_dynamic_return: bool = false) -> void:
	if _changing_scene:
		return
	_changing_scene = true
	EventBus.scene_changing.emit(target_path)
	transition_started.emit()
	
	# Asegurarse de que el juego no esté pausado al cambiar de escena
	get_tree().paused = false

	if _anim:
		_anim.play("fade_out")
		await _anim.animation_finished
	
	# Configuración de spawn en el Autoload Global
	if use_dynamic_return:
		Global.target_spawn_name = Global.return_spawn_name
	else:
		Global.target_spawn_name = target_spawn
		
	if return_spawn != "":
		Global.return_spawn_name = return_spawn
	
	# Cambiamos la escena actual
	var error: Error = get_tree().change_scene_to_file(target_path)
	if error != OK:
		push_error("Error al cambiar de escena a: %s (Código de error: %d)" % [target_path, error])
		_changing_scene = false
		if _anim:
			_anim.play("fade_in")
			await _anim.animation_finished
		transition_finished.emit()
		return
	
	# Esperamos un frame para que la nueva escena esté lista
	await get_tree().process_frame
	
	if _anim:
		_anim.play("fade_in")
		await _anim.animation_finished
	
	_changing_scene = false
	transition_finished.emit()
	EventBus.scene_changed.emit(target_path)

## Pausa o reanuda el juego y notifica la señal
func pause_game(pause: bool) -> void:
	get_tree().paused = pause
	game_paused.emit(pause)

## Reproduce una transición de barrido a negro horizontal limpio para indicar el paso del tiempo
func play_time_passage(duration: float = 1.5, mid_callback: Callable = Callable()) -> void:
	if _changing_scene or not _blur_overlay:
		if mid_callback.is_valid():
			mid_callback.call()
		return
		
	_changing_scene = true
	_blur_overlay.visible = true
	transition_started.emit()
	
	var mat = _blur_overlay.material as ShaderMaterial
	mat.set_shader_parameter("wipe_progress", 0.0)
	
	# Tween para cubrir la pantalla con negro con un barrido horizontal de izquierda a derecha (0.0 -> 1.0)
	var tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(mat, "shader_parameter/wipe_progress", 1.0, duration * 0.4)
	
	await tween.finished
	
	# Ejecutar el callback (limpieza del minijuego) con la pantalla completamente negra
	if mid_callback.is_valid():
		mid_callback.call()
		
	# Pequeña pausa con la pantalla en negro para denotar el paso del tiempo
	await get_tree().create_timer(0.6).timeout
	
	# Tween para descorrer el barrido hacia la derecha revelando la escena (1.0 -> 2.0)
	var tween_back = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween_back.tween_property(mat, "shader_parameter/wipe_progress", 2.0, duration * 0.4)
	
	await tween_back.finished
	
	_blur_overlay.visible = false
	mat.set_shader_parameter("wipe_progress", 0.0) # Resetear para futura transición
	_changing_scene = false
	transition_finished.emit()

