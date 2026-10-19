extends Control

@export var icon_id: String = "swords"
@export var accent: Color = Color(0.8, 0.7, 0.3, 1)

# Near-black, used for every silhouette so the tiles read as one set
const INK := Color(0.055, 0.05, 0.07, 1)


func _ready() -> void:
	custom_minimum_size = Vector2(150, 96)
	resized.connect(queue_redraw)


func set_icon(p_id: String, p_accent: Color) -> void:
	icon_id = p_id
	accent = p_accent
	queue_redraw()


# Banded vertical gradient -- cheaper than a shader and good enough at tile size
func _vgrad(x: float, y: float, w: float, h: float, top: Color, bottom: Color, steps: int = 14) -> void:
	var sh: float = h / float(steps)
	for i in range(steps):
		var t: float = float(i) / float(maxi(steps - 1, 1))
		draw_rect(Rect2(x, y + i * sh, w, sh + 1.0), top.lerp(bottom, t))


func _draw() -> void:
	var w := size.x
	var h := size.y
	if w <= 1.0 or h <= 1.0:
		return
	var horizon: float = h * 0.72

	# sky: deep at the top, warming toward the horizon
	_vgrad(0, 0, w, horizon, accent.darkened(0.72), accent.darkened(0.3))
	# ground
	_vgrad(0, horizon, w, h - horizon, accent.darkened(0.62), accent.darkened(0.84), 6)
	# horizon seam
	draw_rect(Rect2(0, horizon - 1.0, w, 1.5), accent.darkened(0.86))

	match icon_id:
		"swords": _scene_banner(w, h, horizon)
		"hood": _scene_night(w, h, horizon)
		"bow": _scene_bow(w, h, horizon)
		"temple": _scene_temple(w, h, horizon)
		"sling": _scene_sling(w, h, horizon)
		"tower": _scene_fort(w, h, horizon)
		"war": _scene_war(w, h, horizon)
		"ship": _scene_ship(w, h, horizon)
		_: draw_circle(Vector2(w * 0.5, h * 0.5), h * 0.2, INK)

	# a soft darkening at the very bottom so the name below sits on something
	_vgrad(0, h - 10.0, w, 10.0, Color(0, 0, 0, 0), Color(0, 0, 0, 0.35), 5)


func _pawn(x: float, base_y: float, s: float) -> void:
	# the same rounded pawn the units use, in silhouette
	draw_colored_polygon(PackedVector2Array([
		Vector2(x - 3.4 * s, base_y), Vector2(x - 2.3 * s, base_y - 6.0 * s),
		Vector2(x + 2.3 * s, base_y - 6.0 * s), Vector2(x + 3.4 * s, base_y),
	]), INK)
	draw_circle(Vector2(x, base_y - 8.2 * s), 2.6 * s, INK)


func _scene_banner(w: float, h: float, hz: float) -> void:
	# a rise with the banner planted on it
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, h), Vector2(0, hz + 6), Vector2(w * 0.34, hz - 7),
		Vector2(w * 0.72, hz + 4), Vector2(w, hz - 1), Vector2(w, h),
	]), INK.lerp(accent.darkened(0.8), 0.55))
	var px: float = w * 0.3
	var top: float = hz - 44.0
	draw_rect(Rect2(px - 1.2, top, 2.6, hz - 5 - top), INK)
	draw_colored_polygon(PackedVector2Array([
		Vector2(px + 1.0, top + 2), Vector2(px + 26, top + 8),
		Vector2(px + 18, top + 15), Vector2(px + 26, top + 22), Vector2(px + 1.0, top + 19),
	]), INK)
	_pawn(w * 0.52, hz + 3, 1.5)
	_pawn(w * 0.64, hz + 6, 1.35)
	_pawn(w * 0.76, hz + 2, 1.2)


func _scene_night(w: float, h: float, hz: float) -> void:
	var mx: float = w * 0.76
	var my: float = h * 0.26
	draw_circle(Vector2(mx, my), 11.0, Color(0.93, 0.92, 0.82, 0.92))
	draw_circle(Vector2(mx + 4.5, my - 3.0), 10.0, accent.darkened(0.58))
	# treeline
	for i in range(7):
		var tx: float = w * (0.04 + i * 0.145)
		var th: float = 16.0 + float((i * 7) % 11)
		draw_colored_polygon(PackedVector2Array([
			Vector2(tx - 7, hz + 2), Vector2(tx, hz - th), Vector2(tx + 7, hz + 2),
		]), INK)
	# the figure, crouched and running
	draw_colored_polygon(PackedVector2Array([
		Vector2(w * 0.3 - 11, h - 6), Vector2(w * 0.3 - 7, hz - 6),
		Vector2(w * 0.3 + 5, hz - 9), Vector2(w * 0.3 + 11, h - 6),
	]), INK)
	draw_circle(Vector2(w * 0.3 - 1, hz - 13), 5.4, INK)


