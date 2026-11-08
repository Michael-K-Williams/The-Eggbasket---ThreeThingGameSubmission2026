@tool
class_name LockedDoor
extends Door

@export var key_margin: float = 16.0  
@export var lock_color := Color(1.0, 0.82, 0.25)

var locked := true
var _area: Area2D


func _ready() -> void:
	super()
	if Engine.is_editor_hint():
		return
	stays_open = true    
	plates_needed = 1

	
	_area = Area2D.new()
	_area.collision_layer = 0
	_area.collision_mask = 16
	_area.monitorable = false
	var shape := RectangleShape2D.new()
	shape.size = size + Vector2.ONE * key_margin * 2.0
	var cs := CollisionShape2D.new()
	cs.shape = shape
	_area.add_child(cs)
	add_child(_area)


func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint() or not locked:
		return
	for body in _area.get_overlapping_bodies():
		var key := body as DoorKey
		
		if key != null and key.is_flying():
			_unlock(key)
			return


func _unlock(key: DoorKey) -> void:
	locked = false   
	var t := key.use_on(global_position)
	await t.finished
	if is_instance_valid(key):
		key.queue_free()
	queue_redraw()   
	plate_pressed(self)  


func _draw() -> void:
	super()
	if not locked:
		return
	var dark := Color(0.15, 0.12, 0.18)
	draw_arc(Vector2(0, -6), 7.0, PI, TAU, 16, lock_color, 3.0, true)   
	draw_rect(Rect2(-10, -6, 20, 16), lock_color)                        
	draw_circle(Vector2(0, 1), 2.5, dark)                              
	draw_rect(Rect2(-1, 1, 2, 5), dark)
