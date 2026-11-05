class_name Yeti
extends CharacterBody2D

enum Ability { BUBBLE, WIND }

@export var player_id: int = 1
var ability: Ability
var _bubble: Bubble = null
@export var ability_cooldown: float = 0.5

@export var move_speed: float = 300.0
@export var acceleration: float = 2000.0
@export var friction: float = 2500.0

@export var jump_velocity: float = -550.0
@export var jump_cut_factor: float = 0.5

@export var coyote_time: float = 0.1
@export var jump_buffer_time: float = 0.1

@export_group("Wind")
@export var normal_wind_response: float = 0.35  

@export_group("Bubbled")
@export var bubble_duration: float = 8.0         
@export var bubble_gravity_scale: float = 0.25
@export var bubble_max_fall_speed: float = 70.0
@export var bubble_max_rise_speed: float = 300.0
@export var bubble_wind_response: float = 1.5    
@export var bubble_move_speed_mult: float = 0.7
@export var bubble_acceleration: float = 500.0
@export var bubble_friction: float = 120.0      
@export var bubble_jump_mult: float = 0.5
@export var push_transfer: float = 1.0    

@export_group("Props")
@export var throw_up_ratio: float = 1.0       # arc height: 1.0 = 45 degrees
@export var pickup_range: float = 120.0

@export var throw_inherit_velocity: float = 0.5   # how much of your own speed adds to the throw

var _act_interact: StringName
var _held_prop: Prop = null       

@onready var _grab_zone: Area2D = $GrabZone
@onready var _body_shape: CollisionShape2D = $CollisionShape2D

var is_bubbled := false

var _act_left: StringName
var _act_right: StringName
var _act_jump: StringName
var _act_grab: StringName
var _act_ability: StringName

var _gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity", 980.0)

var _coyote_timer: float = 0.0
var _jump_buffer_timer: float = 0.0
var _ability_timer: float = 0.0
var _bubble_timer: float = 0.0
var _facing: float = 1.0
var _wind_accel := Vector2.ZERO

var _grabbed_cube: PushableCube = null
var _bubble_visual: BubbleVisual
var _fan: Fan = null


func _ready() -> void:
	var prefix := "p%d_" % player_id
	_act_left = StringName(prefix + "left")
	_act_right = StringName(prefix + "right")
	_act_jump = StringName(prefix + "jump")
	_act_grab = StringName(prefix + "grab")
	_act_ability = StringName(prefix + "ability")
	_act_interact = StringName(prefix + "interact")
	ability = Ability.BUBBLE if player_id == 1 else Ability.WIND

	_bubble_visual = BubbleVisual.new()
	_bubble_visual.radius = _bubble_radius()
	_bubble_visual.visible = false
	_bubble_visual.z_index = 1
	add_child(_bubble_visual)


func _physics_process(delta: float) -> void:
	_tick_bubble(delta)
	_apply_gravity(delta)
	_apply_wind(delta)
	_handle_grab()
	_handle_props()      
	_handle_horizontal(delta)
	_handle_jump(delta)
	_handle_ability(delta)

	if is_bubbled:
		velocity.y = clampf(velocity.y, -bubble_max_rise_speed, bubble_max_fall_speed)

	var intended_velocity := velocity
	move_and_slide()
	_push_bubbled_players(intended_velocity)
	_update_held_prop()    


# ---------- helpers ----------

func _body_extents() -> Vector2:
	var s := _body_shape.shape
	var capsule := s as CapsuleShape2D
	if capsule:
		return Vector2(capsule.radius, capsule.height / 2.0)
	var rect := s as RectangleShape2D
	if rect:
		return rect.size / 2.0
	var circle := s as CircleShape2D
	if circle:
		return Vector2(circle.radius, circle.radius)
	return Vector2(16.0, 16.0)


func _bubble_radius() -> float:

	return _body_extents().length() * 1.1


# ---------- bubbled state ----------

func set_bubbled(value: bool) -> void:
	is_bubbled = value
	_bubble_visual.visible = value
	_bubble_timer = bubble_duration
	if value and _grabbed_cube != null:
		if value and _held_prop != null:
			_held_prop.call_deferred("throw", Vector2.ZERO)
		_held_prop = null
		_grabbed_cube.release(self)
		_grabbed_cube = null


func _tick_bubble(delta: float) -> void:
	if not is_bubbled or bubble_duration <= 0.0:
		return
	_bubble_timer -= delta
	if _bubble_timer <= 0.0:
		set_bubbled(false)



func receive_push(push_velocity: Vector2) -> void:
	velocity.x = push_velocity.x


func _push_bubbled_players(intended_velocity: Vector2) -> void:
	for i in get_slide_collision_count():
		var collision := get_slide_collision(i)
		var other := collision.get_collider() as Yeti
		if other == null or not other.is_bubbled:
			continue
		var push_dir := -collision.get_normal()
		if absf(push_dir.x) < 0.5:
			continue  
		var amount := intended_velocity.dot(push_dir)
		if amount > 0.0:
			other.receive_push(push_dir * amount * push_transfer)


# ---------- wind ----------


func apply_wind(direction: Vector2, strength: float) -> void:
	var response := bubble_wind_response if is_bubbled else normal_wind_response
	_wind_accel += direction * strength * response


