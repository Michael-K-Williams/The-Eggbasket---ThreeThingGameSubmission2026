# Where the yetis come back after dying. Drop one in a level and move it to
# the right spot. If a level has none, they come back at the arrival cave
# instead (cave_exit.gd), and if there isn't one of those either, where they started.
class_name RespawnPoint
extends Marker2D

@export var spread: float = 40.0   # gap between the two players, a yeti is about 33 wide so less than that and they shove each other


func _ready() -> void:
	add_to_group("respawn_points")


# yetis ask every respawn_points member for a position, see Yeti.die()
func get_respawn_position(yeti: Yeti) -> Vector2:
	var side := -1.0 if yeti.player_id == 1 else 1.0
	return global_position + Vector2(side * spread / 2.0, 0.0)
