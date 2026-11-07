class_name Bubble
extends Area2D

@export var radius: float = 30.0
@export_flags_2d_physics var player_mask: int = 2   
@export_flags_2d_physics var bubble_layer: int = 8   
@export var lifetime: float = 10.0  
@export var wind_response: float = 1.5            
@export var drag: float = 0.0
@export var max_speed: float = 0.0
@export var time_can_enter: float = 0.5
@export var owner_grace: float = 0.25   # seconds the one who blew it can't touch it
var owner_yeti: Yeti = null

var velocity := Vector2.ZERO
var _wind_accel := Vector2.ZERO
var _age := 0.0


func _ready() -> void:
	collision_layer = bubble_layer
	collision_mask = player_mask

	var circle := CircleShape2D.new()
	circle.radius = radius
	var cs := CollisionShape2D.new()
	cs.shape = circle
	add_child(cs)

	var visual := BubbleVisual.new()
	visual.radius = radius
	add_child(visual)


# Checked every frame while something is inside (not just on entry), so a yeti
# who's still overlapping when the owner grace runs out is picked up too.
# - fresh bubble: swallows whoever touches it
# - older bubble: pops, and bounces anyone who lands on it
# - the one who blew it can't touch it for a moment, so walking forward while
#   you blow doesn't bubble you by accident
# - someone already in a bubble is left alone
func _touch(yeti: Yeti) -> void:
	if yeti.is_bubbled or yeti.in_cave:
		return
	if yeti == owner_yeti and _age < owner_grace:
		return
	if _age >= time_can_enter:
		if yeti.position.y < position.y:
			yeti.velocity.y = yeti.jump_velocity
		queue_free()
		return
	if yeti.was_in_bubble:
		return
	yeti.set_bubbled(true)
	queue_free()

# called by WindZone
func apply_wind(direction: Vector2, strength: float) -> void:
	_wind_accel += direction * strength * wind_response


func _physics_process(delta: float) -> void:
	_age += delta
	for body in get_overlapping_bodies():
		var yeti := body as Yeti   # cubes share the player layer, so it might not be a yeti
		if yeti != null:
			_touch(yeti)
			if is_queued_for_deletion():
				return
	if lifetime > 0.0 and _age >= lifetime:
		queue_free()
		return

	velocity += _wind_accel * delta
	_wind_accel = Vector2.ZERO
	velocity = velocity.move_toward(Vector2.ZERO, drag * delta).limit_length(max_speed)
	position += velocity * delta
