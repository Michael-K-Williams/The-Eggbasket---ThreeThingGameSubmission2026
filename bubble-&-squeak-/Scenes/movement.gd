extends CharacterBody2D

@export var player_id: int = 1

@export var move_speed: float = 300.0
@export var acceleration: float = 2000.0
@export var friction: float = 2500.0

@export var jump_velocity: float = -550.0
@export var jump_cut_factor: float = 0.5

@export var coyote_time: float = 0.1
@export var jump_buffer_time: float = 0.1

@onready var _grab_zone: Area2D = $GrabZone

var _act_left: StringName
var _act_right: StringName
var _act_jump: StringName
var _act_grab: StringName

var _gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity", 980.0)

var _coyote_timer: float = 0.0
var _jump_buffer_timer: float = 0.0

var _grabbed_cube: PushableCube = null


func _ready() -> void:
	var prefix := "p%d_" % player_id
	_act_left = StringName(prefix + "left")
	_act_right = StringName(prefix + "right")
	_act_jump = StringName(prefix + "jump")
	_act_grab = StringName(prefix + "grab")


func _physics_process(delta: float) -> void:
	_apply_gravity(delta)
	_handle_grab()
	_handle_horizontal(delta)
	_handle_jump(delta)
	move_and_slide()


func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += _gravity * delta


func _handle_grab() -> void:
	if _grabbed_cube != null and _grabbed_cube.grabbed_by != self:
		_grabbed_cube = null

	if _grabbed_cube != null:
		if not Input.is_action_pressed(_act_grab) or not is_on_floor():
			_grabbed_cube.release(self)
			_grabbed_cube = null
		return


	if Input.is_action_just_pressed(_act_grab) and is_on_floor():
		var closest: PushableCube = null
		var closest_dist := INF
		for body in _grab_zone.get_overlapping_bodies():
			var cube := body as PushableCube
			if cube == null or not cube.is_grabbable_by(self):
				continue
			var dist := absf(cube.global_position.x - global_position.x)
			if dist < closest_dist:
				closest = cube
				closest_dist = dist
		if closest != null and closest.try_grab(self):
			_grabbed_cube = closest


func _handle_horizontal(delta: float) -> void:
	var direction := Input.get_axis(_act_left, _act_right)
	var speed := move_speed if _grabbed_cube == null else _grabbed_cube.grab_speed
	if direction != 0.0:
		velocity.x = move_toward(velocity.x, direction * speed, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)


func _handle_jump(delta: float) -> void:
	if is_on_floor():
		_coyote_timer = coyote_time
	else:
		_coyote_timer -= delta

	if Input.is_action_just_pressed(_act_jump):
		_jump_buffer_timer = jump_buffer_time
	else:
		_jump_buffer_timer -= delta

	# no jumping while holding a cube (jump = let go instead, if you prefer, see below)
	if _grabbed_cube == null and _jump_buffer_timer > 0.0 and _coyote_timer > 0.0:
		velocity.y = jump_velocity
		_jump_buffer_timer = 0.0
		_coyote_timer = 0.0

	if Input.is_action_just_released(_act_jump) and velocity.y < 0.0:
		velocity.y *= jump_cut_factor
