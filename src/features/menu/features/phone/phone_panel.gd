extends CanvasLayer
class_name PhonePanel

signal closed

var _overlay: ColorRect
var _main_panel: Panel
var _font: Font

func _init() -> void:
	layer = 50
	process_mode = PROCESS_MODE_ALWAYS

func _ready() -> void:
	_font = load("res://src/shared/fonts/coolvetica/Coolvetica Rg.otf") as Font
	build_ui()

func build_ui() -> void:
	_overlay = ColorRect.new()
	_overlay.color = Color(0, 0, 0, 0.6)
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(_overlay)

	_main_panel = Panel.new()
	_main_panel.set_size(Vector2(500, 450))
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.117647, 0.117647, 0.137255, 0.95)
	panel_style.border_width_left = 2
	panel_style.border_width_top = 2
	panel_style.border_width_right = 2
	panel_style.border_width_bottom = 2
	panel_style.border_color = Color(0.294118, 0.294118, 0.352941, 1)
	panel_style.corner_radius_top_left = 4
	panel_style.corner_radius_top_right = 4
	panel_style.corner_radius_bottom_right = 4
	panel_style.corner_radius_bottom_left = 4
	_main_panel.add_theme_stylebox_override("panel", panel_style)
	add_child(_main_panel)
	call_deferred(&"_center_panel")

func _center_panel() -> void:
	var vs := get_viewport().get_visible_rect().size
	_main_panel.position = vs / 2 - _main_panel.size / 2

func close() -> void:
	var tw := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw.tween_property(_overlay, "modulate", Color.TRANSPARENT, 0.15)
	tw.parallel().tween_property(_main_panel, "modulate", Color.TRANSPARENT, 0.15)
	await tw.finished
	closed.emit()
	queue_free()
