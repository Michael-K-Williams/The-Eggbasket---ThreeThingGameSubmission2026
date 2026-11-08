class_name WindYeti
extends Yeti

@export_group("Gust")
@export var gust_linger: float = 0.0        # 0 = stops the moment you let go
@export var gust_size := Vector2(48, 220)
@export var gust_strength: float = 700.0
@export_range(0.0, 1.0) var gust_source_width: float = 0.35
@export var gust_tint := Color(1.0, 0.55, 0.2)   # yellowy red, so it reads as Squeak's wind
@export var freeze_while_blowing: bool = true
@export_range(0.0, 2.0) var gust_opacity: float = 1.1   # the shader's default is 0.6


@export var shake_amount: float = 1.0     # pixels left and right
@export var shake_speed: float = 10.0     # shakes per second

var _sprite: AnimatedSprite2D
var _sprite_base_x := 0.0
var _shake_time := 0.0


var _gust: WindZone = null
var _linger_left := -1.0


func _use_ability() -> void:
	print("WindYeti ability fired, player_id = ", player_id)
	_stop_ability()

	var dir := Vector2(_facing, 0.0)
	var zone := WindZone.new()
	zone.size = Vector2(gust_size.x, gust_size.y + _body_extents().x)
	zone.strength = gust_strength
	zone.source_width = gust_source_width
	zone.tint = gust_tint
	zone.exclude = self
	zone.rotation = Vector2.UP.angle_to(dir)
	zone.position = dir * (zone.size.y / 2.0)
	zone.show_behind_parent = true
	add_child(zone)
	await get_tree().physics_frame
	print("gust pos=", zone.global_position, " visible=", zone.is_visible_in_tree(),
		" monitoring=", zone.monitoring, " size=", zone.size, " parent alpha=", modulate.a)
	_set_gust_opacity(zone)
	_gust = zone
	_linger_left = -1.0


func _physics_process(delta: float) -> void:
	var blowing := is_instance_valid(_gust) and Input.is_action_pressed(_act_ability)

	if blowing:
		_shake_sprite(delta)
	else:
		_stop_shake()

	if blowing and freeze_while_blowing:
		_linger_left = -1.0
		velocity = Vector2.ZERO
		return

	super(delta)

	if not is_instance_valid(_gust):
		return
	if blowing:
		_linger_left = -1.0
		return
	if _linger_left < 0.0:
		_linger_left = gust_linger
	_linger_left -= delta
	if _linger_left <= 0.0:
		_stop_ability()


func _stop_ability() -> void:
	if is_instance_valid(_gust):
		_gust.queue_free()
	_gust = null
	_linger_left = -1.0
	
func _set_gust_opacity(zone: WindZone) -> void:
	for node in zone.find_children("*", "CanvasItem", true, false):
		var item := node as CanvasItem
		if item.material is ShaderMaterial:
			(item.material as ShaderMaterial).set_shader_parameter("intensity", gust_opacity)
			
func _shake_sprite(delta: float) -> void:
	if _sprite == null:
		_sprite = find_child("AnimatedSprite2D", true, false) as AnimatedSprite2D
		if _sprite == null:
			return
		_sprite_base_x = _sprite.position.x
	_shake_time += delta
	var dir := 1.0 if sin(_shake_time * shake_speed * PI) >= 0.0 else -1.0
	_sprite.position.x = _sprite_base_x + dir * shake_amount
	
func _stop_shake() -> void:
	if _sprite != null:
		_sprite.position.x = _sprite_base_x
		
func _can_carry_props() -> bool:
	return true
