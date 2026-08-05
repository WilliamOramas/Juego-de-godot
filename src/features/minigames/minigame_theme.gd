class_name MiniGameTheme
extends RefCounted

const SILKSCREEN = preload("res://src/shared/fonts/Silkscreen-Regular.ttf")

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

const NEON_CYAN = Color(0.0, 0.9, 1.0)
const NEON_PINK = Color(1.0, 0.2, 0.6)
const NEON_GREEN = Color(0.0, 1.0, 0.4)
const NEON_YELLOW = Color(1.0, 0.9, 0.0)

const PANEL_BG_DARK = Color(0.0, 0.02, 0.05, 0.85)
const PANEL_BORDER_DARK = Color(0.1, 0.15, 0.2, 0.9)

static func _apply_font(label: Label, size: int) -> void:
	label.add_theme_font_override("font", SILKSCREEN)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_outline_color", Color.BLACK)

static func apply_primary(label: Label, size: int) -> void:
	_apply_font(label, size)
	label.add_theme_constant_override("outline_size", 4)

static func apply_body(label: Label, size: int) -> void:
	_apply_font(label, size)
	label.add_theme_constant_override("outline_size", 3)

static func apply_muted(label: Label, size: int) -> void:
	_apply_font(label, size)
	label.add_theme_constant_override("outline_size", 2)

static func style_text_panel(label: Label) -> void:
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.0, 0.0, 0.0, 0.65)
	bg.border_width_left = 2
	bg.border_width_top = 2
	bg.border_width_right = 2
	bg.border_width_bottom = 2
	bg.border_color = Color(0.3, 0.35, 0.5, 0.7)
	bg.corner_radius_top_left = 6
	bg.corner_radius_top_right = 6
	bg.corner_radius_bottom_left = 6
	bg.corner_radius_bottom_right = 6
	label.add_theme_stylebox_override("normal", bg)

static func style_progress_bar(bar: Range) -> void:
	var fill := StyleBoxFlat.new()
	fill.bg_color = BAR_FILL
	bar.add_theme_stylebox_override("fill", fill)
	var bg := StyleBoxFlat.new()
	bg.bg_color = BAR_BG
	bar.add_theme_stylebox_override("background", bg)

static func style_neon_panel(label: Label, accent_color: Color = NEON_CYAN) -> void:
	var bg := StyleBoxFlat.new()
	bg.bg_color = PANEL_BG_DARK
	bg.border_width_left = 2
	bg.border_width_top = 2
	bg.border_width_right = 2
	bg.border_width_bottom = 2
	bg.border_color = accent_color.lerp(PANEL_BORDER_DARK, 0.4)
	bg.corner_radius_top_left = 2
	bg.corner_radius_top_right = 2
	bg.corner_radius_bottom_left = 2
	bg.corner_radius_bottom_right = 2
	bg.shadow_color = accent_color * Color(1, 1, 1, 0.15)
	bg.shadow_size = 4
	bg.shadow_offset = Vector2(0, 0)
	label.add_theme_stylebox_override("normal", bg)
	label.add_theme_color_override("font_outline_color", accent_color * Color(1, 1, 1, 0.3))
	label.add_theme_constant_override("outline_size", 5)

static func style_neon_button(btn: Button, accent_color: Color = NEON_CYAN) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.0, 0.03, 0.06, 0.9)
	normal.border_width_left = 2
	normal.border_width_top = 2
	normal.border_width_right = 2
	normal.border_width_bottom = 2
	normal.border_color = accent_color.lerp(PANEL_BORDER_DARK, 0.3)
	normal.corner_radius_top_left = 4
	normal.corner_radius_top_right = 4
	normal.corner_radius_bottom_left = 4
	normal.corner_radius_bottom_right = 4
	normal.shadow_color = accent_color * Color(1, 1, 1, 0.1)
	normal.shadow_size = 3
	btn.add_theme_stylebox_override("normal", normal)

	var hover := normal.duplicate()
	hover.border_color = accent_color
	hover.shadow_color = accent_color * Color(1, 1, 1, 0.25)
	hover.shadow_size = 5
	btn.add_theme_stylebox_override("hover", hover)

	var pressed := normal.duplicate()
	pressed.bg_color = accent_color * Color(0.15, 0.15, 0.15, 0.9)
	pressed.border_color = accent_color
	pressed.shadow_color = accent_color * Color(1, 1, 1, 0.35)
	pressed.shadow_size = 6
	btn.add_theme_stylebox_override("pressed", pressed)

	var disabled := normal.duplicate()
	disabled.bg_color = Color(0.05, 0.05, 0.08, 0.6)
	disabled.border_color = PANEL_BORDER_DARK
	disabled.shadow_size = 0
	btn.add_theme_stylebox_override("disabled", disabled)

	btn.add_theme_font_override("font", SILKSCREEN)
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_color_override("font_outline_color", Color.BLACK)
	btn.add_theme_constant_override("outline_size", 3)

static func style_progress_bar_neon(bar: Range, accent_color: Color = NEON_GREEN) -> void:
	var fill := StyleBoxFlat.new()
	fill.bg_color = accent_color * Color(0.8, 0.8, 0.8, 0.9)
	fill.shadow_color = accent_color * Color(1, 1, 1, 0.2)
	fill.shadow_size = 4
	bar.add_theme_stylebox_override("fill", fill)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.05, 0.05, 0.08, 0.9)
	bg.border_width_left = 1
	bg.border_width_top = 1
	bg.border_width_right = 1
	bg.border_width_bottom = 1
	bg.border_color = accent_color.lerp(PANEL_BORDER_DARK, 0.6)
	bg.corner_radius_top_left = 3
	bg.corner_radius_top_right = 3
	bg.corner_radius_bottom_left = 3
	bg.corner_radius_bottom_right = 3
	bar.add_theme_stylebox_override("background", bg)
