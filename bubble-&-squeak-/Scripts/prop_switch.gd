@tool
class_name PropSwitch
extends StaticBody2D

signal pressed
signal released

@export var doors: Array[Door] = []            
@export var size := Vector2(32, 14):
	set(v):
		size = v
		queue_redraw()
@export var hold_time: float = 0.0             
@export var require_thrown: bool = true        
@export var catch_margin: float = 14.0        
@export var idle_color := Color(0.85, 0.3, 0.3)
@export var active_color := Color(0.35, 0.9, 0.45)

var is_pressed := false

var _area: Area2D
var _timer := 0.0
var _press_amount := 0.0   


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	collision_layer = 1  
	collision_mask = 0

	var rect := RectangleShape2D.new()
	rect.size = size
	var cs := CollisionShape2D.new()
	cs.shape = rect
	add_child(cs)

	
	_area = Area2D.new()
	_area.collision_layer = 0
	_area.collision_mask = 16
	_area.monitorable = false
	var area_shape := RectangleShape2D.new()
	area_shape.size = size + Vector2.ONE * catch_margin * 2.0
	var acs := CollisionShape2D.new()
	acs.shape = area_shape
	_area.add_child(acs)
	add_child(_area)


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return

	
	var hit := false
	for body in _area.get_overlapping_bodies():
		var prop := body as Prop
		if prop == null:
			continue
		if require_thrown and not prop.is_flying():
			continue
		hit = true
		break

	if hit:
		if not is_pressed:
			_press()
		_timer = hold_time  
	elif is_pressed and hold_time > 0.0:
		_timer -= delta
		if _timer <= 0.0:
			_release()


	var target := 1.0 if is_pressed else 0.0
	if _press_amount != target:
		_press_amount = move_toward(_press_amount, target, delta * 8.0)
		queue_redraw()


func _press() -> void:
	is_pressed = true
	for d in doors:
		if is_instance_valid(d):
			d.plate_pressed(self)
	pressed.emit()


func _release() -> void:
	is_pressed = false
	for d in doors:
		if is_instance_valid(d):
			d.plate_released(self)
	released.emit()


func _draw() -> void:
	var half := size / 2.0
	var base := Rect2(-half, size)
	draw_rect(base, Color(0.25, 0.22, 0.3))
	draw_rect(base, Color(0.12, 0.1, 0.15), false, 2.0)


	var cap_h := 6.0 * (1.0 - _press_amount * 0.7)
	var col := idle_color.lerp(active_color, _press_amount)
	var cap := Rect2(-half.x + 4.0, -half.y - cap_h, size.x - 8.0, cap_h)
	draw_rect(cap, col)
	draw_rect(cap, col.darkened(0.5), false, 1.5)
