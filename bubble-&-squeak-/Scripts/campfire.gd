class_name Campfire
extends Prop

@export var fire_size := Vector2(28, 14)
@export var heat_size := Vector2(40, 140)
@export var heat_strength := 450.0

var _zone: WindZone


func _init() -> void:
	mass = 4.0
	throw_speed = 400.0
	bounciness = 0.3
	sticks_to_walls = true
	starts_stuck = true  


func _make_shape() -> Shape2D:
	var r := RectangleShape2D.new()
	r.size = fire_size
	return r


func _build_extras() -> void:
	stick_depth = fire_size.y / 2.0

	_zone = WindZone.new()
	_zone.size = heat_size
	_zone.strength = heat_strength
	_zone.tint = Color(1.0, 0.65, 0.3, 1.0)
	_zone.position = Vector2(0, -(fire_size.y / 2.0 + heat_size.y / 2.0))
	add_child(_zone)


func _on_state_changed(new_state: State) -> void:
	if _zone != null:
		_zone.set_active(new_state == State.STUCK)   


func _draw() -> void:
	
	draw_rect(Rect2(-fire_size / 2.0, fire_size), Color(0.35, 0.22, 0.12))
	
	var top := -fire_size.y / 2.0
	draw_colored_polygon(PackedVector2Array([
		Vector2(-9, top), Vector2(0, top - 20), Vector2(9, top)]), Color(1.0, 0.5, 0.15))
	draw_colored_polygon(PackedVector2Array([
		Vector2(-4, top), Vector2(0, top - 11), Vector2(4, top)]), Color(1.0, 0.85, 0.3))
