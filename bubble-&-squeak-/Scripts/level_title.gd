# Title card when a level starts: "Level 1" over "Lift-off", fades in as the
# arrival cave fade finishes, hangs about, then fades away.
# Drop Scenes/level_title.tscn in a level and fill in the two lines.
class_name LevelTitle
extends CanvasLayer

@export var number: String = "Level 1"
@export var title: String = ""
@export var delay: float = 0.5
@export var hold: float = 2.2
@export var fade_time: float = 0.5

var _card: Control


func _ready() -> void:
	layer = 60
	var screen := Control.new()
	screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(screen)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", -4)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(UiStyle.title(number.to_upper(), 16, UiStyle.ACCENT))
	col.add_child(UiStyle.title(title, 44))
	col.set_anchors_preset(Control.PRESET_CENTER)
	col.grow_horizontal = Control.GROW_DIRECTION_BOTH
	col.grow_vertical = Control.GROW_DIRECTION_BOTH
	col.offset_top = -120
	col.offset_bottom = -120
	screen.add_child(col)
	_card = col
	_card.modulate.a = 0.0
	_play()


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
