extends Control

@export var icon_id: String = "swords"
@export var accent: Color = Color(0.8, 0.7, 0.3, 1)

const INK := Color(0.09, 0.08, 0.11, 1)


func _ready() -> void:
	custom_minimum_size = Vector2(150, 96)


func set_icon(p_id: String, p_accent: Color) -> void:
	icon_id = p_id
	accent = p_accent
	queue_redraw()


func _draw() -> void:
	var w := size.x
	var h := size.y
	var cx := w * 0.5
	var cy := h * 0.5
	match icon_id:
		"swords":
			_draw_swords(cx, cy)
		"hood":
			_draw_hood(cx, cy)
		"bow":
			_draw_bow(cx, cy)
		"temple":
			_draw_temple(cx, cy)
		"sling":
			_draw_sling(cx, cy)
		"tower":
			_draw_tower(cx, cy)
		"war":
			_draw_war(cx, cy)
		_:
			draw_circle(Vector2(cx, cy), 26.0, accent)


func _blade(from: Vector2, to: Vector2, width: float, col: Color) -> void:
	draw_line(from, to, INK, width + 4.0)
	draw_line(from, to, col, width)


func _draw_swords(cx: float, cy: float) -> void:
	var a0 := Vector2(cx - 30, cy + 28)
	var a1 := Vector2(cx + 28, cy - 30)
	var b0 := Vector2(cx + 30, cy + 28)
	var b1 := Vector2(cx - 28, cy - 30)
	_blade(a0, a1, 7.0, Color(0.85, 0.87, 0.92, 1))
	_blade(b0, b1, 7.0, Color(0.85, 0.87, 0.92, 1))
	_blade(Vector2(cx - 14, cy + 6), Vector2(cx + 2, cy + 22), 6.0, accent)
	_blade(Vector2(cx + 14, cy + 6), Vector2(cx - 2, cy + 22), 6.0, accent)
	draw_circle(Vector2(cx, cy + 26), 6.0, INK)
	draw_circle(Vector2(cx, cy + 26), 4.0, accent)


func _draw_hood(cx: float, cy: float) -> void:
	var body := PackedVector2Array([
		Vector2(cx - 22, cy + 32), Vector2(cx - 16, cy - 4),
		Vector2(cx, cy - 26), Vector2(cx + 16, cy - 4),
		Vector2(cx + 22, cy + 32),
	])
	draw_colored_polygon(body, INK)
	var inner := PackedVector2Array([
		Vector2(cx - 15, cy + 28), Vector2(cx - 10, cy - 2),
		Vector2(cx, cy - 18), Vector2(cx + 10, cy - 2),
		Vector2(cx + 15, cy + 28),
	])
	draw_colored_polygon(inner, accent)
	draw_circle(Vector2(cx - 5, cy + 2), 3.0, Color(1, 0.95, 0.6, 1))
	draw_circle(Vector2(cx + 5, cy + 2), 3.0, Color(1, 0.95, 0.6, 1))


func _draw_bow(cx: float, cy: float) -> void:
	var pts := PackedVector2Array()
	var steps := 18
	for i in range(steps + 1):
		var t: float = float(i) / float(steps)
		var ang: float = lerp(-1.15, 1.15, t)
		pts.append(Vector2(cx - 6 + cos(ang) * 30.0, cy + sin(ang) * 34.0))
	for i in range(pts.size() - 1):
		draw_line(pts[i], pts[i + 1], INK, 9.0)
	for i in range(pts.size() - 1):
		draw_line(pts[i], pts[i + 1], Color(0.55, 0.36, 0.16, 1), 5.0)
	draw_line(pts[0], pts[pts.size() - 1], Color(0.9, 0.88, 0.8, 1), 2.0)
	_blade(Vector2(cx - 24, cy), Vector2(cx + 34, cy), 4.0, accent)
	var head := PackedVector2Array([
		Vector2(cx + 40, cy), Vector2(cx + 30, cy - 7), Vector2(cx + 30, cy + 7),
	])
	draw_colored_polygon(head, INK)


