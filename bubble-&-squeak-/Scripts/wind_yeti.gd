# Player 2. Ability: put a fan down next to you, blowing the way you're facing.
class_name WindYeti
extends Yeti

var _fan: Fan = null


func _use_ability() -> void:
	# only one of our fans at a time
	if is_instance_valid(_fan):
		_fan.queue_free()

	var fan := Fan.new()
	fan.wind_direction = Vector2(_facing, 0)
	get_parent().add_child(fan)
	var ext := _body_extents()
	fan.global_position = Vector2(
		global_position.x + _facing * (ext.x + fan.fan_size.x / 2.0 + 6.0),
		global_position.y + ext.y - fan.fan_size.y / 2.0)
	_fan = fan
