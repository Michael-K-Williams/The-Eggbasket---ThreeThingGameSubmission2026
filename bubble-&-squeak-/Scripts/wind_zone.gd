class_name WindZone
extends Area2D

const SHADER_CODE := """
shader_type canvas_item;

uniform vec4 wind_color : source_color = vec4(0.75, 0.92, 1.0, 1.0);
uniform float speed = 1.4;
uniform float streak_density = 6.0;
uniform float streak_stretch = 0.25;
uniform float intensity = 0.6;

float hash(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

void fragment() {
	vec2 p = vec2(UV.x * streak_density, UV.y * streak_density * streak_stretch + TIME * speed);
	float n = vnoise(p) * 0.65 + vnoise(p * 2.1 + 7.3) * 0.35;
	float streaks = smoothstep(0.45, 0.85, n);

	float side_fade = smoothstep(0.0, 0.2, UV.x) * smoothstep(1.0, 0.8, UV.x);
	float far_fade = smoothstep(0.0, 0.4, UV.y);

	float alpha = (streaks + 0.08) * side_fade * far_fade * intensity;
	COLOR = vec4(wind_color.rgb, alpha);
}
"""

@export var size: Vector2 = Vector2(48, 220)
@export var strength: float = 700.0
@export var tint := Color(0.75, 0.92, 1.0, 1.0)
@export_flags_2d_physics var affects_mask: int = 2 | 4 | 8


func _ready() -> void:
	collision_layer = 0
	collision_mask = affects_mask
	monitorable = false

	var rect_shape := RectangleShape2D.new()
	rect_shape.size = size
	var cs := CollisionShape2D.new()
	cs.shape = rect_shape
	add_child(cs)

	var shader := Shader.new()
	shader.code = SHADER_CODE
	var mat := ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("wind_color", tint)

	var rect := ColorRect.new()
	rect.size = size
	rect.position = -size / 2.0
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.material = mat
	add_child(rect)


func _physics_process(_delta: float) -> void:
	var dir := Vector2.UP.rotated(global_rotation)
	for body in get_overlapping_bodies():
		if body.has_method("apply_wind"):
			body.apply_wind(dir, strength)
	for area in get_overlapping_areas():
		if area.has_method("apply_wind"):
			area.apply_wind(dir, strength)
			
			
func set_active(on: bool) -> void:
	set_deferred("monitoring", on)
	set_physics_process(on)
	visible = on
