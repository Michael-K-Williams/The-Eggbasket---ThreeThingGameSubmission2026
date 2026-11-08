class_name Prop
extends RigidBody2D

enum State { FREE, HELD, STUCK }

const LAYER_WORLD := 1
const LAYER_CUBE := 4
const LAYER_PROP := 16
const FLAT_THRESHOLD := 0.95   

@export var throw_speed: float = 600.0
@export_range(0.0, 1.0) var bounciness: float = 0.3  
@export var wind_response: float = 0.0
@export var sticks_to_walls: bool = false
@export var stick_depth: float = 0.0      
@export var starts_stuck: bool = false    
@export var bubble_throw_carry: float = 0.4   
var _free_fly_time := 0.0

@export_group("Trail")
@export var trail_color := Color(1, 1, 1, 0.5)
@export var trail_width: float = 5.0
@export var trail_length: int = 14

@export_group("Bubble")
@export var bubble_duration: float = 8.0        
@export var bubble_gravity_scale: float = 0.2
@export var bubble_damp: float = 1.2            
@export var bubble_wind_response: float = 1.6   
@export var bubble_max_rise_speed: float = 260.0
@export var bubble_max_fall_speed: float = 60.0
@export var players_push_bubbled: bool = true

var is_bubbled := false
var _bubble_timer := 0.0
var _bubble_visual: BubbleVisual

var state: State = State.FREE
var holder: Node2D = null

var _thrown := false
var _release_grace := 0.0
var _stick_queued := false
var _trail: Line2D


# ---------- overridden by subclasses ----------

func _make_shape() -> Shape2D:
	return null

func _build_extras() -> void:
	pass

func _on_state_changed(_new_state: State) -> void:
	pass


# ---------- setup ----------

func _ready() -> void:
	add_to_group("props")
	lock_rotation = true
	freeze_mode = RigidBody2D.FREEZE_MODE_KINEMATIC
	continuous_cd = RigidBody2D.CCD_MODE_CAST_RAY
	contact_monitor = true
	max_contacts_reported = 4

	var cs := CollisionShape2D.new()
	cs.shape = _make_shape()
	add_child(cs)

	# heavier props bounce less
	var mat := PhysicsMaterial.new()
	mat.bounce = clampf(bounciness / mass, 0.0, 0.85)
	mat.friction = 0.6
	physics_material_override = mat

	_trail = Line2D.new()
	_trail.top_level = true  
	_trail.width = trail_width
	_trail.z_index = -1
	var g := Gradient.new()
	g.set_color(0, Color(trail_color, 0.0))
	g.set_color(1, trail_color)
	_trail.gradient = g
	add_child(_trail)

	_build_extras()
	_set_state(State.STUCK if starts_stuck else State.FREE)
	
func is_flying() -> bool:
	return _thrown and state == State.FREE


# ---------- state ----------

func _set_state(new_state: State) -> void:
	state = new_state
	match state:
		State.FREE:
			freeze = false
			collision_layer = LAYER_PROP
			collision_mask = _free_mask()
		State.HELD, State.STUCK:
			freeze = true
			collision_layer = 0
			collision_mask = 0
			_thrown = false
	_on_state_changed(state)


func pick_up(new_holder: Node2D) -> bool:
	if state == State.HELD:
		set_bubbled(false)
		return false
	holder = new_holder
	linear_velocity = Vector2.ZERO
	rotation = 0.0
	_trail.clear_points()
	_set_state(State.HELD)
	return true


func throw(throw_velocity: Vector2) -> void:
	holder = null
	_set_state(State.FREE)
	linear_velocity = throw_velocity
	_thrown = true
	_release_grace = 0.08
	_free_fly_time = bubble_throw_carry if is_bubbled else 0.0


func apply_wind(direction: Vector2, strength: float) -> void:
	if state != State.FREE:
		return
	var response := bubble_wind_response if is_bubbled else wind_response
	apply_central_force(direction * strength * response * mass)


# ---------- sticking ----------

