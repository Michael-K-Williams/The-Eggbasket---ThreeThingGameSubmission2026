# Notices when a level has gone wrong and offers to restart it. It's an autoload
# (see project.godot), so every level gets it for free. Two things trigger it:
#  - a cube has dropped into a pit or out of the level, so it can't be used again
#  - you've been mashing buttons for a while and nothing at all is moving
# "Keep trying" hides it and leaves it alone for a bit.
extends CanvasLayer

const MENU_SCENE := "res://Scenes/main_menu.tscn"

@export var struggle_seconds: float = 10.0   # buttons pressed but nobody going anywhere
@export var lost_cube_seconds: float = 2.0   # a cube has to stay lost this long
@export var lost_cube_depth: float = 470.0   # a cube resting on the floor sits at y=448
@export var progress_distance: float = 24.0  # how far something has to move to count as progress
@export var snooze_seconds: float = 60.0     # quiet time after "Keep trying"

const ACTIONS := [
	"p1_left", "p1_right", "p1_jump", "p1_ability", "p1_interact", "p1_grab",
	"p2_left", "p2_right", "p2_jump", "p2_ability", "p2_interact", "p2_grab",
]

var _overlay: Control
var _restart: Button
var _open := false
var _struggle := 0.0
var _lost_for := 0.0
var _snooze := 0.0
var _anchors := {}      # node -> where it was when we last saw progress
var _scene_seen: Node


func _ready() -> void:
	layer = 95
	process_mode = Node.PROCESS_MODE_ALWAYS   # the prompt pauses the game, it has to keep working

	# the layout is saved in the scene so it can be edited in Godot,
	# build() only runs if it's missing
	if not has_node("Overlay"):
		build()
	_overlay = $Overlay
	var buttons := $Overlay/Centre/Column/Buttons
	_restart = buttons.get_node("Restart")
	_restart.pressed.connect(_do_restart)
	buttons.get_node("KeepTrying").pressed.connect(_keep_trying)
	_overlay.visible = false


func build() -> void:
	var overlay := Control.new()
	overlay.name = "Overlay"
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)

	var dim := ColorRect.new()
	dim.name = "Dim"
	dim.color = Color(0.02, 0.03, 0.06, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(dim)

	var centre := CenterContainer.new()
	centre.name = "Centre"
	centre.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(centre)

	var col := VBoxContainer.new()
	col.name = "Column"
	col.add_theme_constant_override("separation", 12)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	centre.add_child(col)

	var heading := UiStyle.title("Stuck?", 40)
	heading.name = "Heading"
	col.add_child(heading)

	var message := ControlsLegend.text("Looks like something's gone wrong.\nWant to restart the level?", 18, Color(0.85, 0.9, 0.96))
	message.name = "Message"
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(message)

	var buttons := VBoxContainer.new()
	buttons.name = "Buttons"
	buttons.add_theme_constant_override("separation", 8)
	buttons.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col.add_child(buttons)
	for entry in [["Restart", "Restart level"], ["KeepTrying", "Keep trying"]]:
		var b := Button.new()
		b.name = entry[0]
		b.text = entry[1]
		UiStyle.button(b)
		buttons.add_child(b)


func _physics_process(delta: float) -> void:
	if _open or get_tree().paused:
		return
	var yetis := get_tree().get_nodes_in_group("yetis")
	var scene := get_tree().current_scene
	if yetis.is_empty() or scene == null or scene.scene_file_path == MENU_SCENE:
		_reset()
		return
	if scene != _scene_seen:   # a new level, start fresh
		_scene_seen = scene
		_reset()
		_snooze = 0.0
	if _snooze > 0.0:
		_snooze -= delta
		return

	# a cube that's fallen where nobody can reach it
	var lost := false
	#for node in scene.find_children("*", "PushableCube", true, false):
		#if (node as Node2D).global_position.y > lost_cube_depth:
			#lost = true
	_lost_for = _lost_for + delta if lost else 0.0

	# buttons being pressed while nothing moves
	var moved := false
	var things: Array = []
	things.append_array(yetis)
	things.append_array(scene.find_children("*", "PushableCube", true, false))
	for n in things:
		var pos: Vector2 = (n as Node2D).global_position
		if not _anchors.has(n) or pos.distance_to(_anchors[n]) > progress_distance:
			_anchors[n] = pos
			moved = true
	if moved:
		_struggle = 0.0
	elif _any_input():
		_struggle += delta

	if _lost_for >= lost_cube_seconds or _struggle >= struggle_seconds:
		show_prompt()


func _any_input() -> bool:
	for a in ACTIONS:
		if InputMap.has_action(a) and Input.is_action_pressed(a):
			return true
	return false


func _reset() -> void:
	_struggle = 0.0
	_lost_for = 0.0
	_anchors.clear()


func show_prompt() -> void:
	_open = true
	_reset()
	get_tree().paused = true
	_overlay.visible = true
	get_tree().call_group("controls_legend", "close")
	_restart.grab_focus()


func is_open() -> bool:
	return _open


func _keep_trying() -> void:
	_close()
	_snooze = snooze_seconds


func _do_restart() -> void:
	_close()
	get_tree().reload_current_scene()


func _close() -> void:
	_open = false
	_overlay.visible = false
	_reset()
	get_tree().paused = false


# Esc counts as "keep trying" rather than opening the pause menu on top
func _unhandled_input(event: InputEvent) -> void:
	if _open and event.is_action_pressed("pause") and not event.is_echo():
		_keep_trying()
		get_viewport().set_input_as_handled()
