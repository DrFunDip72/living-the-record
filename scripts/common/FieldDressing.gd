extends Node2D

# Terrain detail that the shader cannot do: a worn path, scuffed patches, and
# blades of grass that sit in FRONT of the nearest units. Put one of these at
# y = 0 for the ground pass and another below the field for the foreground
# pass -- with y-sorting on, that ordering happens by itself.
@export var mode: String = "ground"  # ground | foreground
@export var field_size: Vector2 = Vector2(960, 540)
@export var tint: Color = Color(0.2, 0.3, 0.15, 1)
@export var rng_seed: int = 7


func _ready() -> void:
	queue_redraw()


func _draw() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = rng_seed
	if mode == "foreground":
		_draw_foreground(rng)
	else:
		_draw_patches(rng)
		_draw_path()


func _draw_path() -> void:
	var w := field_size.x
	var h := field_size.y
	var pts := PackedVector2Array()
	for i in range(26):
		var t: float = float(i) / 25.0
		pts.append(Vector2(w * (0.30 + sin(t * 2.3) * 0.11 + t * 0.09), lerpf(-20.0, h + 20.0, t)))
	var worn := tint.lightened(0.17)
	worn.a = 0.26
	for i in range(pts.size() - 1):
		var t: float = float(i) / float(pts.size() - 1)
		draw_line(pts[i], pts[i + 1], worn, lerpf(13.0, 38.0, t))
	var core := tint.lightened(0.26)
	core.a = 0.14
	for i in range(pts.size() - 1):
		var t: float = float(i) / float(pts.size() - 1)
		draw_line(pts[i], pts[i + 1], core, lerpf(7.0, 22.0, t))


func _draw_patches(rng: RandomNumberGenerator) -> void:
	var w := field_size.x
	var h := field_size.y
	for i in range(16):
		var p := Vector2(rng.randf_range(0.0, w), rng.randf_range(h * 0.1, h))
		var rx: float = rng.randf_range(26.0, 74.0)
		var c := tint.darkened(rng.randf_range(0.12, 0.3)) if i % 2 == 0 else tint.lightened(rng.randf_range(0.06, 0.16))
		c.a = 0.26
		draw_set_transform(p, 0.0, Vector2(1.0, rng.randf_range(0.22, 0.34)))
		draw_circle(Vector2.ZERO, rx, c)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# scattered tufts across the field, small and dark
	for i in range(34):
		var p := Vector2(rng.randf_range(0.0, w), rng.randf_range(h * 0.18, h))
		var d := tint.darkened(0.42)
		d.a = 0.7
		var s: float = rng.randf_range(4.0, 7.0)
		draw_line(p, p + Vector2(0, -s), d, 1.3)
		draw_line(p, p + Vector2(-s * 0.5, -s * 0.8), d, 1.1)
		draw_line(p, p + Vector2(s * 0.5, -s * 0.85), d, 1.1)


func _draw_foreground(rng: RandomNumberGenerator) -> void:
	var w := field_size.x
	var dark := tint.darkened(0.62)
	for i in range(90):
		var x: float = rng.randf_range(-20.0, w + 20.0)
		var y: float = rng.randf_range(-2.0, 14.0)
		var bl: float = rng.randf_range(16.0, 42.0)
		var tilt: float = rng.randf_range(-11.0, 11.0)
		var th: float = rng.randf_range(1.9, 3.4)
		draw_line(Vector2(x, y), Vector2(x + tilt, y - bl), dark, th)
		if i % 3 == 0:
			draw_line(Vector2(x, y), Vector2(x + tilt * 2.2, y - bl * 0.62), dark, th * 0.8)
