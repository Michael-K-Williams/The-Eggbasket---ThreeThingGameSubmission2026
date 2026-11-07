# Anything in here sends a yeti back to the respawn point. Put one under the
# level for falling out of the world, or use it for spikes and water.
# spare_bubbled is for the ice water: a bubbled yeti floats on top instead.
class_name KillZone
extends Area2D

@export var size := Vector2(200, 40)
@export var spare_bubbled: bool = false


func _ready() -> void:
	collision_layer = 0
	collision_mask = 3   # players are on layer 2 in the levels, 1 on the bare player scene
	monitorable = false

	var rect_shape := RectangleShape2D.new()
	rect_shape.size = size
	var cs := CollisionShape2D.new()
	cs.shape = rect_shape
	add_child(cs)


# checked every frame rather than on body_entered, so a yeti whose bubble pops
# while inside the zone still dies
func _physics_process(_delta: float) -> void:
	var rect := Rect2(global_position - size / 2.0, size)
	for node in get_tree().get_nodes_in_group("yetis"):
		var yeti := node as Yeti
		if yeti == null or yeti.in_cave:
			continue
		if not _touches(yeti, rect):
			continue
		if spare_bubbled and yeti.is_bubbled:
			continue
		yeti.die()


# the body counts, and so does the whole bubble if they're in one,
# since it sticks out about 20px past the body on each side
func _touches(yeti: Yeti, rect: Rect2) -> bool:
	if overlaps_body(yeti):
		return true
	if not yeti.is_bubbled:
		return false
	var centre := yeti.global_position
	var nearest := centre.clamp(rect.position, rect.end)
	return centre.distance_to(nearest) <= yeti._bubble_radius()


func _draw() -> void:
	# placeholder look so you can see where it is
	draw_rect(Rect2(-size / 2.0, size), Color(0.9, 0.2, 0.2, 0.25))
