shader_type canvas_item;

uniform vec4 top_color : source_color = vec4(0.26, 0.42, 0.62, 1.0);
uniform vec4 horizon_color : source_color = vec4(0.86, 0.66, 0.38, 1.0);
uniform float horizon : hint_range(0.0, 1.0) = 0.62;

void fragment() {
	float t = clamp(UV.y / max(horizon, 0.001), 0.0, 1.0);
	COLOR = mix(top_color, horizon_color, pow(t, 1.4));
}