func _draw_temple(cx: float, cy: float) -> void:
	var base := PackedVector2Array([
		Vector2(cx - 34, cy + 30), Vector2(cx + 34, cy + 30),
		Vector2(cx + 34, cy + 20), Vector2(cx - 34, cy + 20),
	])
	draw_colored_polygon(base, INK)
	for i in range(4):
		var px: float = cx - 24 + i * 16.0
		draw_line(Vector2(px, cy + 20), Vector2(px, cy - 8), INK, 11.0)
		draw_line(Vector2(px, cy + 20), Vector2(px, cy - 8), accent, 7.0)
	var roof := PackedVector2Array([
		Vector2(cx - 40, cy - 8), Vector2(cx + 40, cy - 8), Vector2(cx, cy - 34),
	])
	draw_colored_polygon(roof, INK)
	var roof_in := PackedVector2Array([
		Vector2(cx - 32, cy - 11), Vector2(cx + 32, cy - 11), Vector2(cx, cy - 28),
	])
	draw_colored_polygon(roof_in, accent)


func _draw_sling(cx: float, cy: float) -> void:
	draw_line(Vector2(cx - 26, cy - 26), Vector2(cx - 4, cy + 8), INK, 7.0)
	draw_line(Vector2(cx + 26, cy - 26), Vector2(cx + 4, cy + 8), INK, 7.0)
	draw_line(Vector2(cx - 26, cy - 26), Vector2(cx - 4, cy + 8), Color(0.75, 0.66, 0.5, 1), 3.0)
	draw_line(Vector2(cx + 26, cy - 26), Vector2(cx + 4, cy + 8), Color(0.75, 0.66, 0.5, 1), 3.0)
	var pouch := PackedVector2Array([
		Vector2(cx - 12, cy + 6), Vector2(cx + 12, cy + 6),
		Vector2(cx + 8, cy + 24), Vector2(cx - 8, cy + 24),
	])
	draw_colored_polygon(pouch, INK)
	draw_circle(Vector2(cx, cy + 14), 8.0, accent)


func _draw_tower(cx: float, cy: float) -> void:
	var body := PackedVector2Array([
		Vector2(cx - 26, cy + 32), Vector2(cx + 26, cy + 32),
		Vector2(cx + 20, cy - 14), Vector2(cx - 20, cy - 14),
	])
	draw_colored_polygon(body, INK)
	var body_in := PackedVector2Array([
		Vector2(cx - 20, cy + 28), Vector2(cx + 20, cy + 28),
		Vector2(cx + 15, cy - 10), Vector2(cx - 15, cy - 10),
	])
	draw_colored_polygon(body_in, accent)
	for i in range(4):
		var bx: float = cx - 24 + i * 16.0
		draw_rect(Rect2(bx, cy - 26, 11, 14), INK)
	draw_line(Vector2(cx, cy - 26), Vector2(cx, cy - 44), INK, 4.0)
	var flag := PackedVector2Array([
		Vector2(cx, cy - 44), Vector2(cx + 22, cy - 38), Vector2(cx, cy - 31),
	])
	draw_colored_polygon(flag, Color(0.85, 0.25, 0.2, 1))
	draw_rect(Rect2(cx - 7, cy + 12, 14, 20), Color(0.15, 0.12, 0.1, 1))


func _draw_war(cx: float, cy: float) -> void:
	# banner pole + title of liberty
	draw_line(Vector2(cx - 18, cy + 34), Vector2(cx - 18, cy - 34), INK, 5.0)
	var flag := PackedVector2Array([
		Vector2(cx - 16, cy - 32), Vector2(cx + 26, cy - 26),
		Vector2(cx + 16, cy - 14), Vector2(cx + 26, cy - 2), Vector2(cx - 16, cy - 6),
	])
	draw_colored_polygon(flag, INK)
	var flag_in := PackedVector2Array([
		Vector2(cx - 14, cy - 29), Vector2(cx + 20, cy - 24),
		Vector2(cx + 12, cy - 14), Vector2(cx + 20, cy - 5), Vector2(cx - 14, cy - 9),
	])
	draw_colored_polygon(flag_in, accent)
	# formation of dots (companies)
	for i in range(3):
		for j in range(2):
			draw_circle(Vector2(cx + 2 + i * 12, cy + 14 + j * 12), 4.5, INK)
			draw_circle(Vector2(cx + 2 + i * 12, cy + 14 + j * 12), 3.0, Color(0.85, 0.82, 0.72, 1))
