class_name Fan
extends Prop

@export var fan_size := Vector2(40, 14)
@export var tunnel_size := Vector2(48, 220)
@export var wind_strength := 700.0

var _zone: WindZone


func _init() -> void:
	mass = 3.0
	throw_speed = 480.0
	bounciness = 0.3  
	sticks_to_walls = true


func _make_shape() -> Shape2D:
	var r := RectangleShape2D.new()
	r.size = fan_size
	return r


func _build_extras() -> void:
	stick_depth = fan_size.y / 2.0

	_zone = WindZone.new()
	_zone.size = tunnel_size
	_zone.strength = wind_strength
	
	_zone.position = Vector2(0, -(fan_size.y / 2.0 + tunnel_size.y / 2.0))
	add_child(_zone)



func _on_state_changed(new_state: State) -> void:
	if _zone != null:
		_zone.set_active(new_state == State.STUCK)


func _draw() -> void:
	draw_rect(Rect2(-fan_size / 2.0, fan_size), Color(0.35, 0.42, 0.55))
