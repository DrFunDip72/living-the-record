shader_type canvas_item;

uniform vec4 color_center : source_color = vec4(0.24, 0.42, 0.2, 1.0);
uniform vec4 color_edge : source_color = vec4(0.06, 0.13, 0.06, 1.0);
uniform float vignette_strength : hint_range(0.0, 2.0) = 1.15;
// 0.0 disables the horizon band, so existing materials look unchanged
uniform float horizon : hint_range(0.0, 1.0) = 0.0;
uniform float mottle : hint_range(0.0, 1.0) = 0.35;
uniform float depth_falloff : hint_range(0.0, 1.0) = 0.22;

float hash12(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(
		mix(hash12(i), hash12(i + vec2(1.0, 0.0)), f.x),
		mix(hash12(i + vec2(0.0, 1.0)), hash12(i + vec2(1.0, 1.0)), f.x),
		f.y);
}

void fragment() {
	vec2 centered = UV - vec2(0.5, 0.5);
	centered.x *= 1.4;
	float d = length(centered) * vignette_strength;
	vec3 c = mix(color_center.rgb, color_edge.rgb, clamp(d, 0.0, 1.0));

	// Ground receding away from the camera: lighter and hazier toward the top,
	// darker underfoot. This is what stops the gradient reading as a flat wall.
	c *= mix(1.0 + depth_falloff * 0.5, 1.0 - depth_falloff, clamp(UV.y, 0.0, 1.0));

	// Broken-up turf rather than a clean sweep
	float n = vnoise(UV * vec2(14.0, 26.0)) * 0.62 + vnoise(UV * vec2(43.0, 74.0)) * 0.38;
	c *= 1.0 + (n - 0.5) * mottle * 0.34;

	if (horizon > 0.001) {
		float band = smoothstep(horizon + 0.05, horizon, UV.y);
		c = mix(c, c * 1.3 + vec3(0.035, 0.045, 0.025), band * 0.8);
		float ridge = smoothstep(0.014, 0.0, abs(UV.y - horizon));
		c = mix(c, c * 0.7, ridge * 0.55);
	}

	COLOR = vec4(c, color_center.a);
}
