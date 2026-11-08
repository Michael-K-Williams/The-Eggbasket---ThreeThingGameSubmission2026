class_name Bubble
extends Area2D

@export var radius: float = 30.0
@export_flags_2d_physics var player_mask: int = 2 | 16
@export_flags_2d_physics var bubble_layer: int = 8
@export var lifetime: float = 10.0
@export var wind_response: float = 1.5
@export var drag: float = 0.0
@export var max_speed: float = 0.0
@export var time_can_enter: float = 0.5   
@export var owner_grace: float = 0.25     
var owner_yeti: Yeti = null

@export_group("Blowing")
@export var grow_time: float = 0.6
@export var spin_turns: float = 0.5       
@export var bob_height: float = 3.0
@export var bob_speed: float = 1.2        

var velocity := Vector2.ZERO
var _wind_accel := Vector2.ZERO
var _age := 0.0

var _from := Vector2.ZERO
var _to := Vector2.ZERO
var _launched := false
var _started := false
var _grow_t := 0.0
var _shape: CircleShape2D
var _visual: BubbleVisual





func launch(mouth: Vector2, rest: Vector2) -> void:
	_from = mouth
	_to = rest
	_launched = true
	global_position = mouth


func _ready() -> void:
	collision_layer = bubble_layer
	collision_mask = player_mask

	_shape = CircleShape2D.new()
	_shape.radius = 1.0
	var cs := CollisionShape2D.new()
	cs.shape = _shape
	add_child(cs)

	_visual = BubbleVisual.new()
	_visual.radius = radius
	_visual.scale = Vector2.ONE * 0.05
	add_child(_visual)


func _touch(yeti: Yeti) -> void:
	if yeti.is_bubbled or yeti.in_cave:
		return
	var is_owner := yeti == owner_yeti
	if is_owner and _age < owner_grace:
		return
	if not is_owner and _age >= grow_time + time_can_enter:
		if yeti.position.y < position.y:
			yeti.velocity.y = yeti.jump_velocity
		queue_free()
		return
	if yeti.was_in_bubble:
		return
	yeti.set_bubbled(true)
	queue_free()


func apply_wind(direction: Vector2, strength: float) -> void:
	_wind_accel += direction * strength * wind_response


func _physics_process(delta: float) -> void:
	_age += delta

	if not _started:
		_started = true
		if not _launched:
			_from = global_position
			_to = global_position

	var growing := _grow_t < 1.0
	if growing:
		_grow_t = minf(_grow_t + delta / grow_time, 1.0)
		var e := 1.0 - pow(1.0 - _grow_t, 3.0)  
		global_position = _from.lerp(_to, e)
		_shape.radius = maxf(radius * e, 1.0)
		_visual.scale = Vector2.ONE * maxf(e, 0.05)
		_visual.rotation = spin_turns * TAU * (1.0 - e)
	else:
		_visual.rotation = 0.0
		var t := _age - grow_time
		_visual.bob_offset = Vector2(0.0, sin(t * bob_speed * TAU) * bob_height)

	for body in get_overlapping_bodies():
		var prop := body as Prop
		if prop != null:
			if _grow_t >= 0.5 and prop.state == Prop.State.FREE and not prop.is_bubbled:
				prop.set_bubbled(true)
				queue_free()
				return
			continue
		var yeti := body as Yeti
		if yeti != null:
			_touch(yeti)
			if is_queued_for_deletion():
				return
	if lifetime > 0.0 and _age >= lifetime:
		queue_free()
		return

	if growing:
		_wind_accel = Vector2.ZERO   
		return
	velocity += _wind_accel * delta
	_wind_accel = Vector2.ZERO
	velocity = velocity.move_toward(Vector2.ZERO, drag * delta).limit_length(max_speed)
	position += velocity * delta
