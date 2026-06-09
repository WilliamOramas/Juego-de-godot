class_name MiniGameTheme
extends RefCounted

const SILKSCREEN = preload("res://src/fonts/Silkscreen-Regular.ttf")

const SUCCESS = Color(0.0, 0.6, 0.0)
const WARNING = Color(1.0, 0.8, 0.0)
const DANGER = Color(1.0, 0.2, 0.2)

const FEEDBACK_GOOD = Color(0, 1, 0)
const FEEDBACK_WARN = Color(1, 1, 0)
const FEEDBACK_BAD = Color(1, 0, 0)

const TEXT_PRIMARY = Color(1, 1, 1)
const TEXT_SECONDARY = Color(0.7, 0.7, 0.9)
const TEXT_MUTED = Color(0.7, 0.7, 0.7)
const DIAL = Color(0, 1, 0.8)

const BAR_FILL = Color(0.0, 0.6, 0.0, 0.8)
const BAR_BG = Color(0.15, 0.15, 0.15, 0.8)

static func _apply_font(label: Label, size: int) -> void:
	label.add_theme_font_override("font", SILKSCREEN)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_outline_color", Color.BLACK)

static func apply_primary(label: Label, size: int) -> void:
	_apply_font(label, size)
	label.add_theme_constant_override("outline_size", 3)

static func apply_body(label: Label, size: int) -> void:
	_apply_font(label, size)
	label.add_theme_constant_override("outline_size", 2)

static func apply_muted(label: Label, size: int) -> void:
	_apply_font(label, size)
	label.add_theme_constant_override("outline_size", 1)

static func style_progress_bar(bar: TextureProgressBar) -> void:
	var fill := StyleBoxFlat.new()
	fill.bg_color = BAR_FILL
	bar.add_theme_stylebox_override("fill", fill)
	var bg := StyleBoxFlat.new()
	bg.bg_color = BAR_BG
	bar.add_theme_stylebox_override("background", bg)
