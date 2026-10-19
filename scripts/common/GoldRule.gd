extends Control

# A hairline that fades out toward both ends, so it reads as engraved rather
# than drawn. Used above and below the title.
@export var color: Color = Color(0.85, 0.72, 0.38, 1)
@export var falloff: float = 0.75
@export var center_pip: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func _draw() -> void:
	var w := size.x
	if w <= 1.0:
		return
	var y := size.y * 0.5
	var steps := 64
	for i in range(steps):
		var t0: float = float(i) / float(steps)
		var t1: float = float(i + 1) / float(steps)
		var a: float = 1.0 - absf(t0 - 0.5) * 2.0
		a = pow(clampf(a, 0.0, 1.0), falloff)
		var c := color
		c.a = a
		draw_rect(Rect2(w * t0, y - 0.6, w * (t1 - t0) + 1.0, 1.2), c)
	if center_pip:
		var p := color
		p.a = 0.95
		draw_colored_polygon(PackedVector2Array([
			Vector2(w * 0.5, y - 3.2), Vector2(w * 0.5 + 3.2, y),
			Vector2(w * 0.5, y + 3.2), Vector2(w * 0.5 - 3.2, y),
		]), p)
