@tool   # so the cave shows up in the editor, the arrival sequence below only runs in game
class_name CaveExit
extends Node2D

@export var size := Vector2(64, 80):       # match the entrance cave's size
	set(v):
		size = v
		queue_redraw()
@export var hold_black: float = 0.1        # stays fully black while players get hidden
@export var fade_time: float = 0.25        # fade-in from black (keep short for a seamless feel)
@export var start_delay: float = 0.1       # pause on the empty cave before they step out
@export var stagger: float = 0.0           # 0 = both step out together
@export var spread: float = 14.0           # horizontal gap between players so they don't overlap
@export var respawn_spread: float = 40.0   # gap when respawning after a death (a yeti is ~33 wide)


func _draw() -> void:
	CaveEntrance.draw_cave(self, size)
	if Engine.is_editor_hint():
		EditorDraw.label(self, Vector2(0, -size.y / 2.0 - 10.0), "arrival / respawn")


# same spot they step out at when a level starts
func get_respawn_position(yeti: Yeti) -> Vector2:
	var side := -1.0 if yeti.player_id == 1 else 1.0
	return global_position + Vector2(side * respawn_spread / 2.0, size.y / 2.0 - yeti._body_extents().y)


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	add_to_group("respawn_points")   # dying sends you back here, see Yeti.die()

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
