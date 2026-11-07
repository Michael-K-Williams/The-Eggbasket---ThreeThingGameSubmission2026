# Player 2. Ability: hold the key to blow wind out in front. It keeps going as
# long as the key's held, and dies off gust_linger seconds after you let go.
# The gust is stuck to the yeti, so it moves with them, but it keeps blowing
# whichever way they were facing when they started.
# (Fans you can put in a level are separate, see Fan.gd / fan.tscn.)
class_name WindYeti
extends Yeti

@export_group("Gust")
@export var gust_linger: float = 0.5        # how long it keeps blowing after you let go
@export var gust_size := Vector2(48, 220)   # width, then how far it reaches
@export var gust_strength: float = 700.0
@export_range(0.0, 1.0) var gust_source_width: float = 0.35   # narrow where it leaves the yeti, spreads out from there

var _gust: WindZone = null
var _linger_left := -1.0   # counting down once the key's let go, -1 while held


func _use_ability() -> void:
	# pressing again starts a fresh gust rather than stacking two
	_stop_ability()

	var dir := Vector2(_facing, 0.0)
	var zone := WindZone.new()
	# starts at our middle so it looks like it's coming out of us, the extra
	# length keeps the reach past our body the same as gust_size.y
	zone.size = Vector2(gust_size.x, gust_size.y + _body_extents().x)
	zone.strength = gust_strength
	zone.source_width = gust_source_width
	zone.exclude = self   # it starts inside us, don't blow ourselves about
	# WindZone blows along its own "up", so turn it to face the way we're facing
	zone.rotation = Vector2.UP.angle_to(dir)
	zone.position = dir * (zone.size.y / 2.0)
	zone.show_behind_parent = true   # drawn behind the yeti so it comes out from them
	add_child(zone)
	_gust = zone
	_linger_left = -1.0


func _physics_process(delta: float) -> void:
	super(delta)
	if not is_instance_valid(_gust):
		return
	if Input.is_action_pressed(_act_ability):
		_linger_left = -1.0   # still held, keep blowing
		return
	if _linger_left < 0.0:
		_linger_left = gust_linger   # just let go, start the countdown
	_linger_left -= delta
	if _linger_left <= 0.0:
		_stop_ability()


func _stop_ability() -> void:
	if is_instance_valid(_gust):
		_gust.queue_free()
	_gust = null
	_linger_left = -1.0
