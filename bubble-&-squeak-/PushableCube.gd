class_name PushableCube
extends RigidBody2D

@export var grab_speed: float = 120.0        
@export var stop_deceleration: float = 2000.0  
@export var max_drag_distance: float = 24.0   

var grabbed_by: Node2D = null
var _offset_x: float = 0.0


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
	return true


func release(player: Node2D) -> void:
	if grabbed_by == player:
		grabbed_by = null


func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	var v := state.linear_velocity

	if grabbed_by != null:
		var target_x := grabbed_by.global_position.x + _offset_x
		var error := target_x - state.transform.origin.x

		if absf(error) > max_drag_distance:
			grabbed_by = null
		else:
			v.x = clampf(error / state.step, -grab_speed * 1.5, grab_speed * 1.5)
	
	if grabbed_by == null:
		v.x = move_toward(v.x, 0.0, stop_deceleration * state.step)

	state.linear_velocity = v
