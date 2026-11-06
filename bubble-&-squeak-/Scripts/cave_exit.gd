class_name CaveExit
extends Node2D

@export var size := Vector2(64, 80)        # match the entrance cave's size
@export var hold_black: float = 0.1        # stays fully black while players get hidden
@export var fade_time: float = 0.25        # fade-in from black (keep short for a seamless feel)
@export var start_delay: float = 0.1       # pause on the empty cave before they step out
@export var stagger: float = 0.0           # 0 = both step out together
@export var spread: float = 14.0           # horizontal gap between players so they don't overlap


func _draw() -> void:
	CaveEntrance.draw_cave(self, size)


func _ready() -> void:
	# fully black from the very first frame, so nothing pops in
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

	var players: Array = get_tree().current_scene.find_children("*", "Yeti", true, false)
	print("CaveExit found players: ", players.size())
	players.sort_custom(func(a, b): return a.player_id < b.player_id)

	
	for p in players:
		p.enter_cave(global_position, false)

	await get_tree().create_timer(hold_black).timeout

	var tween := create_tween()
	tween.tween_property(fade, "modulate:a", 0.0, fade_time)
	await tween.finished
	await get_tree().create_timer(start_delay).timeout

	# step out
	for i in players.size():
		var p = players[i]
		var ext: Vector2 = p._body_extents()
		var x := (i - (players.size() - 1) / 2.0) * spread
		p.leave_cave(global_position + Vector2(x, size.y / 2.0 - ext.y))
		if stagger > 0.0:
			await get_tree().create_timer(stagger).timeout

	layer.queue_free()
