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

	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	var yeti := body as Yeti
	# cubes share the player layer, so this can be something that isn't a yeti
	if yeti == null:
		return
	if _age >= time_can_enter:
		if yeti.position.y < position.y:
			yeti.velocity.y = yeti.jump_velocity
		queue_free()
		return
	if yeti.is_bubbled or yeti.was_in_bubble:
		return
	yeti.set_bubbled(true)
	queue_free()  # the bubble is absorbed


# called by WindZone
func apply_wind(direction: Vector2, strength: float) -> void:
	_wind_accel += direction * strength * wind_response


func _physics_process(delta: float) -> void:
	_age += delta
	if lifetime > 0.0 and _age >= lifetime:
		queue_free()
		return

	velocity += _wind_accel * delta
	_wind_accel = Vector2.ZERO
	velocity = velocity.move_toward(Vector2.ZERO, drag * delta).limit_length(max_speed)
	position += velocity * delta
