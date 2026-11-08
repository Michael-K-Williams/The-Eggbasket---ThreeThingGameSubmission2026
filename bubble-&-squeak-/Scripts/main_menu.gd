# Title screen: the level backdrop with drifting clouds and bubbles floating up,
# the title in the players' colours, and Play / Controls / Quit.
# Bubble is the yeti (player 1), Squeak is the mouse in the wizard hat (player 2).
#
# The layout is saved in main_menu.tscn so you can edit it in Godot. This script
# just wires up the buttons and runs the animations. build() only runs if the
# saved layout is missing. The Controls overlay is hidden in the editor, click
# the eye on ControlsOverlay to see it.
extends Control

#const FIRST_LEVEL := "res://Scenes/level_1.tscn"
const FIRST_LEVEL := "res://Scenes/Starting_Cutscene.tscn"
#const FIRST_LEVEL := "res://Scenes/Ending_Cutscene.tscn"
#const FIRST_LEVEL := "res://Scenes/level_3.tscn"

var _clouds: Control
var _bubbles: Control
var _title: Control
var _buttons: Control
var _controls: Control
var _play: Button
var _time := 0.0
var _spawn_left := 0.0
var _title_top := 70.0


func _ready() -> void:
	if not has_node("Backdrop"):
		build()
	_clouds = $Backdrop/Clouds
	_bubbles = $Backdrop/Bubbles
	_title = $Title
	_buttons = $Buttons
	_controls = $ControlsOverlay
	_play = $Buttons/Play
	_play.pressed.connect(func(): get_tree().change_scene_to_file(FIRST_LEVEL))
	$Buttons/Controls.pressed.connect(func(): _show_controls(true))
	$Buttons/Quit.pressed.connect(func(): get_tree().quit())
	$ControlsOverlay/Centre/Column/Back.pressed.connect(func(): _show_controls(false))
	_controls.visible = false
	_title_top = _title.offset_top
	_bob_title()
	_fade_in()
	_play.grab_focus()


# ---------- layout (saved into the scene) ----------

func build() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_backdrop()
	_build_title()
	_build_buttons()
	_build_controls()
	_build_footer()


func _layer(parent: Node, node_name: String, tex: String) -> TextureRect:
	var r := TextureRect.new()
	r.name = node_name
	r.texture = load(tex)
	r.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	r.set_anchors_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(r)
	return r


func _full(node_name: String, parent: Node) -> Control:
	var c := Control.new()
	c.name = node_name
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(c)
	return c


func _build_backdrop() -> void:
	var back := _full("Backdrop", self)
	var clouds := _layer(back, "Clouds", "res://sprites/clouds.png")
	# a little wider than the screen so it can drift without showing an edge
	clouds.offset_left = -40
	clouds.offset_right = 40
	_layer(back, "Back", "res://sprites/back.png")
	_layer(back, "Middle", "res://sprites/middle.png")
	_layer(back, "Front", "res://sprites/front.png")
	_full("Bubbles", back)   # rising bubbles get spawned in here while the menu runs
	# darken it a bit so the title and buttons stand out
	var shade := ColorRect.new()
	shade.name = "Shade"
	shade.color = Color(0.03, 0.05, 0.09, 0.35)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	back.add_child(shade)


func _named_title(node_name: String, s: String, size: int, colour := UiStyle.TEXT) -> Label:
	var l := UiStyle.title(s, size, colour)
	l.name = node_name
	return l


func _build_title() -> void:
	var col := VBoxContainer.new()
	col.name = "Title"
	col.add_theme_constant_override("separation", 0)
	col.set_anchors_preset(Control.PRESET_CENTER_TOP)
	col.grow_horizontal = Control.GROW_DIRECTION_BOTH
	col.offset_top = 70
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(col)
	var row := HBoxContainer.new()
	row.name = "Names"
	row.add_theme_constant_override("separation", 14)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(_named_title("Bubble", "Bubble", 72, ControlsLegend.BUBBLE_COL))
	row.add_child(_named_title("And", "&", 56))
	row.add_child(_named_title("Squeak", "Squeak", 72, ControlsLegend.SQUEAK_COL))
	col.add_child(row)
	col.add_child(_named_title("Subtitle", "a co-op puzzle platformer for one yeti and one mouse", 18, Color(0.85, 0.92, 1.0)))


