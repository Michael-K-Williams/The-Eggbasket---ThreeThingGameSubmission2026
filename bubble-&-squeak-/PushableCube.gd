class_name PushableCube
extends RigidBody2D

@export var grab_speed: float = 120.0        
@export var stop_deceleration: float = 2000.0  
@export var max_drag_distance: float = 24.0   

var grabbed_by: Node2D = null
var _offset_x: float = 0.0

@export var wind_response: float = 0.5  

func apply_wind(direction: Vector2, strength: float) -> void:
	apply_central_force(direction * strength * wind_response * mass)

func _ready() -> void:
	lock_rotation = true
	continuous_cd = RigidBody2D.CCD_MODE_CAST_RAY
	can_sleep = false


func is_grabbable_by(player: Node2D) -> bool:
	return grabbed_by == null or grabbed_by == player


func try_grab(player: Node2D) -> bool:
	if not is_grabbable_by(player):
		return false  
	grabbed_by = player
	_offset_x = global_position.x - player.global_position.x
	# the holder and the cube ignore each other while grabbed, otherwise pushing
	# deadlocks: the yeti can't shove a rigid body and the cube only follows the yeti
	_set_ignore(player, true)
	return true


func release(player: Node2D) -> void:
	if grabbed_by == player:
		_drop()


func _drop() -> void:
	if grabbed_by != null:
		_set_ignore(grabbed_by, false)
	grabbed_by = null


func _set_ignore(player: Node2D, on: bool) -> void:
	var body := player as PhysicsBody2D
	if body == null:
		return
	if on:
		add_collision_exception_with(body)
		body.add_collision_exception_with(self)
	else:
		remove_collision_exception_with(body)
		body.remove_collision_exception_with(self)


func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	var v := state.linear_velocity

	if grabbed_by != null:
		var target_x := grabbed_by.global_position.x + _offset_x
		var error := target_x - state.transform.origin.x

		if absf(error) > max_drag_distance:
			call_deferred("_drop")   # can't change exceptions mid physics step
			v.x = 0.0
		else:
			v.x = clampf(error / state.step, -grab_speed * 1.5, grab_speed * 1.5)
	
	if grabbed_by == null:
		v.x = move_toward(v.x, 0.0, stop_deceleration * state.step)

	state.linear_velocity = v