func _integrate_forces(physics_state: PhysicsDirectBodyState2D) -> void:
	if is_bubbled and _free_fly_time <= 0.0:
		var v := physics_state.linear_velocity
		var target_y := clampf(v.y, -bubble_max_rise_speed, bubble_max_fall_speed)
		v.y = move_toward(v.y, target_y, 1500.0 * physics_state.step)
		physics_state.linear_velocity = v
	if state != State.FREE or not sticks_to_walls or _release_grace > 0.0 or _stick_queued:
		return

	for i in physics_state.get_contact_count():
		var collider := physics_state.get_contact_collider_object(i)
	
		if collider == null or collider is RigidBody2D:
			continue

		var point := physics_state.get_contact_local_position(i)
		var n := physics_state.get_contact_local_normal(i)
	
		if n.dot(physics_state.transform.origin - point) < 0.0:
			n = -n

		
		if maxf(absf(n.x), absf(n.y)) < FLAT_THRESHOLD:
			continue
		n = Vector2(signf(n.x), 0.0) if absf(n.x) > absf(n.y) else Vector2(0.0, signf(n.y))

		_stick_queued = true
		call_deferred("_stick", point, n) 
		return


func _stick(point: Vector2, normal: Vector2) -> void:
	_stick_queued = false
	if state != State.FREE or is_bubbled:
		return
	linear_velocity = Vector2.ZERO
	_set_state(State.STUCK)
	
	rotation = Vector2.UP.angle_to(normal)
	global_position = point + normal * stick_depth


# ---------- per frame ----------

func _physics_process(delta: float) -> void:
	_free_fly_time -= delta
	_update_bubble_physics()
	_tick_bubble(delta)
	_release_grace -= delta
	if _thrown and state == State.FREE and linear_velocity.length() < 60.0:
		_thrown = false  
	_update_trail()


func _update_trail() -> void:
	var flying := _thrown and state == State.FREE
	if flying:
		_trail.add_point(global_position)
	
	var count := _trail.get_point_count()
	if count > 0 and (not flying or count > trail_length):
		_trail.remove_point(0)
		
		
		
func set_bubbled(value: bool) -> void:
	if value == is_bubbled:
		return
	if value and state != State.FREE:
		return  
	is_bubbled = value
	_bubble_timer = bubble_duration
	_thrown = false
	gravity_scale = bubble_gravity_scale if value else 1.0
	linear_damp = bubble_damp if value else 0.0
	sleeping = false
	if state == State.FREE:
		collision_mask = _free_mask()

	if value:
		if _bubble_visual == null:
			_bubble_visual = BubbleVisual.new()
			_bubble_visual.radius = _bubble_radius()
			_bubble_visual.z_index = 1
			add_child(_bubble_visual)
		_bubble_visual.shake = 0.0
		_bubble_visual.visible = true
	elif _bubble_visual != null:
		_bubble_visual.visible = false


func _free_mask() -> int:
	var m := LAYER_WORLD | LAYER_CUBE
	if is_bubbled and players_push_bubbled:
		m |= 2   
	return m


func _bubble_radius() -> float:
	var s := _make_shape()
	if s is CircleShape2D:
		return (s as CircleShape2D).radius + 8.0
	if s is RectangleShape2D:
		return (s as RectangleShape2D).size.length() / 2.0 + 6.0
	return 20.0


func _tick_bubble(delta: float) -> void:
	if not is_bubbled or bubble_duration <= 0.0 or state != State.FREE:
		return
	_bubble_timer -= delta
	_bubble_visual.shake = clampf((2.0 - _bubble_timer) / 2.0, 0.0, 1.0)
	if _bubble_timer <= 0.0:
		set_bubbled(false)
		
func _update_bubble_physics() -> void:
	# bubbled props are always floaty. Only the drag waits until the carry window ends
	gravity_scale = bubble_gravity_scale if is_bubbled else 1.0
	linear_damp = bubble_damp if (is_bubbled and _free_fly_time <= 0.0) else 0.0
