class_name EndingCutscene
extends Node2D


class _Art extends Node2D:
	var kind := 0  
	var size := Vector2.ZERO

	func _draw() -> void:
		if kind == 0:
			CaveEntrance.draw_cave(self, size)
		else:
			var r := Rect2(Vector2(-size.x / 2.0, 0.0), size)
			draw_rect(r, Color(0.75, 0.88, 0.95))
			draw_rect(r, Color(0.35, 0.5, 0.62), false, 2.0)


@export var bubble_scene: PackedScene
@export var squeak_scene: PackedScene
@export var sprite_scale := Vector2.ONE
@export_file("*.tscn") var main_menu_path: String = ""

@export_group("Scene markers")
@export var cave_point: Node2D        
@export var cave_size := Vector2(64, 80)
@export var ledge_point: Node2D       
@export var platform: Node2D         
@export var platform_size := Vector2(120, 16)
@export var draw_placeholder_cave: bool = true
@export var draw_placeholder_platform: bool = true

@export_group("Timing")
@export var fade_time: float = 1.0
@export var walk_speed: float = 60.0
@export var spread: float = 22.0     
@export var look_count: int = 2
@export var look_interval: float = 0.8
@export var jump_time: float = 0.7
@export var jump_height: float = 40.0
@export var jump_stagger: float = 0.35
@export var float_time: float = 8.0
@export var drift := Vector2(1200.0, 0.0) 
@export var float_bobs: float = 3.0

@export_group("Blizzard")
@export var start_intensity: float = 0.3
@export var look_intensity: float = 0.75

@export_group("Title card")
@export var title_text: String = "To Be Continued"
@export var title_size: int = 72
@export var title_delay: float = 1.2       
@export var title_fade: float = 2.5
@export var title_hold: float = 4.0
@export var line_width: float = 380.0

@export_group("Audio")
@export var blizzard_sound: AudioStream
@export var sting_sound: AudioStream       

var _bubble: CutsceneActor
var _squeak: CutsceneActor
var _blizzard: Blizzard
var _fade: ColorRect
var _title_box: VBoxContainer
var _sting: AudioStreamPlayer
var _finishing := false


func _ready() -> void:

	var layer := CanvasLayer.new()
	layer.layer = 100
	_fade = ColorRect.new()
	_fade.color = Color.BLACK
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_fade)
	add_child(layer)

	if cave_point == null or ledge_point == null or platform == null:
		push_warning("EndingCutscene needs Cave Point, Ledge Point and Platform assigned")
		_fade.modulate.a = 0.0
		return

	
	for y in get_tree().current_scene.find_children("*", "Yeti", true, false):
		y.queue_free()

	if draw_placeholder_cave:
		var cave := _Art.new()
		cave.kind = 0
		cave.size = cave_size
		cave_point.add_child(cave)
	if draw_placeholder_platform:
		var plat := _Art.new()
		plat.kind = 1
		plat.size = platform_size
		platform.add_child(plat)

	var floor_y := cave_point.global_position.y + cave_size.y / 2.0
	var start := Vector2(cave_point.global_position.x, floor_y)
	var dir := _dir()
	_bubble = _make_actor(_frames_from(bubble_scene), start, dir)
	_squeak = _make_actor(_frames_from(squeak_scene), start, dir)

	_blizzard = Blizzard.new()
	_blizzard.sound = blizzard_sound
	_blizzard.intensity = start_intensity
	add_child(_blizzard)

	_sting = AudioStreamPlayer.new()
	_sting.stream = sting_sound
	add_child(_sting)

	_run()


func _dir() -> float:
	var d := signf(ledge_point.global_position.x - cave_point.global_position.x)
	return d if d != 0.0 else 1.0


func _frames_from(scene: PackedScene) -> SpriteFrames:
	if scene == null:
		return null
	var inst := scene.instantiate()
	var spr := inst.find_child("AnimatedSprite2D", true, false) as AnimatedSprite2D
	var frames: SpriteFrames = spr.sprite_frames if spr != null else null
	inst.free()
	return frames


func _make_actor(frames: SpriteFrames, pos: Vector2, facing: float) -> CutsceneActor:
	var a := CutsceneActor.new()
	a.sprite_frames = frames
	a.sprite_scale = sprite_scale
	a.z_index = 2
	a.modulate.a = 0.0   
	add_child(a)
	a.global_position = pos
	a.face(facing)
	return a


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		_finish()




func _wait(seconds: float) -> bool:
	await get_tree().create_timer(seconds).timeout
	return not _finishing


func _play(t: Tween) -> bool:
	await t.finished
	return not _finishing




