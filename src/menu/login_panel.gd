extends Control
class_name LoginPanel

@onready var title_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/Title
@onready var email_input: LineEdit = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/EmailInput
@onready var password_input: LineEdit = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/PasswordInput
@onready var action_button: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ActionButton
@onready var toggle_mode_button: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ToggleModeButton
@onready var info_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/InfoLabel
@onready var close_button: Button = $CloseButton

var is_login_mode: bool = true

func _ready() -> void:
	action_button.pressed.connect(_on_action_pressed)
	email_input.text_submitted.connect(func(_t): _on_action_pressed())
	password_input.text_submitted.connect(func(_t): _on_action_pressed())
	toggle_mode_button.pressed.connect(_on_toggle_mode_pressed)
	close_button.pressed.connect(_on_close_pressed)
	Supabase.auth_completed.connect(_on_auth_completed)
	_update_ui_mode()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("Pause"):
		get_viewport().set_input_as_handled()
		_on_close_pressed()

func _update_ui_mode() -> void:
	info_label.text = ""
	info_label.add_theme_color_override("font_color", Color(0.8, 0.2, 0.2)) # Darker Red for normal messages on light bg
	if is_login_mode:
		title_label.text = "Iniciar Sesión"
		action_button.text = "ENTRAR"
		toggle_mode_button.text = "¿No tienes cuenta? Crea una aquí."
	else:
		title_label.text = "Crear Cuenta"
		action_button.text = "REGISTRARSE"
		toggle_mode_button.text = "¿Ya tienes cuenta? Inicia sesión."

func _on_toggle_mode_pressed() -> void:
	is_login_mode = not is_login_mode
	_update_ui_mode()

func _on_action_pressed() -> void:
	var email = email_input.text.strip_edges()
	var password = password_input.text.strip_edges()
	
	if email == "" or password == "":
		info_label.text = "Por favor, llena todos los campos."
		return
		
	info_label.add_theme_color_override("font_color", Color(0.2, 0.5, 0.8)) # Blue for loading
	
	action_button.disabled = true
	
	if is_login_mode:
		info_label.text = "Iniciando sesión..."
		Supabase.login(email, password)
	else:
		info_label.text = "Registrando..."
		Supabase.register(email, password)

func _on_close_pressed() -> void:
	SceneManager.change_scene("res://src/menu/main_menu.tscn")

func _on_auth_completed(success: bool, message: String) -> void:
	action_button.disabled = false
	
	if success:
		info_label.add_theme_color_override("font_color", Color(0.1, 0.6, 0.3)) # Green for success
		info_label.text = message
		
		if is_login_mode:
			info_label.text = "Sincronizando partidas en la nube..."
			info_label.add_theme_color_override("font_color", Color(0.2, 0.5, 0.8)) # Blue
			
			SaveManager.sync_from_cloud(func(_s):
				SceneManager.change_scene("res://src/menu/main_menu.tscn")
			)
		else:
			# Registration success
			info_label.text = message + "\nRedirigiendo al login en 6 segundos..."
			await get_tree().create_timer(6.0).timeout
			is_login_mode = true
			_update_ui_mode()
			info_label.text = "¡Cuenta creada! Inicia sesión ahora."
			info_label.add_theme_color_override("font_color", Color(0.1, 0.6, 0.3))
	else:
		info_label.add_theme_color_override("font_color", Color(0.8, 0.2, 0.2)) # Red for error
		info_label.text = message
