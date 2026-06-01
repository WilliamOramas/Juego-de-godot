extends Panel

@onready var volume_slider: HSlider = $VBoxContainer/VolumeContainer/HSlider
@onready var volume_label: Label = $VBoxContainer/VolumeContainer/ValueLabel
@onready var fullscreen_check: CheckBox = $VBoxContainer/FullscreenContainer/CheckBox

func _ready() -> void:
	visible = false
	modulate.a = 0.0
	set_process_input(false)
	volume_slider.value_changed.connect(_on_volume_changed)
	fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	_update_fullscreen_state()

func show_panel() -> void:
	set_process_input(true)
	volume_slider.value = db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Master"))) * 100
	volume_label.text = str(roundi(volume_slider.value))
	_update_fullscreen_state()
	modulate.a = 0.0
	visible = true
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.15)

func hide_panel() -> void:
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.1)
	tween.tween_callback(func():
		visible = false
		set_process_input(false)
	)

func _on_volume_changed(value: float) -> void:
	volume_label.text = str(roundi(value))
	var db = linear_to_db(value / 100.0)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), db)

func _on_fullscreen_toggled(toggled: bool) -> void:
	if toggled:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _update_fullscreen_state() -> void:
	var mode = DisplayServer.window_get_mode()
	fullscreen_check.button_pressed = mode == DisplayServer.WINDOW_MODE_FULLSCREEN

func _on_close_pressed() -> void:
	hide_panel()
