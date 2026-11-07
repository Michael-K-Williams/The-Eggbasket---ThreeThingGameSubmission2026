# Title card when a level starts: "Level 1" over "Lift-off", fades in as the
# arrival cave fade finishes, hangs about, then fades away.
# Drop Scenes/level_title.tscn in a level and fill in the two lines.
# The layout is saved in the scene (edit it in Godot), and @tool so the editor
# shows the level's own text rather than the placeholder.
@tool
class_name LevelTitle
extends CanvasLayer

@export var number: String = "Level 1":
	set(v):
		number = v
		_refresh_text()
@export var title: String = "":
	set(v):
		title = v
		_refresh_text()
@export var delay: float = 0.5
@export var hold: float = 2.2
@export var fade_time: float = 0.5

var _card: Control


func _ready() -> void:
	layer = 60
	if not has_node("Screen"):
		build()
	_refresh_text()
	if Engine.is_editor_hint():
		return   # editor just shows it
	_card = $Screen/Card
	_card.modulate.a = 0.0
	_play()


# lays the card out. Used to make the saved scene, and as a fallback
func build() -> void:
	var screen := Control.new()
	screen.name = "Screen"
	screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(screen)

	var col := VBoxContainer.new()
	col.name = "Card"
	col.add_theme_constant_override("separation", -4)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var num := UiStyle.title(number.to_upper(), 16, UiStyle.ACCENT)
	num.name = "Number"
	col.add_child(num)
	var big := UiStyle.title(title if title != "" else "Level name", 44)
	big.name = "Title"
	col.add_child(big)
	col.set_anchors_preset(Control.PRESET_CENTER)
	col.grow_horizontal = Control.GROW_DIRECTION_BOTH
	col.grow_vertical = Control.GROW_DIRECTION_BOTH
	col.offset_top = -120
	col.offset_bottom = -120
	screen.add_child(col)


func _refresh_text() -> void:
	if not is_inside_tree() and not has_node("Screen/Card"):
		return
	var num := get_node_or_null("Screen/Card/Number") as Label
	var big := get_node_or_null("Screen/Card/Title") as Label
	if num:
		num.text = number.to_upper()
	if big and title != "":
		big.text = title


func _play() -> void:
	var rest := _card.position
	_card.position = rest + Vector2(0, 10)
	var t := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t.tween_interval(delay)
	t.tween_property(_card, "modulate:a", 1.0, fade_time)
	t.parallel().tween_property(_card, "position", rest, fade_time)
	t.tween_interval(hold)
	t.tween_property(_card, "modulate:a", 0.0, fade_time)
	t.parallel().tween_property(_card, "position", rest - Vector2(0, 8), fade_time)
	t.tween_callback(func(): visible = false)


func shown_alpha() -> float:
	return _card.modulate.a
