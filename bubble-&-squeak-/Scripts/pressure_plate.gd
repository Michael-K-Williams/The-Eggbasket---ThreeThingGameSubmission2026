# A button on the floor. Pressed while a yeti, a cube or a prop is sat on it.
# Drag the doors (or anything with plate_pressed / plate_released) into
# `targets` in the inspector and it'll tell them when it goes down and up.
# Bubbled yetis float, so they don't count as standing on it.
class_name PressurePlate
extends Area2D

signal pressed
signal released

@export var size := Vector2(48, 10)
@export var targets: Array[NodePath] = []
@export var stays_pressed: bool = false   # once pressed, stays down for good
@export var counts_props: bool = true     # whether a thrown rock is heavy enough

var is_pressed := false


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2 | 16   # players + cubes on 2, props on 16. Not 1, that's the floor it sits on
	monitorable = false

	var rect_shape := RectangleShape2D.new()
	rect_shape.size = size
	var cs := CollisionShape2D.new()
	cs.shape = rect_shape
	add_child(cs)


func _physics_process(_delta: float) -> void:
	var weighed_down := _something_on_it()
	if weighed_down and not is_pressed:
		_set_pressed(true)
	elif not weighed_down and is_pressed and not stays_pressed:
		_set_pressed(false)


func _something_on_it() -> bool:
	for body in get_overlapping_bodies():
		var yeti := body as Yeti
		if yeti != null:
			if not yeti.is_bubbled and not yeti.in_cave:
				return true
			continue
		if body is PushableCube:
			return true
		if counts_props and body is Prop:
			return true
	return false


func _set_pressed(value: bool) -> void:
	is_pressed = value
	queue_redraw()
	for path in targets:
		var target := get_node_or_null(path)
		if target == null:
			continue
		if value and target.has_method("plate_pressed"):
			target.plate_pressed(self)
		elif not value and target.has_method("plate_released"):
			target.plate_released(self)
	if value:
		pressed.emit()
	else:
		released.emit()


func _draw() -> void:
	# placeholder look, sits flush with the floor when pressed
	var h := size.y * (0.35 if is_pressed else 1.0)
	var top := size.y / 2.0 - h
	draw_rect(Rect2(-size.x / 2.0, top, size.x, h), Color(0.85, 0.65, 0.2) if is_pressed else Color(0.9, 0.35, 0.25))
	draw_rect(Rect2(-size.x / 2.0, top, size.x, h), Color(0.25, 0.2, 0.15), false, 2.0)
