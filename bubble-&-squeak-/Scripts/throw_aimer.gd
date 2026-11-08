class_name ThrowAimer
extends Node2D

signal finished(direction: Vector2, power: float)

enum Phase { IDLE, ANGLE, POWER }

@export var min_angle_deg: float = -20.0   # slightly downward
@export var max_angle_deg: float = 80.0    # nearly straight up
@export var angle_speed: float = 3.0       # how fast the arrow sweeps
@export var power_speed: float = 3.5       # how fast the meter fills and empties
@export var min_power: float = 1        # weakest throw, as a fraction of the prop's throw_speed
@export var arrow_min: float = 22.0
@export var arrow_max: float = 64.0

var phase := Phase.IDLE
var active: bool:
	get:
		return phase != Phase.IDLE

var _facing := 1.0
var _t := 0.0
var _angle := 0.0   # radians above horizontal
var _power := 0.0


func begin(facing: float) -> void:
	_facing = facing
	_t = 0.0
	_power = 0.0
	_angle = deg_to_rad(min_angle_deg)
	phase = Phase.ANGLE
	queue_redraw()


# press 2 locks the angle, press 3 throws
func confirm() -> void:
	match phase:
		Phase.ANGLE:
			phase = Phase.POWER
			_t = 0.0
		Phase.POWER:
			var dir := _direction()
			var p := lerpf(min_power, 1.0, _power)
			phase = Phase.IDLE
			queue_redraw()
			finished.emit(dir, p)


func cancel() -> void:
	phase = Phase.IDLE
	queue_redraw()


func _direction() -> Vector2:
	return Vector2(_facing * cos(_angle), -sin(_angle))


func _process(delta: float) -> void:
	if phase == Phase.IDLE:
		return
	_t += delta
	match phase:
		Phase.ANGLE:
			var wave := 0.5 - 0.5 * cos(_t * angle_speed)  
			_angle = deg_to_rad(lerpf(min_angle_deg, max_angle_deg, wave))
		Phase.POWER:
			_power = 0.5 - 0.5 * cos(_t * power_speed)
	queue_redraw()


func _draw() -> void:
	if phase == Phase.IDLE:
		return
		
	var pts := PackedVector2Array()
	for i in 17:
		var a := lerpf(deg_to_rad(min_angle_deg), deg_to_rad(max_angle_deg), i / 16.0)
		pts.append(Vector2(_facing * cos(a), -sin(a)) * arrow_max)
	draw_polyline(pts, Color(1, 1, 1, 0.25), 2.0, true)

	var dir := _direction()
	var length := arrow_max * 0.75
	var col: Color = UiStyle.ACCENT
	if phase == Phase.POWER:
		length = lerpf(arrow_min, arrow_max, _power)
		col = Color(0.4, 1.0, 0.5).lerp(Color(1.0, 0.35, 0.25), _power)

	var tip := dir * length
	var side := dir.orthogonal()
	draw_line(dir * 8.0, tip, col, 3.0, true)
	draw_colored_polygon(PackedVector2Array([
		tip + dir * 8.0, tip - dir * 2.0 + side * 5.0, tip - dir * 2.0 - side * 5.0]), col)

	# power bar above the prop
	if phase == Phase.POWER:
		var bar := Rect2(-24.0, -34.0, 48.0, 7.0)
		draw_rect(bar, Color(0.05, 0.07, 0.1, 0.8))
		draw_rect(Rect2(bar.position, Vector2(bar.size.x * _power, bar.size.y)), col)
		draw_rect(bar, Color(1, 1, 1, 0.6), false, 1.0)
