# Little drawing helpers for the editor-only previews on doors, plates,
# hints and so on (those scripts are @tool). Nothing here runs in the game.
@tool
class_name EditorDraw
extends RefCounted


static func dashed_rect(ci: CanvasItem, r: Rect2, col: Color, width := 1.5, dash := 6.0) -> void:
	var a := r.position
	var b := Vector2(r.end.x, r.position.y)
	var c := r.end
	var d := Vector2(r.position.x, r.end.y)
	ci.draw_dashed_line(a, b, col, width, dash)
	ci.draw_dashed_line(b, c, col, width, dash)
	ci.draw_dashed_line(c, d, col, width, dash)
	ci.draw_dashed_line(d, a, col, width, dash)


static func label(ci: CanvasItem, centre: Vector2, text: String, col := Color(1, 1, 1, 0.9), size := 11) -> void:
	var font := ThemeDB.fallback_font
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	ci.draw_string(font, centre + Vector2(-w / 2.0, size / 2.0 - 1.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)
