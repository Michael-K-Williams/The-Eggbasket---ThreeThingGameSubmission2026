# Follows both players: sits on the midpoint between them and zooms out when
# they spread apart, so neither goes off screen. Never shows past the level's
# edges (set limit_left/top/right/bottom on the camera to the level's size).
# On a level that's only one screen big it just stays put.
class_name CoopCamera
extends Camera2D

@export var margin := Vector2(220, 160)   # space kept around the players, in pixels
@export var min_zoom: float = 0.6         # how far it's allowed to zoom out (smaller = further)
@export var max_zoom: float = 1.0         # how close it gets when they're together
@export var follow_speed: float = 4.0     # higher = snappier
@export var edge_padding: float = 24.0    # how close to the screen edge a player can get


func _ready() -> void:
	position_smoothing_enabled = false   # we do our own easing
	make_current()
	# start in place so the first frame doesn't swoop across the level
	var t := _target()
	if t.has("pos"):
		global_position = t.pos
		zoom = Vector2.ONE * t.zoom


func _process(delta: float) -> void:
	var t := _target()
	if not t.has("pos"):
		return
	var k := 1.0 - exp(-follow_speed * delta)
	global_position = global_position.lerp(t.pos, k)
	zoom = zoom.lerp(Vector2.ONE * t.zoom, k)


# keeps both players on screen: if the camera can't zoom out any further, the
# edge of the view acts like a wall so neither can run off and lose the other
func _physics_process(_delta: float) -> void:
	var view := get_viewport_rect().size / zoom
	var centre := get_screen_center_position()
	var left := centre.x - view.x / 2.0 + edge_padding
	var right := centre.x + view.x / 2.0 - edge_padding
	for y in get_tree().get_nodes_in_group("yetis"):
		if y.in_cave:
			continue
		if y.global_position.x < left:
			y.global_position.x = left
			y.velocity.x = maxf(y.velocity.x, 0.0)
		elif y.global_position.x > right:
			y.global_position.x = right
			y.velocity.x = minf(y.velocity.x, 0.0)


func _target() -> Dictionary:
	var yetis := get_tree().get_nodes_in_group("yetis")
	if yetis.is_empty():
		return {}
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for y in yetis:
		lo = lo.min(y.global_position)
		hi = hi.max(y.global_position)
	var view := get_viewport_rect().size
	var needed := (hi - lo) + margin * 2.0
	var z := minf(view.x / maxf(needed.x, 1.0), view.y / maxf(needed.y, 1.0))
	# never zoom out further than the level is big, or the limits would fight it
	var level := Vector2(limit_right - limit_left, limit_bottom - limit_top)
	z = maxf(z, maxf(view.x / level.x, view.y / level.y))
	z = clampf(z, min_zoom, max_zoom)
	return {"pos": (lo + hi) / 2.0, "zoom": z}
