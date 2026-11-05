class_name BubbleVisual
extends Node2D

@export var radius: float = 30.0:
	set(value):
		radius = value
		queue_redraw()
@export var fill_color := Color(0.6, 0.85, 1.0, 0.22)
@export var edge_color := Color(0.85, 0.95, 1.0, 0.7)


func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, fill_color)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 48, edge_color, 2.0, true)
	# little shine so it reads as a bubble
	draw_arc(Vector2.ZERO, radius * 0.72, deg_to_rad(200), deg_to_rad(250), 12, Color(1, 1, 1, 0.6), 2.0, true)
