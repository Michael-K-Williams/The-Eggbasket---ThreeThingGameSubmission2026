# A door that slides up out of the way when its plates are pressed.
# Point pressure plates at it with their `targets`. With plates_needed = 2
# both plates have to be held at once, which is the usual "one player each" puzzle.
# @tool so it draws in the editor, with a dashed outline where it'll slide to.
@tool
class_name Door
extends StaticBody2D

@export var size := Vector2(32, 96):
	set(v):
		size = v
		queue_redraw()
@export var plates_needed: int = 1
@export var stays_open: bool = false      # once open, never shuts again
@export var slide_time: float = 0.35
@export var open_offset := Vector2.ZERO:  # where it slides to, zero = straight up by its own height
	set(v):
		open_offset = v
		queue_redraw()

var is_open := false
var _held_by: Array[Node] = []
var _closed_pos := Vector2.ZERO
var _tween: Tween


func _ready() -> void:
	if Engine.is_editor_hint():
		return   # editor just draws it
	# on World and Player layers so it blocks yetis, cubes and props alike
	collision_layer = 1 | 2
	collision_mask = 0
	_closed_pos = position
	if open_offset == Vector2.ZERO:
		open_offset = Vector2(0, -size.y)

	var rect_shape := RectangleShape2D.new()
	rect_shape.size = size
	var cs := CollisionShape2D.new()
	cs.shape = rect_shape
	add_child(cs)


func plate_pressed(plate: Node) -> void:
	if not _held_by.has(plate):
		_held_by.append(plate)
	_update()


func plate_released(plate: Node) -> void:
	_held_by.erase(plate)
	_update()


func _update() -> void:
	var want_open := _held_by.size() >= plates_needed
	if is_open and stays_open:
		return
	if want_open == is_open:
		return
	is_open = want_open
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "position", _closed_pos + (open_offset if is_open else Vector2.ZERO), slide_time)


func _draw() -> void:
	draw_rect(Rect2(-size / 2.0, size), Color(0.32, 0.28, 0.36))
	draw_rect(Rect2(-size / 2.0, size), Color(0.15, 0.12, 0.18), false, 3.0)
	if Engine.is_editor_hint():
		var off := open_offset if open_offset != Vector2.ZERO else Vector2(0, -size.y)
		EditorDraw.dashed_rect(self, Rect2(off - size / 2.0, size), Color(0.6, 1.0, 0.6, 0.8))
		EditorDraw.label(self, off, "open")
