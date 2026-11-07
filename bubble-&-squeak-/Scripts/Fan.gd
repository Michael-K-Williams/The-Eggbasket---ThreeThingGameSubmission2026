# A fan you place in a level (Scenes/fan.tscn). Blows all the time in
# wind_direction. Set the direction in the inspector rather than rotating the
# node, the script sets the rotation itself.
# @tool so the editor shows the fan and an outline of where its wind reaches.
@tool
class_name Fan
extends StaticBody2D

@export var fan_size := Vector2(40, 14):
	set(v):
		fan_size = v
		queue_redraw()
@export var wind_direction := Vector2.UP:
	set(v):
		wind_direction = v
		queue_redraw()
@export var tunnel_size := Vector2(48, 220):
	set(v):
		tunnel_size = v
		queue_redraw()
@export var wind_strength := 700.0
@export var starts_on: bool = true   # a plate pointed at the fan flips it while held


# editor preview only, in game the fan builds real nodes in _ready
func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	var dir := wind_direction.normalized() if wind_direction != Vector2.ZERO else Vector2.UP
	draw_set_transform(Vector2.ZERO, Vector2.UP.angle_to(dir))
	draw_rect(Rect2(-fan_size / 2.0, fan_size), Color(0.35, 0.42, 0.55))
	var tunnel := Rect2(-tunnel_size.x / 2.0, -fan_size.y / 2.0 - tunnel_size.y, tunnel_size.x, tunnel_size.y)
	draw_rect(tunnel, Color(0.75, 0.92, 1.0, 0.12))
	EditorDraw.dashed_rect(self, tunnel, Color(0.75, 0.92, 1.0, 0.8))
	# arrow showing which way it blows
	var tip := Vector2(0, -fan_size.y / 2.0 - 40.0)
	draw_line(Vector2(0, -fan_size.y / 2.0 - 6.0), tip, Color(0.75, 0.92, 1.0), 2.0)
	draw_line(tip, tip + Vector2(-6, 8), Color(0.75, 0.92, 1.0), 2.0)
	draw_line(tip, tip + Vector2(6, 8), Color(0.75, 0.92, 1.0), 2.0)
	draw_set_transform(Vector2.ZERO, 0.0)


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	collision_layer = 1
	collision_mask = 0
	rotation = Vector2.UP.angle_to(wind_direction.normalized())

	var rect_shape := RectangleShape2D.new()
	rect_shape.size = fan_size
	var cs := CollisionShape2D.new()
	cs.shape = rect_shape
	add_child(cs)

	var body := ColorRect.new()
	body.size = fan_size
	body.position = -fan_size / 2.0
	body.color = Color(0.35, 0.42, 0.55)
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(body)
	_body = body

	var zone := WindZone.new()
	zone.size = tunnel_size
	zone.strength = wind_strength
	zone.position = Vector2(0, -(fan_size.y / 2.0 + tunnel_size.y / 2.0))
	add_child(zone)
	_zone = zone
	_set_running(starts_on)


# ---------- switching it with pressure plates ----------
# Put the fan in a plate's targets. Held down = the fan does the opposite of
# starts_on, so a plate can switch a fan off (or on) while something's on it.

var _zone: WindZone
var _body: ColorRect
var _held_by: Array[Node] = []
var running := true


func plate_pressed(plate: Node) -> void:
	if not _held_by.has(plate):
		_held_by.append(plate)
	_set_running(starts_on == _held_by.is_empty())


func plate_released(plate: Node) -> void:
	_held_by.erase(plate)
	_set_running(starts_on == _held_by.is_empty())


func _set_running(on: bool) -> void:
	running = on
	if _zone:
		_zone.set_active(on)
	if _body:
		_body.color = Color(0.35, 0.42, 0.55) if on else Color(0.22, 0.24, 0.3)