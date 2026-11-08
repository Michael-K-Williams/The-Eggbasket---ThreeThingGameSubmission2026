class_name CutsceneActor
extends Node2D

@export var sprite_frames: SpriteFrames
@export var sprite_scale := Vector2.ONE       
@export var faces_right: bool = true
@export var feet_offset: float = 0.0
@export var sit_drop: float = 0.0            
@export var talk_bob: float = 2.0            

@export_group("Voice")
@export var talk_sound: AudioStream
@export var voice_pitch: float = 1.0
@export var voice_volume_db: float = -16.0    
@export var blip_length: float = 0.09       
@export var blip_start_random: float = 0.15   
@export var blip_fade: float = 0.02 

var sitting := false
var talking := false
var walking := false

var _holder: Node2D
var _sprite: AnimatedSprite2D
var _voice: AudioStreamPlayer
var _t := randf() * 10.0
var _last_hop := -1

var _blip_tween: Tween


func _ready() -> void:
	_holder = Node2D.new()
	add_child(_holder)

	_sprite = AnimatedSprite2D.new()
	_sprite.sprite_frames = sprite_frames
	_sprite.scale = sprite_scale
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_holder.add_child(_sprite)

	if sprite_frames != null:
		var tex := sprite_frames.get_frame_texture(_current_anim(), 0)
		if tex != null:
			_sprite.position = Vector2(0.0, -tex.get_height() * sprite_scale.y / 2.0 + feet_offset)
		_sprite.play(_current_anim())

	_voice = AudioStreamPlayer.new()
	_voice.stream = talk_sound
	_voice.volume_db = voice_volume_db
	add_child(_voice)


func face(dir: float) -> void:
	if dir != 0.0:
		scale.x = signf(dir) * (1.0 if faces_right else -1.0)


func _current_anim() -> StringName:
	if sprite_frames == null:
		return &"default"
	if walking and sprite_frames.has_animation(&"walk"):
		return &"walk"
	if sitting and sprite_frames.has_animation(&"sit"):
		return &"sit"
	return &"default"


func _process(delta: float) -> void:
	if _sprite == null:
		return
	_t += delta

	var bob := 0.0
	if walking:
		bob = -roundf(absf(sin(_t * 12.0)) * 3.0)
	elif talking:
		var burst := clampf(sin(_t * 2.3) * 2.0, 0.0, 1.0)
		bob = -roundf(absf(sin(_t * 14.0)) * talk_bob * burst)
		var hop := int(floor(_t * 14.0 / PI))
		if hop != _last_hop:
			_last_hop = hop
			if burst > 0.3:
				_play_blip()

	
	_holder.position.y = bob + (sit_drop if sitting else 0.0)

	var anim := _current_anim()
	if _sprite.animation != anim:
		_sprite.play(anim)


func _play_blip() -> void:
	if _voice.stream == null:
		return

	
	if _blip_tween:
		_blip_tween.kill()

	
	var stream_len := _voice.stream.get_length()
	var start := 0.0
	if blip_start_random > 0.0 and stream_len > 0.0:
		start = randf() * minf(blip_start_random, maxf(stream_len - blip_length, 0.0))

	_voice.pitch_scale = voice_pitch * randf_range(0.9, 1.12)
	_voice.volume_db = voice_volume_db
	_voice.play(start)

	
	_blip_tween = create_tween()
	_blip_tween.tween_interval(maxf(blip_length - blip_fade, 0.01))
	_blip_tween.tween_property(_voice, "volume_db", -60.0, blip_fade)
	_blip_tween.tween_callback(_voice.stop)
