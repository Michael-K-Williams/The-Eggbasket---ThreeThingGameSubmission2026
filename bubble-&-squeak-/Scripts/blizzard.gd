class_name Blizzard
extends CanvasLayer

const SHADER_CODE := """
shader_type canvas_item;

uniform float intensity : hint_range(0.0, 1.0) = 0.5;
uniform vec2 wind_dir = vec2(-1.0, 0.3);   // direction the snow travels
uniform vec4 snow_color : source_color = vec4(0.92, 0.96, 1.0, 1.0);
uniform float whiteout = 0.45;

float hash12(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

vec2 hash22(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * vec3(0.1031, 0.1030, 0.0973));
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.xx + p3.yz) * p3.zy);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash12(i), hash12(i + vec2(1.0, 0.0)), f.x),
			mix(hash12(i + vec2(0.0, 1.0)), hash12(i + vec2(1.0, 1.0)), f.x), f.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 3; i++) {
		v += a * vnoise(p);
		p = p * 2.03 + 17.1;
		a *= 0.5;
	}
	return v;
}

// q = wind-aligned space (x along the wind). Checks neighbouring cells so no flake is ever clipped
float flake_layer(vec2 q, float scale, float speed, float density, float streak, float t, float seed) {
	vec2 p = vec2((q.x - t * speed) / streak, q.y) * scale;
	vec2 id = floor(p);
	vec2 f = fract(p);
	float a = 0.0;
	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			vec2 off = vec2(float(x), float(y));
			vec2 cell = id + off + seed;
			if (hash12(cell) <= density) {
				vec2 r = hash22(cell + 9.1);
				vec2 pos = off + r;
				pos.y += sin(t * 1.5 + r.x * 6.2831) * 0.12;   // slight flutter
				float size = mix(0.1, 0.28, hash12(cell + 3.3));
				float bright = 0.5 + 0.5 * hash12(cell + 5.5);
				a = max(a, smoothstep(size, size * 0.2, length(f - pos)) * bright);
			}
		}
	}
	return a;
}

void fragment() {
	vec2 res = 1.0 / SCREEN_PIXEL_SIZE;
	vec2 uv = UV * vec2(res.x / res.y, 1.0);
	vec2 w = normalize(wind_dir);
	vec2 q = vec2(dot(uv, w), dot(uv, vec2(-w.y, w.x)));

	float i = intensity;
	float speed = mix(0.3, 1.4, i);
	float t = TIME;

	float a = 0.0;
	a += flake_layer(q, 24.0, speed * 0.6, mix(0.08, 0.45, i), 2.0, t, 0.0) * 0.5;
	a += flake_layer(q, 15.0, speed * 0.9, mix(0.06, 0.4, i), 2.5, t, 31.0) * 0.75;
	a += flake_layer(q, 9.0, speed * 1.3, mix(0.04, 0.3, i), 3.0, t, 67.0);

	// soft rolling fog, thickening quickly toward full intensity
	vec2 fp = vec2(q.x - t * speed * 0.5, q.y) * vec2(1.2, 2.4);
	float fog = smoothstep(0.15, 0.85, fbm(fp));
	a += fog * whiteout * i * i;
	a += whiteout * 0.3 * i * i * i;

	float alpha = min(1.0 - exp(-a * 1.6), 0.92);
	COLOR = vec4(snow_color.rgb, alpha * smoothstep(0.0, 0.03, i));
}
"""

@export_range(0.0, 1.0) var intensity: float = 0.5:
	set(value):
		intensity = clampf(value, 0.0, 1.0)
		_apply()
@export var wind_direction := Vector2(-1.0, 0.3)
@export var snow_color := Color(0.92, 0.96, 1.0)
@export var whiteout: float = 0.45

@export_group("Audio")
@export var sound: AudioStream                 
@export var max_volume_db: float = -4.0   

var _mat: ShaderMaterial
var _tween: Tween
var _audio: AudioStreamPlayer


func _init() -> void:
	layer = 50


func _ready() -> void:
	var shader := Shader.new()
	shader.code = SHADER_CODE
	_mat = ShaderMaterial.new()
	_mat.shader = shader

	var rect := ColorRect.new()
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.material = _mat
	add_child(rect)

	if sound != null:
		_audio = AudioStreamPlayer.new()
		_audio.stream = sound
		_audio.finished.connect(_audio.play)  
		add_child(_audio)

	_apply()


func _apply() -> void:
	if _mat == null:
		return
	_mat.set_shader_parameter("intensity", intensity)
	_mat.set_shader_parameter("wind_dir", wind_direction)
	_mat.set_shader_parameter("snow_color", snow_color)
	_mat.set_shader_parameter("whiteout", whiteout)


	if _audio != null:
		if intensity <= 0.01:
			if _audio.playing:
				_audio.stop()
		else:
			_audio.volume_db = max_volume_db + linear_to_db(pow(intensity, 1.5))
			if not _audio.playing:
				_audio.play()


func ramp_to(target: float, duration: float) -> Tween:
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "intensity", target, duration)
	return _tween
