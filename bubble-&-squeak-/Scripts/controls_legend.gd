# On-screen controls: a card per player in their colour, keys drawn as keycaps.
# Shows when the level starts, fades out after show_seconds (0 = stays up),
# Tab toggles it. While it's hidden a small "Tab  Controls" reminder stays put.
# Drop Scenes/controls_legend.tscn in a level, it sits on its own CanvasLayer.
class_name ControlsLegend
extends CanvasLayer

@export var show_seconds: float = 6.0
@export var fade_time: float = 0.35

const BUBBLE_COL := Color(0.3, 0.6, 1.0)    # same as the cave orbs
const SQUEAK_COL := Color(1.0, 0.3, 0.3)
# Bubble's the mouse and Squeak's the yeti, the names are the wrong way round on purpose
const P1_SUB := "Player 1 · the mouse"
const P2_SUB := "Player 2 · the yeti"

const P1_ROWS := [
	[["A", "D"], "Move"],
	[["W"], "Jump"],
	[["Q"], "Blow a bubble"],
	[["F"], "Use / pick up / throw"],
	[["Left mouse"], "Hold to grab a cube"],
]
const P2_ROWS := [
	[["Left", "Right"], "Move"],
	[["Up"], "Jump"],
	[["Right Shift"], "Hold to blow wind"],
	[["Enter"], "Use / pick up / throw"],
	[["Right mouse"], "Hold to grab a cube"],
]

var _cards: Control
var _reminder: Control
var _open := false
var _tween: Tween
var _hide_timer: SceneTreeTimer


func _ready() -> void:
	layer = 50
	add_to_group("controls_legend")
	process_mode = Node.PROCESS_MODE_ALWAYS   # so it can fade out while the game's paused

	var screen := Control.new()
	screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(screen)

	_cards = HBoxContainer.new()
	_cards.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_cards.offset_left = 16
	_cards.offset_right = -16
	_cards.offset_top = 14
	_cards.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen.add_child(_cards)
	_cards.add_child(card("Bubble", ControlsLegend.P1_SUB, BUBBLE_COL, P1_ROWS))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cards.add_child(spacer)
	_cards.add_child(card("Squeak", ControlsLegend.P2_SUB, SQUEAK_COL, P2_ROWS))
	_cards.modulate.a = 0.0

	# small "Tab  Controls" tag, top middle, shown while the cards are hidden
	var tag := HBoxContainer.new()
	tag.add_theme_constant_override("separation", 6)
	tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tag.add_child(key("Tab"))
	tag.add_child(text("Controls", 13, Color(0.95, 0.97, 1.0)))
	var tag_box := PanelContainer.new()
	tag_box.add_theme_stylebox_override("panel", Hint.box_style())
	tag_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tag_box.add_child(tag)
	tag_box.set_anchors_preset(Control.PRESET_CENTER_TOP)
	tag_box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	tag_box.offset_top = 10
	screen.add_child(tag_box)
	_reminder = tag_box
	_reminder.modulate.a = 0.0

	_set_open(true)
	_schedule_hide()


func _unhandled_input(event: InputEvent) -> void:
	if get_tree().paused:
		return   # the pause screen already shows the controls
	if event.is_action_pressed("toggle_controls") and not event.is_echo():
		_set_open(not _open)
		if _open:
			_schedule_hide()
		get_viewport().set_input_as_handled()


func _schedule_hide() -> void:
	if show_seconds <= 0.0:
		return
	var timer := get_tree().create_timer(show_seconds)
	_hide_timer = timer
	timer.timeout.connect(func():
		# only the newest timer counts, so pressing Tab again restarts the countdown
		if _hide_timer == timer:
			_set_open(false))


func _set_open(value: bool) -> void:
	_open = value
	if _tween:
		_tween.kill()
	_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_tween.tween_property(_cards, "modulate:a", 1.0 if value else 0.0, fade_time)
	_tween.tween_property(_reminder, "modulate:a", _reminder_alpha(), fade_time)


func _reminder_alpha() -> float:
	return 0.0 if _open or get_tree().paused else 0.85


var _was_paused := false

func _process(_delta: float) -> void:
	# hide the "Tab Controls" tag while the pause screen is up, bring it back after
	var p := get_tree().paused
	if p != _was_paused:
		_was_paused = p
		create_tween().tween_property(_reminder, "modulate:a", _reminder_alpha(), 0.15)


func is_open() -> bool:
	return _open


# the pause menu calls this so the two sets of cards don't stack up
func close() -> void:
	if _open:
		_hide_timer = null
		_set_open(false)


# ---------- building bits, static so the pause menu and main menu can use them ----------

static func card(title: String, subtitle: String, colour: Color, rows: Array) -> Control:
	var sb := Hint.box_style()
	sb.border_color = colour
	sb.border_width_left = 4
	sb.content_margin_left = 14
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", sb)
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 5)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(col)

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 8)
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	head.add_child(text(title, 17, colour))
	var sub := text(subtitle, 12, Color(0.75, 0.8, 0.88))
	sub.size_flags_vertical = Control.SIZE_SHRINK_END
	head.add_child(sub)
	col.add_child(head)

	for row in rows:
		var line := HBoxContainer.new()
		line.add_theme_constant_override("separation", 8)
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var keys := HBoxContainer.new()
		keys.add_theme_constant_override("separation", 4)
		keys.custom_minimum_size.x = 104   # lines the action names up in a column
		keys.mouse_filter = Control.MOUSE_FILTER_IGNORE
		for k in row[0]:
			keys.add_child(key(k))
		line.add_child(keys)
		line.add_child(text(row[1], 13, Color(0.92, 0.94, 0.98)))
		col.add_child(line)
	return card


static func key(name: String) -> Control:
	# a keycap: light face with a darker lip along the bottom
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.93, 0.94, 0.97)
	sb.border_color = Color(0.55, 0.58, 0.66)
	sb.border_width_bottom = 3
	sb.set_corner_radius_all(4)
	sb.content_margin_left = 6
	sb.content_margin_right = 6
	sb.content_margin_top = 1
	sb.content_margin_bottom = 2
	var cap := PanelContainer.new()
	cap.add_theme_stylebox_override("panel", sb)
	cap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cap.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	cap.add_child(text(name, 12, Color(0.12, 0.13, 0.17)))
	return cap


static func text(s: String, size: int, colour: Color) -> Label:
	var l := Label.new()
	l.text = s
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", colour)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l
