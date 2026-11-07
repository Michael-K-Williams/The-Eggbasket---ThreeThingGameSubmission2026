class_name Fan
extends StaticBody2D

@export var fan_size := Vector2(40, 14)
@export var wind_direction := Vector2.ZERO
@export var tunnel_size := Vector2(48, 220)
@export var wind_strength := 700.0


func _ready() -> void:
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

	var zone := WindZone.new()
	zone.size = tunnel_size
	zone.strength = wind_strength
	zone.position = Vector2(0, -(fan_size.y / 2.0 + tunnel_size.y / 2.0))
	add_child(zone)
