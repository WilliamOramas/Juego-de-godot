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
		if _changing_scene or get_tree().current_scene == null or get_tree().current_scene is MainMenu:
			return
		if MiniGameManager.is_minigame_active():
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
