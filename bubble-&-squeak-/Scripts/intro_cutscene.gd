class_name IntroCutscene
extends Node2D

@export_file("*.tscn") var next_level_path: String = ""
@export var campfire: Node2D           
@export var exit_point: Node2D         
@export var floor_offset: float = 7.0  
@export var sit_offset: float = 44.0   
@export var talk_time: float = 6.0
@export var turn_time: float = 1.6      
@export var blizzard_ramp_time: float = 7.0
@export_range(0.1, 0.9) var react_point: float = 0.45  
@export var walk_speed: float = 70.0
@export var fade_time: float = 0.8
@export var bubble_scene: PackedScene  
@export var squeak_scene: PackedScene  
@export var sprite_scale := Vector2.ONE

@export_group("Audio")
@export var talk_sound: AudioStream
@export var bubble_voice_pitch: float = 0.8  
@export var squeak_voice_pitch: float = 1.5  
@export var blizzard_sound: AudioStream

@export_group("Looking around")
@export var look_pause: float = 1.0       
@export var look_count: int = 2           
@export var look_interval: float = 0.7     
@export var final_talk_time: float = 2.5  

var _bubble: CutsceneActor
var _squeak: CutsceneActor
var _blizzard: Blizzard
var _fade: ColorRect
var _finishing := false


func _ready() -> void:
	if campfire == null or exit_point == null:
		push_warning("IntroCutscene needs a Campfire and an Exit Point assigned")
		return

	
	for y in get_tree().current_scene.find_children("*", "Yeti", true, false):
		y.queue_free()

	
	var layer := CanvasLayer.new()
	layer.layer = 100
	_fade = ColorRect.new()
	_fade.color = Color.BLACK
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_fade)
	add_child(layer)

	var base := campfire.global_position + Vector2(0.0, floor_offset)
	_bubble = _make_actor(_frames_from(bubble_scene), base + Vector2(-sit_offset, 0.0), 1.0, bubble_voice_pitch)
	_squeak = _make_actor(_frames_from(squeak_scene), base + Vector2(sit_offset, 0.0), -1.0, squeak_voice_pitch)

	_blizzard = Blizzard.new()
	_blizzard.sound = blizzard_sound
	_blizzard.intensity = 0.0
	add_child(_blizzard)

	_run()


func _make_actor(frames: SpriteFrames, pos: Vector2, facing: float, pitch: float) -> CutsceneActor:
	var a := CutsceneActor.new()
	a.sprite_frames = frames
	a.sprite_scale = sprite_scale
	a.talk_sound = talk_sound
	a.voice_pitch = pitch
	a.sitting = true
	a.z_index = 2
	add_child(a)
	a.global_position = pos
	a.face(facing)
	return a


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):  
		_finish()


func _run() -> void:
	var t := create_tween()
	t.tween_property(_fade, "modulate:a", 0.0, fade_time)
	await t.finished

	
	var elapsed := 0.0
	var turn := 0
	while elapsed < talk_time:
		_bubble.talking = turn % 2 == 0
		_squeak.talking = turn % 2 == 1
		await get_tree().create_timer(turn_time).timeout
		elapsed += turn_time
		turn += 1


	_blizzard.ramp_to(1.0, blizzard_ramp_time)
	_bubble.talking = false
	_squeak.talking = false
	await get_tree().create_timer(look_pause).timeout

	
	await _look_around()

	
	_bubble.face(1.0)
	_squeak.face(-1.0)
	await get_tree().create_timer(0.4).timeout

	
	var talked := 0.0
	var turn_b := 0
	while talked < final_talk_time:
		_bubble.talking = turn_b % 2 == 0
		_squeak.talking = turn_b % 2 == 1
		await get_tree().create_timer(turn_time).timeout
		talked += turn_time
		turn_b += 1


	_bubble.talking = false
	_squeak.talking = false
	await get_tree().create_timer(0.4).timeout

	var floor_y := campfire.global_position.y + floor_offset
	var ex := exit_point.global_position.x
	var b_target := Vector2(ex - 8.0, floor_y)
	var s_target := Vector2(ex + 8.0, floor_y)

	for a in [_bubble, _squeak]:
		a.sitting = false
		a.walking = true
		a.face(ex - a.global_position.x)

	var b_time := _bubble.global_position.distance_to(b_target) / walk_speed
	var s_time := _squeak.global_position.distance_to(s_target) / walk_speed
	var walk := create_tween().set_parallel(true)
	walk.tween_property(_bubble, "global_position", b_target, b_time)
	walk.tween_property(_squeak, "global_position", s_target, s_time).set_delay(0.3)
	await walk.finished

	_bubble.walking = false
	_squeak.walking = false
	var vanish := create_tween().set_parallel(true)
	vanish.tween_property(_bubble, "modulate:a", 0.0, 0.3)
	vanish.tween_property(_squeak, "modulate:a", 0.0, 0.3)
	await vanish.finished

	await get_tree().create_timer(0.8).timeout
	_finish()

func _frames_from(scene: PackedScene) -> SpriteFrames:
	if scene == null:
		return null
	var inst := scene.instantiate()
	var spr := inst.find_child("AnimatedSprite2D", true, false) as AnimatedSprite2D
	var frames: SpriteFrames = spr.sprite_frames if spr != null else null
	inst.free()
	return frames
	
func _look_around() -> void:
	var dir := -1.0   
	for i in look_count * 2:
		_bubble.face(dir)
		await get_tree().create_timer(0.15).timeout  
		_squeak.face(dir)
		await get_tree().create_timer(look_interval).timeout
		dir = -dir

func _finish() -> void:
	_blizzard.ramp_to(0.0, fade_time)
	if _finishing:
		return
	_finishing = true
	if next_level_path == "":
		push_warning("IntroCutscene has no next_level_path set")
		return
	var t := create_tween()
	t.tween_property(_fade, "modulate:a", 1.0, fade_time)
	await t.finished
	get_tree().change_scene_to_file("res://Scenes/level_1.tscn")
