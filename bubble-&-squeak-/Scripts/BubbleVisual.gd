class_name BubbleVisual
extends Node2D

@export var radius: float = 30.0:
	set(value):
		radius = value
		queue_redraw()
@export var fill_color := Color(0.6, 0.85, 1.0, 0.22)
@export var edge_color := Color(0.85, 0.95, 1.0, 0.7)
@export var max_shake: float = 4.0   # pixels it jitters by when it's about to pop

# 0 = calm, 1 = about to pop. Set by the yeti inside while they try to get out.
var shake: float = 0.0:
	set(value):
		shake = value
		if shake <= 0.0:
			position = Vector2.ZERO
		queue_redraw()


func _process(_delta: float) -> void:
	if shake > 0.0:
		position = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * max_shake * shake


func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, fill_color)
	var edge := edge_color.lerp(Color(1.0, 0.85, 0.7, 0.95), shake)   # warms up as it nears popping
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 48, edge, 2.0 + shake * 1.5, true)
	# little shine so it reads as a bubble
	draw_arc(Vector2.ZERO, radius * 0.72, deg_to_rad(200), deg_to_rad(250), 12, Color(1, 1, 1, 0.6), 2.0, true)
