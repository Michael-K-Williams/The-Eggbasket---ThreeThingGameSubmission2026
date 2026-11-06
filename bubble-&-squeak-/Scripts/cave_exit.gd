class_name CaveExit
extends Node2D

@export var size := Vector2(64, 80)       
@export var start_delay: float = 0.3
@export var stagger: float = 0.5        
@export var fade_time: float = 0.6


func _draw() -> void:
	CaveEntrance.draw_cave(self, size)


func _ready() -> void:
	
	var layer := CanvasLayer.new()
	layer.layer = 100
	var fade := ColorRect.new()
	fade.color = Color.BLACK
	fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(fade)
	add_child(layer)

	
	await get_tree().process_frame
	await get_tree().process_frame

	var players := get_tree().get_nodes_in_group("players")
	players.sort_custom(func(a, b): return a.player_id < b.player_id)


	for p in players:
		p.enter_cave(global_position, false)

	var tween := create_tween()
	tween.tween_property(fade, "modulate:a", 0.0, fade_time)
	await tween.finished
	await get_tree().create_timer(start_delay).timeout

	
	for p in players:
		var ext: Vector2 = p._body_extents()
		p.leave_cave(global_position + Vector2(0.0, size.y / 2.0 - ext.y))
		await get_tree().create_timer(stagger).timeout

	layer.queue_free()
