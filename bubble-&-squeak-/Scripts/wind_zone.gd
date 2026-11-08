class_name WindZone
extends Area2D

const SHADER_CODE := """
shader_type canvas_item;

uniform vec4 wind_color : source_color = vec4(0.75, 0.92, 1.0, 1.0);
uniform float speed = 1.4;
uniform float streak_density = 6.0;
uniform float streak_stretch = 0.25;
uniform float intensity = 0.6;
// how wide the wind is where it starts, as a fraction of the full width.
// 1.0 = a straight strip (fans), smaller = narrow at the source and spreading out
uniform float source_width = 1.0;

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

	// wind blows towards UV.y = 0, so the source end is UV.y = 1
	float along = 1.0 - UV.y;
	float half_w = 0.5 * mix(source_width, 1.0, smoothstep(0.0, 0.35, along));
	// wobble the edges with drifting noise so it doesn't read as a straight-sided box
	float wobble = (vnoise(vec2(UV.y * 4.0 - TIME * speed * 0.5, 3.1)) - 0.5) * 0.14;
	float d = abs(UV.x - 0.5 + wobble);
	float side_fade = 1.0 - smoothstep(half_w * 0.2, half_w, d);
	// thins out over the back half and is gone by the far end
	float end_fade = 1.0 - smoothstep(0.4, 1.0, along);
	float near_fade = smoothstep(0.0, 0.06, along);

	float alpha = (streaks + 0.06) * side_fade * end_fade * end_fade * near_fade * intensity;
	COLOR = vec4(wind_color.rgb, alpha);
}
"""

@export var size: Vector2 = Vector2(48, 220)
@export var strength: float = 700.0
@export var tint := Color(0.75, 0.92, 1.0, 1.0)
@export_flags_2d_physics var affects_mask: int = 2 | 4 | 8 | 16
@export_range(0.0, 1.0) var source_width: float = 1.0   
var exclude: Node = null   


@export var DIRECTION := Vector2.LEFT
 
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
	mat.set_shader_parameter("source_width", source_width)

	var rect := ColorRect.new()
	rect.size = size
	rect.position = -size / 2.0
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.material = mat
	add_child(rect)


func _physics_process(_delta: float) -> void:
	var dir := Vector2.UP.rotated(global_rotation)
	
	
	var upward := dir.y < -0.7
	var top := global_position.y - size.y / 2.0
	for body in get_overlapping_bodies():
		if body == exclude:
			continue
		if body.has_method("apply_wind"):
			body.apply_wind(dir, strength)
		if upward and body.has_method("wind_ceiling"):
			body.wind_ceiling(top)
	for area in get_overlapping_areas():
		if area.has_method("apply_wind"):
			area.apply_wind(dir, strength)
			
			
func set_active(on: bool) -> void:
	set_deferred("monitoring", on)
	set_physics_process(on)
	visible = on
