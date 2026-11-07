# Title screen: the level backdrop with drifting clouds and bubbles floating up,
# the title in the players' colours, and Play / Controls / Quit.
# Bubble is the yeti (player 1), Squeak is the mouse in the wizard hat (player 2).
extends Control

const FIRST_LEVEL := "res://Scenes/level_1.tscn"

var _clouds: TextureRect
var _bubbles: Control
var _title: Control
var _controls: Control
var _play: Button
var _time := 0.0
var _spawn_left := 0.0


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_backdrop()
	_build_title()
	_build_buttons()
	_build_controls()
	_build_footer()
	_fade_in()
	_play.grab_focus()


# ---------- backdrop ----------

func _layer(tex: String) -> TextureRect:
	var r := TextureRect.new()
	r.texture = load(tex)
	r.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	r.set_anchors_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(r)
	return r


func _build_backdrop() -> void:
	_clouds = _layer("res://sprites/clouds.png")
	# a little wider than the screen so it can drift without showing an edge
	_clouds.offset_left = -40
	_clouds.offset_right = 40
	_layer("res://sprites/back.png")
	_layer("res://sprites/middle.png")
	_layer("res://sprites/front.png")

	_bubbles = Control.new()
	_bubbles.set_anchors_preset(Control.PRESET_FULL_RECT)
	_bubbles.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bubbles)

	# darken the middle a bit so the title and buttons stand out
	var shade := ColorRect.new()
	shade.color = Color(0.03, 0.05, 0.09, 0.35)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)


func _process(delta: float) -> void:
	_time += delta
	_clouds.position.x = sin(_time * 0.15) * 30.0
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


# ---------- title card ----------

func _build_title() -> void:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 0)
	col.set_anchors_preset(Control.PRESET_CENTER_TOP)
	col.grow_horizontal = Control.GROW_DIRECTION_BOTH
	col.offset_top = 70
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(col)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(UiStyle.title("Bubble", 72, ControlsLegend.BUBBLE_COL))
	row.add_child(UiStyle.title("&", 56))
	row.add_child(UiStyle.title("Squeak", 72, ControlsLegend.SQUEAK_COL))
	col.add_child(row)
	col.add_child(UiStyle.title("a co-op puzzle platformer for one yeti and one mouse", 18, Color(0.85, 0.92, 1.0)))
	_title = col

	# gentle bob
	var t := create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(col, "offset_top", 78.0, 2.2)
	t.tween_property(col, "offset_top", 70.0, 2.2)


# ---------- buttons ----------

func _build_buttons() -> void:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	col.set_anchors_preset(Control.PRESET_CENTER)
	col.grow_horizontal = Control.GROW_DIRECTION_BOTH
	col.grow_vertical = Control.GROW_DIRECTION_BOTH
	col.offset_top = 40
	col.offset_bottom = 40
	add_child(col)
	_play = _button(col, "Play", func(): get_tree().change_scene_to_file(FIRST_LEVEL))
	_button(col, "Controls", func(): _show_controls(true))
	_button(col, "Quit", func(): get_tree().quit())


func _button(parent: Control, label: String, action: Callable) -> Button:
	var b := Button.new()
	b.text = label
	UiStyle.button(b, 22)
	b.pressed.connect(action)
	parent.add_child(b)
	return b


# ---------- controls overlay ----------

func _build_controls() -> void:
	_controls = Control.new()
	_controls.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_controls)
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.03, 0.06, 0.8)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_controls.add_child(dim)
	var centre := CenterContainer.new()
	centre.set_anchors_preset(Control.PRESET_FULL_RECT)
	_controls.add_child(centre)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 14)
	centre.add_child(col)
	col.add_child(UiStyle.title("Controls", 34))
	var cards := HBoxContainer.new()
	cards.add_theme_constant_override("separation", 16)
	cards.add_child(ControlsLegend.card("Bubble", ControlsLegend.P1_SUB, ControlsLegend.BUBBLE_COL, ControlsLegend.P1_ROWS))
	cards.add_child(ControlsLegend.card("Squeak", ControlsLegend.P2_SUB, ControlsLegend.SQUEAK_COL, ControlsLegend.P2_ROWS))
	col.add_child(cards)
	col.add_child(ControlsLegend.text("Both of you get into the cave and press use to move on.  Esc pauses, Tab shows these in a level.", 13, Color(0.8, 0.86, 0.94)))
	var back := Button.new()
	back.text = "Back"
	UiStyle.button(back, 20)
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back.pressed.connect(func(): _show_controls(false))
	col.add_child(back)
	_controls.visible = false


func _show_controls(value: bool) -> void:
	_controls.visible = value
	# the title and buttons would show through otherwise
	_title.visible = not value
	_play.get_parent().visible = not value
	if value:
		_controls.modulate.a = 0.0
		create_tween().tween_property(_controls, "modulate:a", 1.0, 0.2)
		_controls.find_children("*", "Button", true, false)[0].grab_focus()
	else:
		_play.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if _controls.visible and (event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel")):
		_show_controls(false)
		get_viewport().set_input_as_handled()


func is_showing_controls() -> bool:
	return _controls.visible


# ---------- bits ----------

func _build_footer() -> void:
	var l := ControlsLegend.text("Three Thing Game 2026  ·  The Eggbasket", 13, Color(0.85, 0.9, 0.97, 0.8))
	l.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	l.grow_horizontal = Control.GROW_DIRECTION_BOTH
	l.grow_vertical = Control.GROW_DIRECTION_BEGIN
	l.offset_bottom = -12
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(l)


func _fade_in() -> void:
	var black := ColorRect.new()
	black.color = Color.BLACK
	black.set_anchors_preset(Control.PRESET_FULL_RECT)
	black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(black)
	var t := create_tween()
	t.tween_property(black, "modulate:a", 0.0, 0.6)
	t.tween_callback(black.queue_free)
