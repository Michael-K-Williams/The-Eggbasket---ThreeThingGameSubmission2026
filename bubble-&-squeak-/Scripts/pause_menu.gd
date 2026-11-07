# Escape pauses the game in any level. It's an autoload (see project.godot),
# so new levels get it for free. Does nothing on the main menu.
extends CanvasLayer

const MENU_SCENE := "res://Scenes/main_menu.tscn"

var _overlay: Control
var _resume: Button
var _open := false
var _tween: Tween


func _ready() -> void:
	layer = 90
	process_mode = Node.PROCESS_MODE_ALWAYS   # keeps working while the tree is paused

	# the layout is saved in the scene so it can be edited in Godot (the overlay
	# is left visible there so you can see it), build() only runs if it's missing
	if not has_node("Overlay"):
		build()
	_overlay = $Overlay
	var buttons := $Overlay/Centre/Column/Buttons
	_resume = buttons.get_node("Resume")
	_resume.pressed.connect(func(): set_open(false))
	buttons.get_node("Restart").pressed.connect(_restart)
	buttons.get_node("MainMenu").pressed.connect(_to_menu)
	buttons.get_node("Quit").pressed.connect(func(): get_tree().quit())

	_overlay.visible = false
	_overlay.modulate.a = 0.0


# lays the pause screen out. Used to make the saved scene, and as a fallback
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
	col.add_theme_constant_override("separation", 10)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	centre.add_child(col)
	var heading := UiStyle.title("Paused", 40)
	heading.name = "Heading"
	col.add_child(heading)

	var buttons := VBoxContainer.new()
	buttons.name = "Buttons"
	buttons.add_theme_constant_override("separation", 8)
	buttons.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col.add_child(buttons)
	_add_button(buttons, "Resume", "Resume")
	_add_button(buttons, "Restart", "Restart level")
	_add_button(buttons, "MainMenu", "Main menu")
	_add_button(buttons, "Quit", "Quit")

	var gap := Control.new()
	gap.name = "Gap"
	gap.custom_minimum_size.y = 8
	col.add_child(gap)
	var cards := HBoxContainer.new()
	cards.name = "Cards"
	cards.add_theme_constant_override("separation", 16)
	cards.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	cards.add_child(ControlsLegend.card("Bubble", ControlsLegend.P1_SUB, ControlsLegend.BUBBLE_COL, ControlsLegend.P1_ROWS))
	cards.add_child(ControlsLegend.card("Squeak", ControlsLegend.P2_SUB, ControlsLegend.SQUEAK_COL, ControlsLegend.P2_ROWS))
	col.add_child(cards)
	var esc := ControlsLegend.text("Esc to resume", 13, Color(0.75, 0.8, 0.88))
	esc.name = "EscHint"
	esc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(esc)


func _add_button(parent: Control, node_name: String, label: String) -> Button:
	var b := Button.new()
	b.name = node_name
	b.text = label
	UiStyle.button(b)
	parent.add_child(b)
	return b


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("pause") or event.is_echo():
		return
	if not _open and _on_menu():
		return
	set_open(not _open)
	get_viewport().set_input_as_handled()


func _on_menu() -> bool:
	var scene := get_tree().current_scene
	return scene == null or scene.scene_file_path == MENU_SCENE


func set_open(value: bool) -> void:
	_open = value
	get_tree().paused = value
	if _tween:
		_tween.kill()
	if value:
		_overlay.visible = true
		_resume.grab_focus()
		# the pause screen has its own copy of the controls, tuck the level's one away
		get_tree().call_group("controls_legend", "close")
	_tween = create_tween()
	_tween.tween_property(_overlay, "modulate:a", 1.0 if value else 0.0, 0.15)
	if not value:
		_tween.tween_callback(func(): _overlay.visible = false)


func is_open() -> bool:
	return _open


func _restart() -> void:
	_close_now()
	get_tree().reload_current_scene()


func _to_menu() -> void:
	_close_now()
	get_tree().change_scene_to_file(MENU_SCENE)


# no fade when leaving the level, it'd still be showing over the next scene
func _close_now() -> void:
	if _tween:
		_tween.kill()
	_open = false
	get_tree().paused = false
	_overlay.visible = false
	_overlay.modulate.a = 0.0
