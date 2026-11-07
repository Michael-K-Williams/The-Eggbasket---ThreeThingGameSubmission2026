# Anything in here sends a yeti back to the respawn point. Put one under the
# level for falling out of the world, or use it for spikes and water.
# spare_bubbled is for the ice water: a bubbled yeti floats on top instead.
# @tool so it draws in the editor too.
@tool
class_name KillZone
extends Area2D

@export var size := Vector2(200, 40):
	set(v):
		size = v
		queue_redraw()
@export var spare_bubbled: bool = false:
	set(v):
		spare_bubbled = v
		queue_redraw()
@export var tint := Color(0.9, 0.2, 0.2, 0.25):   # colour for the Plain look
	set(v):
		tint = v
		queue_redraw()
# Plain = a tinted box, Spikes = a row of spikes along the bottom, Water = icy water
@export_enum("Plain", "Spikes", "Water") var look: int = 0:
	set(v):
		look = v
		queue_redraw()
@export var spike_width: float = 16.0:
	set(v):
		spike_width = maxf(v, 4.0)
		queue_redraw()
@export var spike_height: float = 26.0:
	set(v):
		spike_height = v
		queue_redraw()

var _t := 0.0


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	collision_layer = 0
	collision_mask = 3   # players are on layer 2 in the levels, 1 on the bare player scene
	monitorable = false

	var lethal := _lethal_rect()
	var rect_shape := RectangleShape2D.new()
	rect_shape.size = lethal.size
	var cs := CollisionShape2D.new()
	cs.shape = rect_shape
	cs.position = lethal.get_center()
	add_child(cs)


# Spikes only hurt once you've dropped down onto the points, so you fall into
# the pit first instead of dying the moment you cross the edge. The zone's top
# stays where it was, it's just the sharp bit at the bottom that counts.
func _lethal_rect() -> Rect2:
	var full := Rect2(-size / 2.0, size)
	if look != 1:
		return full
	var h := minf(spike_height * 0.6, size.y)
	return Rect2(full.position.x, full.end.y - h, size.x, h)


# checked every frame rather than on body_entered, so a yeti whose bubble pops
# while inside the zone still dies
func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	var local := _lethal_rect()
	var rect := Rect2(global_position + local.position, local.size)
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


func _process(delta: float) -> void:
	# only the water moves
	if look == 2:
		_t += delta
		queue_redraw()


func _draw() -> void:
	match look:
		1:
			_draw_spikes()
		2:
			_draw_water()
		_:
			draw_rect(Rect2(-size / 2.0, size), tint)
	if Engine.is_editor_hint():
		draw_rect(Rect2(-size / 2.0, size), Color(tint, 0.9), false, 1.5)
		EditorDraw.label(self, Vector2.ZERO, "kill zone, bubbles safe" if spare_bubbled else "kill zone")



# a row of steel spikes standing on the bottom edge of the zone
func _draw_spikes() -> void:
	var left := -size.x / 2.0
	var bottom := size.y / 2.0
	var h := minf(spike_height, size.y)
	var n := maxi(1, int(round(size.x / spike_width)))
	var w := size.x / n
	var steel := Color(0.72, 0.76, 0.83)
	var shade := Color(0.45, 0.49, 0.57)
	var shine := Color(0.95, 0.97, 1.0)
	var edge := Color(0.18, 0.2, 0.26)
	# base plate
	draw_rect(Rect2(left, bottom - 4.0, size.x, 4.0), shade)
	for i in n:
		var x0 := left + i * w
		var tip := Vector2(x0 + w / 2.0, bottom - h)
		var a := Vector2(x0, bottom - 3.0)
		var b := Vector2(x0 + w, bottom - 3.0)
		var mid := Vector2(x0 + w / 2.0, bottom - 3.0)
		# lit left face, shaded right face
		draw_colored_polygon(PackedVector2Array([a, tip, mid]), steel)
		draw_colored_polygon(PackedVector2Array([mid, tip, b]), shade)
		draw_polyline(PackedVector2Array([a, tip, b]), edge, 1.5, true)
		draw_line(tip + Vector2(-1.0, 3.0), a.lerp(tip, 0.35) + Vector2(1.5, 0.0), shine, 1.0, true)


# icy water with a gently moving surface
func _draw_water() -> void:
	var left := -size.x / 2.0
	var top := -size.y / 2.0
	draw_rect(Rect2(left, top, size.x, size.y), Color(0.35, 0.62, 0.85, 0.75))
	draw_rect(Rect2(left, top + size.y * 0.55, size.x, size.y * 0.45), Color(0.2, 0.42, 0.68, 0.5))
	var pts := PackedVector2Array()
	var steps := maxi(8, int(size.x / 8.0))
	for i in steps + 1:
		var x := left + size.x * i / steps
		pts.append(Vector2(x, top + 3.0 + sin(x * 0.06 + _t * 2.2) * 2.0))
	draw_polyline(pts, Color(0.88, 0.96, 1.0, 0.95), 2.0, true)
	# a few glints
	for i in 4:
		var gx := left + fposmod(size.x * (0.15 + i * 0.27) + _t * 12.0, size.x)
		draw_line(Vector2(gx, top + 10.0 + i * 5.0), Vector2(gx + 8.0, top + 10.0 + i * 5.0), Color(1, 1, 1, 0.45), 1.0)
