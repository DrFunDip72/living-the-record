shader_type canvas_item;

uniform vec4 color_center : source_color = vec4(0.24, 0.42, 0.2, 1.0);
uniform vec4 color_edge : source_color = vec4(0.06, 0.13, 0.06, 1.0);
uniform float vignette_strength : hint_range(0.0, 2.0) = 1.15;

void fragment() {
	vec2 centered = UV - vec2(0.5, 0.5);
	centered.x *= 1.4;
	float d = length(centered) * vignette_strength;
	COLOR = mix(color_center, color_edge, clamp(d, 0.0, 1.0));
}