func _build_buttons() -> void:
	var col := VBoxContainer.new()
	col.name = "Buttons"
	col.add_theme_constant_override("separation", 10)
	col.set_anchors_preset(Control.PRESET_CENTER)
	col.grow_horizontal = Control.GROW_DIRECTION_BOTH
	col.grow_vertical = Control.GROW_DIRECTION_BOTH
	col.offset_top = 40
	col.offset_bottom = 40
	add_child(col)
	for label in ["Play", "Controls", "Quit"]:
		var b := Button.new()
		b.name = label
		b.text = label
		UiStyle.button(b, 22)
		col.add_child(b)


func _build_controls() -> void:
	var overlay := _full("ControlsOverlay", self)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.visible = false
	var dim := ColorRect.new()
	dim.name = "Dim"
	dim.color = Color(0.02, 0.03, 0.06, 0.8)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(dim)
	var centre := CenterContainer.new()
	centre.name = "Centre"
	centre.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(centre)
	var col := VBoxContainer.new()
	col.name = "Column"
	col.add_theme_constant_override("separation", 14)
	centre.add_child(col)
	col.add_child(_named_title("Heading", "Controls", 34))
	var cards := HBoxContainer.new()
	cards.name = "Cards"
	cards.add_theme_constant_override("separation", 16)
	cards.add_child(ControlsLegend.card("Bubble", ControlsLegend.P1_SUB, ControlsLegend.BUBBLE_COL, ControlsLegend.P1_ROWS))
	cards.add_child(ControlsLegend.card("Squeak", ControlsLegend.P2_SUB, ControlsLegend.SQUEAK_COL, ControlsLegend.P2_ROWS))
	col.add_child(cards)
	var help := ControlsLegend.text("Both of you get into the cave and press use to move on.  Esc pauses, Tab shows these in a level.", 13, Color(0.8, 0.86, 0.94))
	help.name = "Help"
	col.add_child(help)
	var back := Button.new()
	back.name = "Back"
	back.text = "Back"
	UiStyle.button(back, 20)
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col.add_child(back)


func _build_footer() -> void:
	var l := ControlsLegend.text("Three Thing Game 2026  ·  The Eggbasket", 13, Color(0.85, 0.9, 0.97, 0.8))
	l.name = "Footer"
	l.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	l.grow_horizontal = Control.GROW_DIRECTION_BOTH
	l.grow_vertical = Control.GROW_DIRECTION_BEGIN
	l.offset_bottom = -12
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(l)


# ---------- running ----------

func _process(delta: float) -> void:
	_time += delta
	_clouds.position.x = -40.0 + sin(_time * 0.15) * 30.0
	_spawn_left -= delta
	if _spawn_left <= 0.0:
		_spawn_left = randf_range(0.35, 0.8)
		_spawn_bubble()


func _spawn_bubble() -> void:
	var b := BubbleVisual.new()
	b.radius = randf_range(6.0, 22.0)
	var start := Vector2(randf_range(0.0, size.x), size.y + 30.0)
	b.position = start
	b.modulate.a = randf_range(0.5, 0.9)
	_bubbles.add_child(b)
	var rise := randf_range(6.0, 11.0)
	var drift := randf_range(-60.0, 60.0)
	var t := b.create_tween().set_parallel(true)
	t.tween_property(b, "position:y", -40.0, rise)
	t.tween_property(b, "position:x", start.x + drift, rise).set_trans(Tween.TRANS_SINE)
	t.chain().tween_callback(b.queue_free)


func _bob_title() -> void:
	var t := create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(_title, "offset_top", _title_top + 8.0, 2.2)
	t.tween_property(_title, "offset_top", _title_top, 2.2)


func _show_controls(value: bool) -> void:
	_controls.visible = value
	# the title and buttons would show through otherwise
	_title.visible = not value
	_buttons.visible = not value
	if value:
		_controls.modulate.a = 0.0
		create_tween().tween_property(_controls, "modulate:a", 1.0, 0.2)
		$ControlsOverlay/Centre/Column/Back.grab_focus()
	else:
		_play.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if _controls.visible and (event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel")):
		_show_controls(false)
		get_viewport().set_input_as_handled()


func is_showing_controls() -> bool:
	return _controls.visible


func _fade_in() -> void:
	var black := ColorRect.new()
	black.color = Color.BLACK
	black.set_anchors_preset(Control.PRESET_FULL_RECT)
	black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(black)
	var t := create_tween()
	t.tween_property(black, "modulate:a", 0.0, 0.6)
	t.tween_callback(black.queue_free)
