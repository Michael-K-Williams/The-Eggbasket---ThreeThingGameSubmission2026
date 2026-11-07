# Player 1. Ability: blow a bubble in front of you (see bubble.gd for what it does).
class_name BubbleYeti
extends Yeti

var _bubble: Bubble = null


func _use_ability() -> void:
	# only one of our bubbles at a time
	if is_instance_valid(_bubble):
		_bubble.queue_free()

	var bubble := Bubble.new()
	bubble.radius = _bubble_radius()
	get_parent().add_child(bubble)
	bubble.global_position = global_position + Vector2(
		_facing * (_body_extents().x + bubble.radius + 4.0), 0.0)
	_bubble = bubble
