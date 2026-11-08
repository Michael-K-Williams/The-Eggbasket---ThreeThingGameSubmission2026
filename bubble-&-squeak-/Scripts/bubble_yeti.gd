# Player 1. Ability: blow a bubble in front of you (see bubble.gd for what it does).
class_name BubbleYeti
extends Yeti

var _bubble: Bubble = null


func _use_ability() -> void:
	# no blowing bubbles from inside a bubble, they just pile up on top of you
	if is_bubbled:
		return

	var bubble := Bubble.new()
	bubble.radius = _bubble_radius()
	bubble.owner_yeti = self

	# if there's a wall right in front, slide the bubble back towards us until it
	# fits, and if there's no room at all just don't blow one
	var far := _body_extents().x + bubble.radius + 4.0
	var spot := _free_spot(far, bubble.radius)
	if spot < 0.0:
		bubble.free()
		return

	# only one of our bubbles at a time
	if is_instance_valid(_bubble):
		_bubble.queue_free()
	get_parent().add_child(bubble)
	var mouth := global_position + Vector2(_facing * _body_extents().x, 0.0)
	var rest := global_position + Vector2(_facing * spot, 0.0)
	bubble.launch(mouth, rest)
	_bubble = bubble


# how far in front of us a bubble of this size can sit without being inside the
# level, or -1 if it can't. Only checks the world layer (1), not other players.
func _free_spot(far: float, radius: float) -> float:
	var circle := CircleShape2D.new()
	circle.radius = radius * 0.4   # smaller than the bubble itself, or the floor under our feet would count
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = circle
	query.collision_mask = 1
	var min_offset := _body_extents().x + radius * 0.5   # any closer and it's mostly on top of us
	var offset := far
	while offset >= min_offset:
		query.transform = Transform2D(0.0, global_position + Vector2(_facing * offset, 0.0))
		if get_world_2d().direct_space_state.intersect_shape(query, 1).is_empty():
			return offset
		offset -= 6.0
	return -1.0
