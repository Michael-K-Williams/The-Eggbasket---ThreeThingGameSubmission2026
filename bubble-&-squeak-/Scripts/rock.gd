class_name Rock
extends Prop

@export var radius: float = 6.0


func _init() -> void:
	mass = 0.4
	throw_speed = 1100.0
	bounciness = 0.3  
	sticks_to_walls = false


func _make_shape() -> Shape2D:
	var c := CircleShape2D.new()
	c.radius = radius
	return c


func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, Color(0.55, 0.55, 0.58))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 20, Color(0.3, 0.3, 0.33), 1.5, true)
