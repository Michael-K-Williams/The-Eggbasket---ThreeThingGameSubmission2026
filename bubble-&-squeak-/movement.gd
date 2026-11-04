extends CharacterBody2D

# One script for both yetis.
# set player_id to 1 or 2 in the inspector and it grabs the right keys

@export var player_id: int = 1

@export var move_speed: float = 300.0
@export var acceleration: float = 2000.0
@export var friction: float = 2500.0

@export var jump_velocity: float = -550.0
# how much of the jump we kill if you let go early. gives you a tap-for-small-hop,
# hold-for-full-jump feel. set to 1.0 to turn it off in testing if you think it's better.
@export var jump_cut_factor: float = 0.5

# little bit of leeway so jumps still feel fair
@export var coyote_time: float = 0.1       # can still jump just after walking off a ledge
@export var jump_buffer_time: float = 0.1  # press jump slightly early and it still fires on landing

# the actual action names get worked out in _ready once we know the player_id
var _act_left: StringName
var _act_right: StringName
var _act_jump: StringName

# pull gravity straight from the project settings so everything falls the same
var _gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity", 980.0)

var _coyote_timer: float = 0.0
var _jump_buffer_timer: float = 0.0


func _ready() -> void:
	# build "p1_" or "p2_" and stick it on the front of each action
	var prefix := "p%d_" % player_id
	_act_left = StringName(prefix + "left")
	_act_right = StringName(prefix + "right")
	_act_jump = StringName(prefix + "jump")


func _physics_process(delta: float) -> void:
	_apply_gravity(delta)
	_handle_horizontal(delta)
	_handle_jump(delta)
	move_and_slide()


func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += _gravity * delta


func _handle_horizontal(delta: float) -> void:
	# get_axis gives us -1 / 0 / 1 for left, nothing, right
	var direction := Input.get_axis(_act_left, _act_right)
	if direction != 0.0:
		# ease up to full speed rather than snapping, feels less robotic
		velocity.x = move_toward(velocity.x, direction * move_speed, acceleration * delta)
	else:
		# nothing held, drag back down to a stop
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)


func _handle_jump(delta: float) -> void:
	# on the ground = top the coyote timer back up, otherwise let it tick down
	if is_on_floor():
		_coyote_timer = coyote_time
	else:
		_coyote_timer -= delta

	# remember a jump press for a fraction of a second
	if Input.is_action_just_pressed(_act_jump):
		_jump_buffer_timer = jump_buffer_time
	else:
		_jump_buffer_timer -= delta

	# got a recent press AND we're allowed to jump? go
	if _jump_buffer_timer > 0.0 and _coyote_timer > 0.0:
		velocity.y = jump_velocity
		_jump_buffer_timer = 0.0
		_coyote_timer = 0.0

	# let go on the way up and we chop the jump short
	if Input.is_action_just_released(_act_jump) and velocity.y < 0.0:
		velocity.y *= jump_cut_factor
