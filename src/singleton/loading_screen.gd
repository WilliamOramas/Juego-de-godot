extends CanvasLayer
class_name LoadingScreen

const LOADING_DOTS := ["", ".", "..", "..."]
const MIN_DISPLAY_TIME: float = 0.5
const PIXEL_SCALE := Vector2(0.5, 0.5)

const LOADING_TIPS := [
	"Presiona Q para abrir tu teléfono.",
	"Habla con todos los estudiantes para descubrir secretos.",
	"Revisa tu diario con la tecla J.",
	"Completa misiones para ganar puntos de rango.",
	"Ayuda a los estudiantes para salvar el día.",
	"Puedes ajustar el volumen en Opciones.",
	"Presiona F11 para pantalla completa.",
	"Tus decisiones afectan el destino de los personajes.",
	"Los minijuegos ponen a prueba tus conocimientos.",
	"Explora cada nivel para encontrar objetos interactivos.",
]

var _progress_bar: ProgressBar
var _tip_label: Label
var _dots_label: Label
var _progress_label: Label
var _dot_timer: float = 0.0
var _dot_index: int = 0

func _ready() -> void:
	layer = 101
	_build_ui()
	hide()

func _build_ui() -> void:
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.85)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	vbox.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.size_flags_vertical = Control.SIZE_EXPAND
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(vbox)

	var pixel_scene := load("res://src/menu/pixel.tscn") as PackedScene
	if pixel_scene:
		var pixel: Control = pixel_scene.instantiate()
		pixel.scale = PIXEL_SCALE
		var bubble = pixel.get_node_or_null("SpeechBubble")
		if bubble:
			bubble.hide()
		vbox.add_child(pixel)

	var font := load("res://src/fonts/m5x7.ttf") as Font

	var loading_hbox := HBoxContainer.new()
	loading_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(loading_hbox)

	var loading_label := Label.new()
	loading_label.text = "CARGANDO"
	if font:
		loading_label.add_theme_font_override("font", font)
	loading_label.add_theme_font_size_override("font_size", 22)
	loading_label.add_theme_color_override("font_color", Color(0.227, 0.886, 0.886, 1))
	loading_hbox.add_child(loading_label)

	_dots_label = Label.new()
	_dots_label.text = "..."
	if font:
		_dots_label.add_theme_font_override("font", font)
	_dots_label.add_theme_font_size_override("font_size", 22)
	_dots_label.add_theme_color_override("font_color", Color(0.227, 0.886, 0.886, 1))
	loading_hbox.add_child(_dots_label)

	_progress_bar = ProgressBar.new()
	_progress_bar.custom_minimum_size = Vector2(280, 14)
	_progress_bar.value = 0
	_progress_bar.max_value = 100
	_progress_bar.show_percentage = false

	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = Color(0.2, 0.2, 0.25, 1)
	bg_style.border_width_left = 1
	bg_style.border_width_top = 1
	bg_style.border_width_right = 1
	bg_style.border_width_bottom = 1
	bg_style.border_color = Color(0.3, 0.3, 0.35, 1)
	bg_style.corner_radius_top_left = 4
	bg_style.corner_radius_top_right = 4
	bg_style.corner_radius_bottom_right = 4
	bg_style.corner_radius_bottom_left = 4
	_progress_bar.add_theme_stylebox_override("background", bg_style)

	var fill_style := StyleBoxFlat.new()
	fill_style.bg_color = Color(0.227, 0.886, 0.886, 1)
	fill_style.corner_radius_top_left = 3
	fill_style.corner_radius_top_right = 3
	fill_style.corner_radius_bottom_right = 3
	fill_style.corner_radius_bottom_left = 3
	_progress_bar.add_theme_stylebox_override("fill", fill_style)

	vbox.add_child(_progress_bar)

	_progress_label = Label.new()
	_progress_label.text = "0%"
	_progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if font:
		_progress_label.add_theme_font_override("font", font)
	_progress_label.add_theme_font_size_override("font_size", 10)
	_progress_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 1))
	vbox.add_child(_progress_label)

	var tip_sep := HSeparator.new()
	tip_sep.custom_minimum_size = Vector2(200, 0)
	vbox.add_child(tip_sep)

	_tip_label = Label.new()
	_tip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tip_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tip_label.custom_minimum_size = Vector2(400, 40)
	if font:
		_tip_label.add_theme_font_override("font", font)
	_tip_label.add_theme_font_size_override("font_size", 11)
	_tip_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6, 1))
	vbox.add_child(_tip_label)

func _process(delta: float) -> void:
	if not visible:
		return
	_dot_timer += delta
	if _dot_timer >= 0.35:
		_dot_timer = 0.0
		_dot_index = (_dot_index + 1) % LOADING_DOTS.size()
		_dots_label.text = LOADING_DOTS[_dot_index]

func load_scene_async(target_path: String, min_display_time: float = MIN_DISPLAY_TIME) -> PackedScene:
	_tip_label.text = LOADING_TIPS[randi() % LOADING_TIPS.size()]
	_progress_bar.value = 0
	_progress_label.text = "0%"
	show()

	var elapsed: float = 0.0
	while elapsed < min_display_time:
		var pct: float = elapsed / min_display_time
		_progress_bar.value = pct * 90.0
		_progress_label.text = "%d%%" % (pct * 90.0)
		elapsed += get_process_delta_time()
		await get_tree().process_frame

	var scene: PackedScene = load(target_path) as PackedScene
	_progress_bar.value = 100
	_progress_label.text = "100%"
	await get_tree().create_timer(0.15).timeout

	hide()
	return scene
