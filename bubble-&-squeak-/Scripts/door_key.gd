class_name DoorKey
extends Prop


func _init() -> void:
	mass = 0.5
	throw_speed = 550.0
	bounciness = 0.3
	sticks_to_walls = false   # the door handles it, so it never sticks to ordinary walls
	trail_color = Color(1.0, 0.85, 0.3, 0.6)


func _make_shape() -> Shape2D:
	var r := RectangleShape2D.new()
	r.size = Vector2(22, 8)
	return r


# called by LockedDoor. Slides the key into the lock, turns it, then fades it out
func use_on(lock_pos: Vector2) -> Tween:
	remove_from_group("props")   # can't be picked up any more
	linear_velocity = Vector2.ZERO
	_trail.clear_points()
	_set_state(State.STUCK)
	z_index = 5

	var t := create_tween()
	t.tween_property(self, "global_position", lock_pos, 0.15)
	t.parallel().tween_property(self, "rotation", 0.0, 0.15)
	t.tween_interval(0.1)
	t.tween_property(self, "rotation", PI / 2.0, 0.35)   # the turn
	t.tween_interval(0.15)
	t.tween_property(self, "modulate:a", 0.0, 0.2)
	return t


func _draw() -> void:
	var gold := Color(1.0, 0.82, 0.25)
	var dark := Color(0.55, 0.4, 0.1)
	draw_circle(Vector2(-7, 0), 4.5, gold)       # bow
	draw_circle(Vector2(-7, 0), 1.8, dark)
	draw_rect(Rect2(-3, -1, 14, 2), gold)        # shaft
	draw_rect(Rect2(6, 1, 2, 3), gold)           # teeth
	draw_rect(Rect2(9, 1, 2, 3), gold)
