@tool
class_name WindVent
extends StaticBody2D

signal started  
signal stopped   

const WIND_GAP := 0.1   

@export var doors: Array[Door] = []
@export var size := Vector2(40, 40):
	set(v):
		size = v
		queue_redraw()
@export var release_delay: float = 1.0     
@export var spin_up_time: float = 0.5      
@export var spin_down_time: float = 1.2   
@export var face_into_wind: bool = false    
@export_range(10.0, 90.0) var max_angle_deg: float = 60.0
@export var sense_margin: float = 6.0      
@export var housing_color := Color(0.28, 0.3, 0.38)
@export var blade_color := Color(0.75, 0.85, 0.95)

var is_on := false

var _sensor: Area2D
var _since_wind := 999.0
var _spin := 0.0         
var _blade_angle := 0.0



class _Sensor extends Area2D:
	var vent: WindVent

	func apply_wind(direction: Vector2, _strength: float) -> void:
		if vent != null:
			vent._receive_wind(direction)

	func wind_ceiling(_top_y: float) -> void:
		pass   


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


	_sensor = _Sensor.new()
	_sensor.vent = self
	_sensor.collision_layer = 8
	_sensor.collision_mask = 0
	_sensor.monitoring = false
	_sensor.monitorable = true
	var area_shape := RectangleShape2D.new()
	area_shape.size = size + Vector2.ONE * sense_margin * 2.0
	var acs := CollisionShape2D.new()
	acs.shape = area_shape
	_sensor.add_child(acs)
	add_child(_sensor)



func _receive_wind(direction: Vector2) -> void:
	print("vent got wind ", direction)
	if face_into_wind:
		var intake := Vector2.UP.rotated(global_rotation)  
		if direction.normalized().dot(-intake) < cos(deg_to_rad(max_angle_deg)):
			return
	_since_wind = 0.0


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_scan_zones()

	_since_wind += delta
	var windy := _since_wind < WIND_GAP

	var time := spin_up_time if windy else spin_down_time
	_spin = move_toward(_spin, 1.0 if windy else 0.0, delta / maxf(time, 0.01))

	if not is_on and windy and _spin >= 0.6:
		_turn_on()
	elif is_on and _since_wind >= maxf(release_delay, WIND_GAP):
		_turn_off()

	if _spin > 0.0:
		_blade_angle = wrapf(_blade_angle + _spin * 14.0 * delta, 0.0, TAU)
		queue_redraw()


func _turn_on() -> void:
	is_on = true
	for d in doors:
		if is_instance_valid(d):
			d.plate_pressed(self)
	started.emit()
	queue_redraw()


func _turn_off() -> void:
	is_on = false
	for d in doors:
		if is_instance_valid(d):
			d.plate_released(self)
	stopped.emit()
	queue_redraw()


func _draw() -> void:
	var half := size / 2.0
	var box := Rect2(-half, size)
	draw_rect(box, housing_color)
	draw_rect(box, housing_color.darkened(0.55), false, 2.0)

	# round intake with spinning blades
	var r := minf(half.x, half.y) * 0.72
	draw_circle(Vector2.ZERO, r, Color(0.08, 0.09, 0.12))
	for i in 4:
		var tip := Vector2.RIGHT.rotated(_blade_angle + i * PI / 2.0) * (r - 2.0)
		draw_line(Vector2.ZERO, tip, blade_color, 4.0, true)
	draw_circle(Vector2.ZERO, 4.0, housing_color.lightened(0.2))
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 28, housing_color.darkened(0.55), 2.0, true)

	# status lamp: red = idle, amber = spinning up, green = doors open
	var lamp := Color(0.85, 0.2, 0.2).lerp(Color(1.0, 0.75, 0.2), _spin)
	if is_on:
		lamp = Color(0.35, 0.95, 0.5)
	draw_circle(Vector2(half.x - 6.0, -half.y + 6.0), 3.5, lamp)
	
	
func _scan_zones() -> void:
	for node in get_tree().get_nodes_in_group("wind_zones"):
		var zone := node as WindZone
		if zone == null or not zone.is_physics_processing() or not zone.is_visible_in_tree():
			continue
		# our centre in the zone's own space, so rotation and scale are handled
		var local := zone.to_local(global_position)
		var half := zone.size / 2.0 + size / 2.0 + Vector2.ONE * sense_margin
		if absf(local.x) <= half.x and absf(local.y) <= half.y:
			_receive_wind(Vector2.UP.rotated(zone.global_rotation))
