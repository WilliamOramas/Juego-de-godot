extends CanvasLayer
class_name LoadingScreen

const LOADING_DOTS := ["", ".", "..", "..."]
const MIN_DISPLAY_TIME: float = 0.5

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

@onready var _progress_bar: ProgressBar = $Center/VBox/ProgressBar
@onready var _tip_label: Label = $Center/VBox/TipLabel
@onready var _dots_label: Label = $Center/VBox/LoadingHBox/DotsLabel
@onready var _progress_label: Label = $Center/VBox/ProgressLabel

var _dot_timer: float = 0.0
var _dot_index: int = 0

func _ready() -> void:
	hide()

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