func _apply_wind(delta: float) -> void:
	var accel := _wind_accel
	_wind_accel = Vector2.ZERO
	if accel == Vector2.ZERO:
		return
	
	if not is_bubbled and is_on_floor() and accel.y < 0.0 and -accel.y < _gravity:
		accel.y = 0.0
	velocity += accel * delta


# ---------- movement ----------

func _apply_gravity(delta: float) -> void:
	if is_on_floor():
		return
	var scale := bubble_gravity_scale if is_bubbled else 1.0
	velocity.y += _gravity * scale * delta


func _handle_horizontal(delta: float) -> void:
	var direction := Input.get_axis(_act_left, _act_right)
	if direction != 0.0:
		_facing = signf(direction)

	var speed := move_speed
	var accel := acceleration
	var drag := friction
	if _grabbed_cube != null:
		speed = _grabbed_cube.grab_speed
	if is_bubbled:
		speed *= bubble_move_speed_mult
		accel = bubble_acceleration
		drag = bubble_friction

	if direction != 0.0:
		velocity.x = move_toward(velocity.x, direction * speed, accel * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, drag * delta)


func _handle_jump(delta: float) -> void:
	if is_on_floor():
		_coyote_timer = coyote_time
	else:
		_coyote_timer -= delta

	if Input.is_action_just_pressed(_act_jump):
		_jump_buffer_timer = jump_buffer_time
	else:
		_jump_buffer_timer -= delta

	if _grabbed_cube == null and _jump_buffer_timer > 0.0 and _coyote_timer > 0.0:
		velocity.y = jump_velocity * (bubble_jump_mult if is_bubbled else 1.0)
		_jump_buffer_timer = 0.0
		_coyote_timer = 0.0

	if Input.is_action_just_released(_act_jump) and velocity.y < 0.0:
		velocity.y *= jump_cut_factor


# ---------- grab ----------

func _handle_grab() -> void:
	if _grabbed_cube != null and _grabbed_cube.grabbed_by != self:
		_grabbed_cube = null

	if _grabbed_cube != null:
		if not Input.is_action_pressed(_act_grab) or not is_on_floor():
			_grabbed_cube.release(self)
			_grabbed_cube = null
		return

	if  Input.is_action_just_pressed(_act_grab) and is_on_floor() and not is_bubbled and _held_prop == null:
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


# ---------- abilities ----------

func _handle_ability(delta: float) -> void:
	_ability_timer -= delta
	if _ability_timer > 0.0 or not Input.is_action_just_pressed(_act_ability):
		return
	_ability_timer = ability_cooldown

	match ability:
		Ability.BUBBLE:
			_blow_bubble()
		Ability.WIND:
			_place_fan()


func _blow_bubble() -> void:
	if is_instance_valid(_bubble):
		_bubble.queue_free()

	var bubble := Bubble.new()
	bubble.radius = _bubble_radius()
	get_parent().add_child(bubble)
	bubble.global_position = global_position + Vector2(
		_facing * (_body_extents().x + bubble.radius + 4.0), 0.0)
	_bubble = bubble


func _place_fan() -> void:
	if is_instance_valid(_fan):
		_fan.queue_free()  

	var fan := Fan.new()
	fan.starts_stuck = true
	get_parent().add_child(fan)
	var ext := _body_extents()
	fan.global_position = Vector2(
		global_position.x + _facing * (ext.x + fan.fan_size.x / 2.0 + 6.0),
		global_position.y + ext.y - fan.fan_size.y / 2.0)
	_fan = fan

func _handle_props() -> void:
	if Input.is_action_just_pressed(_act_interact):
		print("interact pressed by P", player_id, " held: ", _held_prop, " bubbled: ", is_bubbled, " cube: ", _grabbed_cube)
	if _held_prop != null and (not is_instance_valid(_held_prop)
			or _held_prop.state != Prop.State.HELD or _held_prop.holder != self):
		_held_prop = null

	if not Input.is_action_just_pressed(_act_interact):
		return

	if _held_prop != null:
		_throw_prop()
	elif _grabbed_cube == null and not is_bubbled:
		_try_pick_up_prop()


func _try_pick_up_prop() -> void:
	for node in get_tree().get_nodes_in_group("props"):
		print(node, " distance: ", global_position.distance_to(node.global_position))
	var closest: Prop = null
	var closest_dist := pickup_range
	for node in get_tree().get_nodes_in_group("props"):
		var prop := node as Prop
		if prop == null or prop.state == Prop.State.HELD:
			continue
		var dist := global_position.distance_to(prop.global_position)
		if dist < closest_dist:
			closest = prop
			closest_dist = dist
	if closest != null and closest.pick_up(self):
		_held_prop = closest


func _throw_prop() -> void:
	var dir := Vector2(_facing, -throw_up_ratio).normalized()
	var throw_velocity := dir * _held_prop.throw_speed
	throw_velocity.x += velocity.x * throw_inherit_velocity
	_held_prop.throw(throw_velocity)
	_held_prop = null


func _update_held_prop() -> void:
	if _held_prop == null:
		return
	_held_prop.global_position = global_position + Vector2(_facing * 6.0, -_body_extents().y - 12.0)
