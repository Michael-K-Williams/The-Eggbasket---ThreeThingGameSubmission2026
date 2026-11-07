# A tooltip that only shows up when it matters: fades in when a yeti walks
# into its trigger area and fades back out when they've all left.
# Drop Scenes/hint.tscn in a level, write the text, size the trigger area and
# move the box with box_offset (it's relative to the hint's position).
# @tool so the editor shows the box and the trigger area while you place it.
@tool
class_name Hint
extends Area2D

@export_multiline var text: String = "":
	set(v):
		text = v
		queue_redraw()
@export var trigger_size := Vector2(240, 140):
	set(v):
		trigger_size = v
		queue_redraw()
@export var box_offset := Vector2(0, -120):
	set(v):
		box_offset = v
		queue_redraw()
@export var font_size: int = 15:
	set(v):
		font_size = v
		queue_redraw()
@export var fade_time: float = 0.3
@export var always_show: bool = false

const BG := Color(0.07, 0.09, 0.13, 0.85)
const EDGE := Color(0.75, 0.9, 1.0, 0.45)

var _box: PanelContainer
var _shown := false
var _tween: Tween
var _rest_pos := Vector2.ZERO


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	collision_layer = 0
	collision_mask = 2   # yetis
	monitorable = false

	var rect := RectangleShape2D.new()
	rect.size = trigger_size
	var cs := CollisionShape2D.new()
	cs.shape = rect
	add_child(cs)

	_box = PanelContainer.new()
	_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_box.add_theme_stylebox_override("panel", box_style())
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color(0.95, 0.97, 1.0))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_box.add_child(label)
	_box.z_index = 20
	add_child(_box)

	# centre the box on box_offset
	_box.size = _box.get_combined_minimum_size()
	_rest_pos = box_offset - _box.size / 2.0
	_box.position = _rest_pos + Vector2(0, 6)
	_box.modulate.a = 0.0

	if always_show:
		_set_shown(true)


# shared with the controls legend so the UI all matches
static func box_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = BG
	sb.border_color = EDGE
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 7
	sb.content_margin_bottom = 8
	sb.shadow_color = Color(0, 0, 0, 0.25)
	sb.shadow_size = 4
	return sb


func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint() or always_show:
		return
	var near := false
	for body in get_overlapping_bodies():
		var yeti := body as Yeti
		if yeti != null and not yeti.in_cave:
			near = true
			break
	if near != _shown:
		_set_shown(near)


func _set_shown(value: bool) -> void:
	_shown = value
	if _tween:
		_tween.kill()
	_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_tween.tween_property(_box, "modulate:a", 1.0 if value else 0.0, fade_time)
	# floats up into place as it appears, sinks a touch as it goes
	_tween.tween_property(_box, "position", _rest_pos if value else _rest_pos + Vector2(0, 6), fade_time)


func is_showing() -> bool:
	return _shown


# editor preview: the trigger area and roughly where the box will sit
func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	EditorDraw.dashed_rect(self, Rect2(-trigger_size / 2.0, trigger_size), Color(1.0, 0.85, 0.3, 0.7))
	var font := ThemeDB.fallback_font
	var shown := text if text != "" else "(empty hint)"
	var t := font.get_multiline_string_size(shown, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	var pad := Vector2(24, 15)
	var box := Rect2(box_offset - (t + pad) / 2.0, t + pad)
	draw_style_box(box_style(), box)
	draw_multiline_string(font, box.position + Vector2(12, 7 + font.get_ascent(font_size)), shown,
		HORIZONTAL_ALIGNMENT_CENTER, t.x, font_size, -1, Color(0.95, 0.97, 1.0))
