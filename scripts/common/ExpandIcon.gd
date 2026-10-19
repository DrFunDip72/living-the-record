extends Control

# Four corner brackets with outward arrows -- the usual "go fullscreen" glyph,
# drawn rather than shipped as an image.
@export var color: Color = Color(0.92, 0.84, 0.6, 1)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func _draw() -> void:
	var w := size.x
	var h := size.y
	if w <= 2.0 or h <= 2.0:
		return
	var m: float = minf(w, h) * 0.22
	var arm: float = minf(w, h) * 0.2
	var t: float = maxf(1.6, minf(w, h) * 0.085)
	var corners := [
		[Vector2(m, m), Vector2(1, 1)],
		[Vector2(w - m, m), Vector2(-1, 1)],
		[Vector2(m, h - m), Vector2(1, -1)],
		[Vector2(w - m, h - m), Vector2(-1, -1)],
	]
	for c in corners:
		var p: Vector2 = c[0]
		var d: Vector2 = c[1]
		draw_line(p, p + Vector2(arm * d.x, 0), color, t)
		draw_line(p, p + Vector2(0, arm * d.y), color, t)
