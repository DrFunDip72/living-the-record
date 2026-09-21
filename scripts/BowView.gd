extends Node2D

# First-person bow: held upright in your left hand, arrow nocked and pointing at your sight.
# Drawn in screen space (node sits at the origin, unscaled).

const INK := Color(0.09, 0.07, 0.05, 1)
const WOOD := Color(0.5, 0.33, 0.15, 1)
const WOOD_HI := Color(0.68, 0.48, 0.25, 1)
const STRING_COL := Color(0.92, 0.9, 0.82, 1)
const SKIN := Color(0.62, 0.44, 0.3, 1)

var power: float = 0.0
var aim: Vector2 = Vector2(480, 300)


func set_state(p_power: float, p_aim: Vector2) -> void:
	power = clampf(p_power, 0.0, 1.0)
	aim = p_aim
	queue_redraw()


# the bow follows your aim a little, the way your arm would
func grip() -> Vector2:
	return Vector2(660.0 + (aim.x - 480.0) * 0.2, 478.0 + (aim.y - 300.0) * 0.1)


func tip() -> Vector2:
	var g := grip()
	return g + (aim - g).normalized() * 16.0


func _draw() -> void:
	var g := grip()
	var t := tip()
	var dir: Vector2 = (aim - t).normalized()
	var nock: Vector2 = t - dir * (125.0 + power * 150.0)

	# limbs: a tall upright bow, slightly canted, running off the bottom of the screen
	var cant := -0.1
	var top_end: Vector2 = g + Vector2(0, -215).rotated(cant)
	var bot_end: Vector2 = g + Vector2(0, 215).rotated(cant)
	var top_pts := PackedVector2Array()
	var bot_pts := PackedVector2Array()
	var steps := 14
	var flex: float = 26.0 + power * 16.0
	for i in range(steps + 1):
		var k: float = float(i) / float(steps)
		var bulge: float = sin(k * PI * 0.5) * flex * (1.0 - k * 0.35)
		top_pts.append(g.lerp(top_end, k) + Vector2(-bulge, 0).rotated(cant))
		bot_pts.append(g.lerp(bot_end, k) + Vector2(-bulge, 0).rotated(cant))

	# string, pulled back toward you as you draw
	draw_line(top_pts[steps], nock, STRING_COL, 2.0)
	draw_line(bot_pts[steps], nock, STRING_COL, 2.0)

	for i in range(steps):
		var w: float = lerpf(15.0, 7.0, float(i) / steps)
		draw_line(top_pts[i], top_pts[i + 1], INK, w + 4.0)
		draw_line(bot_pts[i], bot_pts[i + 1], INK, w + 4.0)
	for i in range(steps):
		var w2: float = lerpf(15.0, 7.0, float(i) / steps)
		draw_line(top_pts[i], top_pts[i + 1], WOOD, w2)
		draw_line(bot_pts[i], bot_pts[i + 1], WOOD, w2)
		draw_line(top_pts[i] + Vector2(-2, 0), top_pts[i + 1] + Vector2(-2, 0), WOOD_HI, 2.0)
	draw_circle(top_pts[steps], 5.0, INK)

	# the arrow: thick near your eye, thin at the rest, pointing where you aim
	var side := Vector2(-dir.y, dir.x)
	var shaft := PackedVector2Array([
		nock + side * 4.5, t + side * 1.6, t - side * 1.6, nock - side * 4.5,
	])
	draw_colored_polygon(shaft, INK)
	var shaft_in := PackedVector2Array([
		nock + side * 3.0, t + side * 0.9, t - side * 0.9, nock - side * 3.0,
	])
	draw_colored_polygon(shaft_in, Color(0.62, 0.45, 0.25, 1))
	# fletching
	var f0: Vector2 = nock + dir * 8.0
	var f1: Vector2 = nock + dir * 40.0
	draw_colored_polygon(PackedVector2Array([f0 + side * 3.0, f1 + side * 2.0, f0 + side * 16.0]), Color(0.85, 0.82, 0.74, 1))
	draw_colored_polygon(PackedVector2Array([f0 - side * 3.0, f1 - side * 2.0, f0 - side * 16.0]), Color(0.78, 0.3, 0.22, 1))
	# head, resting on your bow hand
	draw_colored_polygon(PackedVector2Array([t + dir * 9.0, t - dir * 3.0 + side * 4.0, t - dir * 3.0 - side * 4.0]), Color(0.86, 0.87, 0.9, 1))

	# bow hand around the grip
	draw_circle(g + Vector2(4, 6), 17.0, INK)
	draw_circle(g + Vector2(4, 6), 14.0, SKIN)
	draw_line(g + Vector2(-8, -2), g + Vector2(14, -2), SKIN.darkened(0.25), 2.0)
	draw_line(g + Vector2(-8, 6), g + Vector2(15, 6), SKIN.darkened(0.25), 2.0)
	draw_line(g + Vector2(-8, 14), g + Vector2(14, 14), SKIN.darkened(0.25), 2.0)

	# drawing hand on the string
	if power > 0.02:
		draw_circle(nock + Vector2(6, 8), 15.0, INK)
		draw_circle(nock + Vector2(6, 8), 12.0, SKIN)
