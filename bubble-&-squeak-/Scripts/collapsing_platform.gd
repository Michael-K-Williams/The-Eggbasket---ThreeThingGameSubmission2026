@tool
class_name CollapsingPlatform
extends StaticBody2D

enum State { SOLID, FALLEN }

@export var size := Vector2(96, 16):
	set(v):
		size = v
		queue_redraw()
@export var stand_time: float = 2.0       
@export var respawn_delay: float = 3.0    
@export var recover_rate: float = 1.0     
@export var one_way: bool = false        
@export var fall_distance: float = 60.0
@export var max_shake: float = 2.0        
@export_flags_2d_physics var trigger_mask: int = 2 | 4   
@export var color := Color(0.45, 0.4, 0.5)

var state := State.SOLID

var _progress := 0.0
var _respawn_timer := 0.0
var _shape: CollisionShape2D
var _area: Area2D
var _draw_offset := Vector2.ZERO
var _tween: Tween


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	collision_layer = 2   
	collision_mask = 0

	_shape = CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	_shape.shape = rect
	_shape.one_way_collision = one_way
	add_child(_shape)

	
	_area = Area2D.new()
	_area.collision_layer = 0
	_area.collision_mask = trigger_mask
	_area.monitorable = false
	var area_shape := RectangleShape2D.new()
	area_shape.size = Vector2(size.x - 2.0, size.y + 10.0)
	var acs := CollisionShape2D.new()
	acs.shape = area_shape
	acs.position = Vector2(0.0, -5.0)
	_area.add_child(acs)
	add_child(_area)


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return

	match state:
		State.SOLID:
			if _someone_standing():
				_progress += delta
			elif recover_rate > 0.0:
				_progress = maxf(0.0, _progress - delta * recover_rate)

		
			var t := clampf(_progress / stand_time, 0.0, 1.0)
			if t > 0.0:
				var amp := max_shake * t
				_draw_offset = Vector2(roundf(randf_range(-amp, amp)), 0.0)
			else:
				_draw_offset = Vector2.ZERO
			queue_redraw()

			if _progress >= stand_time:
				_collapse()

		State.FALLEN:
			_respawn_timer -= delta
			if _respawn_timer <= 0.0 and _area.get_overlapping_bodies().is_empty():
				_reform()


func _someone_standing() -> bool:
	for body in _area.get_overlapping_bodies():
		
		if body.global_position.y < global_position.y:
			return true
	return false


func _collapse() -> void:
	state = State.FALLEN
	_respawn_timer = respawn_delay
	_progress = 0.0
	_shape.set_deferred("disabled", true)

	if _tween:
		_tween.kill()
	_draw_offset = Vector2.ZERO
	_tween = create_tween().set_parallel(true)
	_tween.tween_method(_set_fall, 0.0, fall_distance, 0.6).set_ease(Tween.EASE_IN)
	_tween.tween_property(self, "modulate:a", 0.0, 0.6)


func _reform() -> void:
	state = State.SOLID
	_progress = 0.0
	_shape.set_deferred("disabled", false)

	if _tween:
		_tween.kill()
	_draw_offset = Vector2.ZERO
	queue_redraw()
	_tween = create_tween()
	_tween.tween_property(self, "modulate:a", 1.0, 0.35)


func _set_fall(y: float) -> void:
	_draw_offset = Vector2(0.0, y)
	queue_redraw()


func _draw() -> void:
	draw_set_transform(_draw_offset)
	var rect := Rect2(-size / 2.0, size)
	draw_rect(rect, color)
	draw_rect(rect, color.darkened(0.5), false, 2.0)

	
	if not Engine.is_editor_hint() and state == State.SOLID and stand_time > 0.0:
		var t := clampf(_progress / stand_time, 0.0, 1.0)
		var crack := color.darkened(0.7)
		if t > 0.2:
			draw_line(Vector2(-size.x * 0.2, -size.y / 2.0), Vector2(-size.x * 0.12, size.y / 2.0), crack, 2.0)
		if t > 0.5:
			draw_line(Vector2(size.x * 0.15, -size.y / 2.0), Vector2(size.x * 0.25, size.y / 2.0), crack, 2.0)
		if t > 0.8:
			draw_line(Vector2(0.0, -size.y / 2.0), Vector2(size.x * 0.05, size.y / 2.0), crack, 2.0)
