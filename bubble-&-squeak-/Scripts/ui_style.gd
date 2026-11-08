
class_name UiStyle
extends RefCounted

const TEXT := Color(0.95, 0.97, 1.0)
const ACCENT := Color(0.55, 0.85, 1.0)


static func button(b: Button, font_size := 20) -> void:
	b.add_theme_stylebox_override("normal", _box(Color(0.07, 0.09, 0.13, 0.82), Color(0.75, 0.9, 1.0, 0.35), 1))
	b.add_theme_stylebox_override("hover", _box(Color(0.12, 0.17, 0.24, 0.92), ACCENT, 2))
	b.add_theme_stylebox_override("focus", _box(Color(0.12, 0.17, 0.24, 0.92), ACCENT, 2))
	b.add_theme_stylebox_override("pressed", _box(Color(0.2, 0.32, 0.45, 0.95), ACCENT, 2))
	b.add_theme_font_size_override("font_size", font_size)
	b.add_theme_color_override("font_color", TEXT)
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.add_theme_color_override("font_focus_color", Color.WHITE)
	b.add_theme_color_override("font_pressed_color", Color.WHITE)
	b.custom_minimum_size = Vector2(240, 46)


static func _box(bg: Color, edge: Color, width: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = edge
	sb.set_border_width_all(width)
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	sb.content_margin_top = 6
	sb.content_margin_bottom = 8
	return sb


static func title(s: String, size: int, colour := TEXT) -> Label:
	var l := Label.new()
	l.text = s
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", colour)
	l.add_theme_color_override("font_outline_color", Color(0.05, 0.07, 0.1))
	l.add_theme_constant_override("outline_size", maxi(4, size / 6))
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l