func _run() -> void:
	var dir := _dir()
	var floor_y := cave_point.global_position.y + cave_size.y / 2.0
	var ledge_x := ledge_point.global_position.x

	# 1. fade in on the empty cave
	var t := create_tween()
	t.tween_property(_fade, "modulate:a", 0.0, fade_time)
	if not await _play(t): return
	if not await _wait(0.5): return

	# 2. they step out of the cave, Bubble first
	create_tween().tween_property(_bubble, "modulate:a", 1.0, 0.4)
	if not await _wait(0.5): return
	create_tween().tween_property(_squeak, "modulate:a", 1.0, 0.4)

	# 3. walk to the ledge while the storm starts to build
	_blizzard.ramp_to(look_intensity, 6.0)
	var b_target := Vector2(ledge_x - dir * 10.0, floor_y)
	var s_target := Vector2(ledge_x - dir * (10.0 + spread), floor_y)
	_bubble.walking = true
	_squeak.walking = true
	var walk := create_tween().set_parallel(true)
	walk.tween_property(_bubble, "global_position", b_target,
		_bubble.global_position.distance_to(b_target) / walk_speed)
	walk.tween_property(_squeak, "global_position", s_target,
		_squeak.global_position.distance_to(s_target) / walk_speed).set_delay(0.4)
	if not await _play(walk): return
	_bubble.walking = false
	_squeak.walking = false
	if not await _wait(0.6): return

	# 4. look around as the blizzard picks up
	var look := -dir   # first glance back toward the cave
	for i in look_count * 2:
		_bubble.face(look)
		if not await _wait(0.15): return
		_squeak.face(look)
		if not await _wait(look_interval): return
		look = -look
	_bubble.face(dir)
	_squeak.face(dir)
	if not await _wait(0.6): return

	# 5. jump onto the platform
	var top := platform.global_position
	_jump(_bubble, top + Vector2(-spread / 2.0, 0.0))   # not awaited, so they overlap
	if not await _wait(jump_stagger): return
	if not await _jump(_squeak, top + Vector2(spread / 2.0, 0.0)): return
	if not await _wait(0.4): return

	# ride the platform from here on (reparent keeps their world position)
	_bubble.reparent(platform)
	_squeak.reparent(platform)

	# 6. everything drifts away as the storm swallows the screen
	_blizzard.ramp_to(1.0, float_time)
	var start := platform.global_position
	var drift_tween := create_tween()
	drift_tween.tween_method(func(p: float) -> void:
		platform.global_position = start + drift * p * p \
			+ Vector2(0.0, sin(p * TAU * float_bobs) * 6.0 * (1.0 - p)),
		0.0, 1.0, float_time)
	if not await _wait(float_time * 0.65): return

	# 7. fade to black while it's still drifting
	var to_black := create_tween()
	to_black.tween_property(_fade, "modulate:a", 1.0, float_time * 0.35)
	if not await _play(to_black): return
	_blizzard.ramp_to(0.0, 2.0)   # wind sound dies down under the black

	# 8. title card
	if not await _wait(title_delay): return
	await _show_title()
	if not await _wait(title_hold): return
	_finish()


func _jump(a: CutsceneActor, to: Vector2) -> bool:
	var from := a.global_position
	var t := create_tween()
	t.tween_method(func(p: float) -> void:
		a.global_position = from.lerp(to, p) + Vector2(0.0, -sin(p * PI) * jump_height),
		0.0, 1.0, jump_time)
	return await _play(t)


func _show_title() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 101  
	add_child(layer)

	_title_box = VBoxContainer.new()
	_title_box.set_anchors_preset(Control.PRESET_FULL_RECT)
	_title_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_title_box.add_theme_constant_override("separation", 18)
	_title_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_title_box.modulate.a = 0.0
	layer.add_child(_title_box)

	_title_box.add_child(UiStyle.title(title_text, title_size))

	var line := ColorRect.new()
	line.color = UiStyle.ACCENT
	line.custom_minimum_size = Vector2(line_width, 2.0)
	line.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_title_box.add_child(line)

	await get_tree().process_frame 
	_title_box.pivot_offset = _title_box.size / 2.0
	_title_box.scale = Vector2.ONE * 1.12
	line.pivot_offset = Vector2(line_width / 2.0, 1.0)
	line.scale.x = 0.0

	if sting_sound != null:
		_sting.play()


	var t := create_tween().set_parallel(true)
	t.tween_property(_title_box, "modulate:a", 1.0, title_fade).set_trans(Tween.TRANS_SINE)
	t.tween_property(_title_box, "scale", Vector2.ONE, title_fade + title_hold).set_ease(Tween.EASE_OUT)
	t.tween_property(line, "scale:x", 1.0, 1.5).set_delay(title_fade * 0.6).set_trans(Tween.TRANS_CUBIC)


func _finish() -> void:
	if _finishing:
		return
	_finishing = true
	var t := create_tween().set_parallel(true)
	t.tween_property(_fade, "modulate:a", 1.0, 1.0)
	if _title_box != null:
		t.tween_property(_title_box, "modulate:a", 0.0, 1.2)
	if _blizzard != null:
		_blizzard.ramp_to(0.0, 1.0)
	await t.finished
	if main_menu_path == "":
		push_warning("EndingCutscene has no main_menu_path set")
		return
	get_tree().change_scene_to_file(main_menu_path)
