class_name CaveEntrance
extends Area2D

const ORB_COLORS := {
	1: Color(0.3, 0.6, 1.0),   # Bubble (blue)
	2: Color(1.0, 0.3, 0.3),   # Squeak (red)
}

@export_file("*.tscn") var next_level_path: String = ""
@export var size := Vector2(64, 80)        
@export var require_all_players: bool = true
@export var fade_time: float = 0.6
@export var beat_before_fade: float = 0.6  
@export var orb_radius: float = 9.0
@export var orb_spacing: float = 26.0
@export var orb_height: float = 24.0       

var _nearby: Array[Yeti] = []  
var _inside: Array[Yeti] = []   
var _transitioning := false
var _time := 0.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2   
	monitorable = false

	var rect_shape := RectangleShape2D.new()
	rect_shape.size = size
	var cs := CollisionShape2D.new()
	cs.shape = rect_shape
	add_child(cs)

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node2D) -> void:
	var yeti := body as Yeti
	if yeti != null and not _nearby.has(yeti):
		_nearby.append(yeti)
	print("cave touched by: ", body, " is Yeti: ", body is Yeti)


func _on_body_exited(body: Node2D) -> void:
	var yeti := body as Yeti
	if yeti != null:
		_nearby.erase(yeti)


func _physics_process(delta: float) -> void:
	_time += delta
	queue_redraw()   
	if _transitioning:
		return

	for yeti in _nearby.duplicate():
		if not _inside.has(yeti) and Input.is_action_just_pressed("p%d_up" % yeti.player_id):
			_enter(yeti)

	for yeti in _inside.duplicate():
		if Input.is_action_just_pressed("p%d_down" % yeti.player_id):
			_leave(yeti)


func _enter(yeti: Yeti) -> void:
	_inside.append(yeti)
	yeti.enter_cave(global_position)
	_check_ready()


func _leave(yeti: Yeti) -> void:
	_inside.erase(yeti)
	var ext := yeti._body_extents()
	yeti.leave_cave(global_position + Vector2(0.0, size.y / 2.0 - ext.y))


func _check_ready() -> void:
	var needed := 1
	if require_all_players:
		needed = get_tree().get_nodes_in_group("players").size()
	if _inside.size() < needed:
		return

	_transitioning = true   
	if next_level_path == "":
		push_warning("CaveEntrance has no next_level_path set")
		return

	await get_tree().create_timer(beat_before_fade).timeout

	var layer := CanvasLayer.new()
	layer.layer = 100
	var fade := ColorRect.new()
	fade.color = Color.BLACK
	fade.modulate.a = 0.0
	fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(fade)
	add_child(layer)

	var tween := create_tween()
	tween.tween_property(fade, "modulate:a", 1.0, fade_time)
	await tween.finished
	get_tree().change_scene_to_file(next_level_path)




func _draw() -> void:
	CaveEntrance.draw_cave(self, size)


	for i in _inside.size():
		var yeti := _inside[i]
		var col: Color = ORB_COLORS.get(yeti.player_id, Color.WHITE)
		var x := (i - (_inside.size() - 1) / 2.0) * orb_spacing
		var y := -size.y / 2.0 - orb_height + sin(_time * 3.0 + i) * 3.0
		var c := Vector2(x, y)
		draw_circle(c, orb_radius, Color(col, 0.35))
		draw_arc(c, orb_radius, 0.0, TAU, 24, Color(col, 0.9), 2.0, true)
		draw_circle(c + Vector2(-orb_radius * 0.3, -orb_radius * 0.3), orb_radius * 0.25, Color(1, 1, 1, 0.6))


static func draw_cave(node: CanvasItem, cave_size: Vector2) -> void:
	var dark := Color(0.08, 0.06, 0.1)
	var edge := Color(0.35, 0.3, 0.38)
	var r := cave_size.x / 2.0
	var top := -cave_size.y / 2.0
	# arched top + rectangular body
	node.draw_circle(Vector2(0, top + r), r, dark)
	node.draw_rect(Rect2(-r, top + r, cave_size.x, cave_size.y - r), dark)
	node.draw_arc(Vector2(0, top + r), r, PI, TAU, 24, edge, 3.0, true)
	node.draw_line(Vector2(-r, top + r), Vector2(-r, cave_size.y / 2.0), edge, 3.0)
	node.draw_line(Vector2(r, top + r), Vector2(r, cave_size.y / 2.0), edge, 3.0)
