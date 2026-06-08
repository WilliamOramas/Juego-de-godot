extends Control

const LOADING_DOTS := ["", ".", "..", "..."]
const MIN_DISPLAY_TIME: float = 1.5
const TRANSITION_SCENE: String = "res://src/menu/main_menu.tscn"

var _ready_to_transition: bool = false
var _dot_index: int = 0
var _dot_timer: float = 0.0
var _elapsed: float = 0.0

@onready var title_label: Label = $Center/VBox/Title
@onready var dots_label: Label = $Center/VBox/Dots
@onready var skip_hint: Label = $Center/VBox/SkipHint
@onready var pixel: Control = $Center/VBox/Pixel

func _ready() -> void:
	get_tree().paused = false

	var font := load("res://src/fonts/porky_s/PORKYS_.TTF") as Font
	if font:
		title_label.add_theme_font_override("font", font)
	title_label.add_theme_font_size_override("font_size", 52)
	title_label.add_theme_color_override("font_color", Color(0.47, 0.63, 0.99, 1))
	title_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0.35, 0.6))
	title_label.add_theme_constant_override("shadow_offset_x", 4)
	title_label.add_theme_constant_override("shadow_offset_y", 2)

	dots_label.add_theme_font_size_override("font_size", 14)
	dots_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6, 1))

	var hint_font := load("res://src/fonts/coolvetica/Coolvetica Rg.otf") as Font
	if hint_font:
		skip_hint.add_theme_font_override("font", hint_font)
	skip_hint.add_theme_font_size_override("font_size", 11)
	skip_hint.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4, 0.8))

	for c in [title_label, dots_label, skip_hint]:
		c.modulate.a = 0.0

	var tw := create_tween().set_parallel(true)
	tw.tween_property(title_label, "modulate:a", 1.0, 0.8).set_ease(Tween.EASE_OUT)
	tw.tween_property(dots_label, "modulate:a", 1.0, 1.0).set_delay(0.3).set_ease(Tween.EASE_OUT)
	tw.tween_property(skip_hint, "modulate:a", 0.6, 0.8).set_delay(1.5).set_ease(Tween.EASE_OUT)

	while _elapsed < MIN_DISPLAY_TIME and not _ready_to_transition:
		await get_tree().process_frame
		_elapsed += get_process_delta_time()

	SceneManager.change_scene(TRANSITION_SCENE)

func _process(delta: float) -> void:
	_dot_timer += delta
	if _dot_timer >= 0.4:
		_dot_timer = 0.0
		_dot_index = (_dot_index + 1) % LOADING_DOTS.size()
		dots_label.text = "Cargando" + LOADING_DOTS[_dot_index]

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		_ready_to_transition = true
		get_viewport().set_input_as_handled()
