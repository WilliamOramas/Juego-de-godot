extends RefCounted

const AiDialogBoxScene = preload("res://src/features/menu/features/dialog/ai_dialog_box.tscn")

static func run(runner) -> void:
	runner.run_suite("AiDialogBox Fallback", func() -> void:
		_test_fallback_mode_activation(runner)
	)

static func _test_fallback_mode_activation(runner) -> void:
	var dialog = AiDialogBoxScene.instantiate()
	# No añadir al arbol para evitar "Parent busy"
	
	# Simular que se abre el diálogo con fallback_qa
	var fallback_qa = {
		"¿Dónde estoy?": "Estás en la enfermería.",
		"Me duele la cabeza": "Toma un descanso de la pantalla."
	}
	
	var lines: Array[String] = ["Hola soy Carlos"]
	
	# Mockear las variables que show_dialog setea para evitar llamar a create_tween fuera del arbol
	dialog._fallback_qa = fallback_qa
	dialog.is_open = true
	dialog.badge_container = HBoxContainer.new()
	dialog.input_line = LineEdit.new()
	dialog.send_button = Button.new()
	dialog.dialog_label = Label.new()
	dialog.audio_select = AudioStreamPlayer.new()
	dialog.type_timer = Timer.new()
	dialog._lines = lines
	
	runner.assert_true(dialog.is_open, "El diálogo debería abrirse")
	runner.assert_false(dialog._is_fallback_mode, "No debe estar en modo fallback inicialmente")
	
	# Simular el error de la API de AI llamando directamente a la función en lugar del EventBus
	# ya que EventBus puede no atrapar el evento si no estamos en el arbol de escenas
	dialog._on_ai_error_received("Timeout del proveedor")
	
	runner.assert_true(dialog._is_fallback_mode, "Debería entrar a modo fallback tras el error")
	runner.assert_false(dialog.input_line.editable, "El input debería bloquearse")
	runner.assert_false(dialog.input_line.visible, "El input_line debe ocultarse visualmente")
	runner.assert_false(dialog.send_button.visible, "El send_button debe ocultarse visualmente")
	runner.assert_eq(dialog._lines[0], "Hola soy Carlos", "El texto original no debió modificarse por el error")
	
	var badges = dialog.badge_container.get_children()
	runner.assert_eq(badges.size(), 2, "Debería generar 2 botones para el fallback")
	
	if badges.size() == 2:
		var btn = badges[0] as Button
		runner.assert_true(btn.text == "¿Dónde estoy?", "El botón debe tener la pregunta de fallback")
		
		# Simular llamada en lugar de emitir señal para pruebas deterministas
		dialog._submit_fallback_message("¿Dónde estoy?")
		
		runner.assert_eq(dialog._lines[0], "Estás en la enfermería.", "Debería actualizar las líneas del diálogo con la respuesta estática")
	
	dialog.free()
