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

	_overlay = Control.new()
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_overlay)

	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.03, 0.06, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.add_child(dim)

	var centre := CenterContainer.new()
	centre.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.add_child(centre)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	centre.add_child(col)
	col.add_child(UiStyle.title("Paused", 40))

	var buttons := VBoxContainer.new()
	buttons.add_theme_constant_override("separation", 8)
	buttons.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col.add_child(buttons)
	_resume = _add_button(buttons, "Resume", func(): set_open(false))
	_add_button(buttons, "Restart level", _restart)
	_add_button(buttons, "Main menu", _to_menu)
	_add_button(buttons, "Quit", func(): get_tree().quit())

	var gap := Control.new()
	gap.custom_minimum_size.y = 8
	col.add_child(gap)
	var cards := HBoxContainer.new()
	cards.add_theme_constant_override("separation", 16)
	cards.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	cards.add_child(ControlsLegend.card("Bubble", ControlsLegend.P1_SUB, ControlsLegend.BUBBLE_COL, ControlsLegend.P1_ROWS))
	cards.add_child(ControlsLegend.card("Squeak", ControlsLegend.P2_SUB, ControlsLegend.SQUEAK_COL, ControlsLegend.P2_ROWS))
	col.add_child(cards)
	var esc := ControlsLegend.text("Esc to resume", 13, Color(0.75, 0.8, 0.88))
	esc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(esc)

	_overlay.visible = false
	_overlay.modulate.a = 0.0


func _add_button(parent: Control, label: String, action: Callable) -> Button:
	var b := Button.new()
	b.text = label
	UiStyle.button(b)
	b.pressed.connect(action)
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