func _scene_bow(w: float, h: float, hz: float) -> void:
	var cx: float = w * 0.36
	var cy: float = h * 0.46
	var pts := PackedVector2Array()
	for i in range(17):
		var a: float = lerpf(-1.25, 1.25, float(i) / 16.0)
		pts.append(Vector2(cx + cos(a) * 15.0, cy + sin(a) * 30.0))
	for i in range(pts.size() - 1):
		draw_line(pts[i], pts[i + 1], INK, 4.5)
	draw_line(pts[0], pts[pts.size() - 1], INK, 1.6)
	draw_line(Vector2(cx + 4, cy), Vector2(w * 0.86, cy), INK, 2.6)
	draw_colored_polygon(PackedVector2Array([
		Vector2(w * 0.93, cy), Vector2(w * 0.84, cy - 5.5), Vector2(w * 0.84, cy + 5.5),
	]), INK)
	for i in range(5):
		var gx: float = w * (0.1 + i * 0.2)
		draw_line(Vector2(gx, hz + 9), Vector2(gx - 3, hz + 2), INK, 1.6)
		draw_line(Vector2(gx, hz + 9), Vector2(gx + 3, hz + 1), INK, 1.6)


func _scene_temple(w: float, h: float, hz: float) -> void:
	var bw: float = w * 0.56
	var bx: float = (w - bw) * 0.5
	var base: float = hz + 4.0
	var top: float = h * 0.34
	draw_rect(Rect2(bx - 7, base - 5, bw + 14, 7), INK)
	var n := 5
	for i in range(n):
		var px: float = bx + 6 + (bw - 12) * float(i) / float(n - 1)
		draw_rect(Rect2(px - 3.4, top + 8, 6.8, base - 5 - (top + 8)), INK)
	draw_rect(Rect2(bx - 5, top + 2, bw + 10, 7), INK)
	draw_colored_polygon(PackedVector2Array([
		Vector2(bx - 9, top + 2), Vector2(bx + bw + 9, top + 2), Vector2(w * 0.5, top - 15),
	]), INK)


func _scene_sling(w: float, h: float, hz: float) -> void:
	var fx: float = w * 0.34
	draw_colored_polygon(PackedVector2Array([
		Vector2(fx - 10, hz + 8), Vector2(fx - 6, hz - 20),
		Vector2(fx + 6, hz - 20), Vector2(fx + 10, hz + 8),
	]), INK)
	draw_circle(Vector2(fx, hz - 26), 6.0, INK)
	# the sling, whipping overhead
	var pts := PackedVector2Array()
	for i in range(15):
		var a: float = lerpf(PI * 1.15, PI * 2.0, float(i) / 14.0)
		pts.append(Vector2(fx + 10 + cos(a) * 26.0, hz - 30 + sin(a) * 17.0))
	for i in range(pts.size() - 1):
		draw_line(pts[i], pts[i + 1], INK, 2.2)
	draw_circle(pts[pts.size() - 1], 4.6, INK)
	for i in range(4):
		var sx: float = w * (0.62 + i * 0.1)
		draw_circle(Vector2(sx, hz + 10 + float((i * 5) % 7)), 2.6, INK)


func _scene_fort(w: float, h: float, hz: float) -> void:
	var base: float = hz + 6.0
	var top: float = h * 0.38
	draw_rect(Rect2(w * 0.2, top, w * 0.6, base - top), INK)
	for i in range(6):
		var mx: float = w * 0.2 + w * 0.6 * float(i) / 5.5
		draw_rect(Rect2(mx, top - 8, w * 0.062, 9), INK)
	draw_rect(Rect2(w * 0.44, base - 16, w * 0.12, 16), accent.darkened(0.86))
	# earthworks in front
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, h), Vector2(0, h - 8), Vector2(w * 0.3, h - 15),
		Vector2(w * 0.7, h - 12), Vector2(w, h - 18), Vector2(w, h),
	]), INK)


func _scene_war(w: float, h: float, hz: float) -> void:
	var px: float = w * 0.22
	var top: float = h * 0.2
	draw_rect(Rect2(px - 1.4, top, 3.0, hz + 6 - top), INK)
	draw_colored_polygon(PackedVector2Array([
		Vector2(px + 1.4, top + 1), Vector2(px + 30, top + 8),
		Vector2(px + 21, top + 16), Vector2(px + 30, top + 25), Vector2(px + 1.4, top + 21),
	]), INK)
	for row in range(2):
		for col in range(4):
			_pawn(w * 0.52 + col * (w * 0.11), hz + 2 + row * 11.0, 1.0 + row * 0.18)


func _scene_ship(w: float, h: float, hz: float) -> void:
	var cx: float = w * 0.5
	var deck: float = hz - 2.0
	draw_line(Vector2(cx, deck), Vector2(cx, h * 0.14), INK, 3.0)
	draw_colored_polygon(PackedVector2Array([
		Vector2(cx + 2, h * 0.17), Vector2(cx + 27, deck - 6), Vector2(cx + 2, deck - 6),
	]), INK)
	draw_colored_polygon(PackedVector2Array([
		Vector2(cx - 2, h * 0.26), Vector2(cx - 23, deck - 6), Vector2(cx - 2, deck - 6),
	]), INK)
	draw_colored_polygon(PackedVector2Array([
		Vector2(cx - 34, deck - 6), Vector2(cx + 34, deck - 6),
		Vector2(cx + 22, deck + 8), Vector2(cx - 22, deck + 8),
	]), INK)
	for i in range(4):
		var y: float = hz + 5 + i * 6.0
		var prev := Vector2(0, y)
		var x := 0.0
		while x <= w:
			var p := Vector2(x, y + sin(x * 0.17 + i * 1.3) * 2.4)
			draw_line(prev, p, INK.lerp(accent.darkened(0.7), 0.25 + i * 0.16), 2.0)
			prev = p
			x += 5.0
