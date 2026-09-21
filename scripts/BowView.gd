extends Node2D

const INK := Color(0.09, 0.07, 0.05, 1)
const WOOD := Color(0.48, 0.32, 0.15, 1)

var power: float = 0.0
var nocked: bool = true


func set_state(p_power: float, p_nocked: bool) -> void:
	power = clampf(p_power, 0.0, 1.0)
	nocked = p_nocked
	queue_redraw()


func _draw() -> void:
	var pull: float = power * 30.0
	var limb_top := Vector2(6, -46)
	var limb_bot := Vector2(6, 46)

	# limbs (two curved halves bulging forward)
	var top_pts := PackedVector2Array()
	var bot_pts := PackedVector2Array()
	var steps := 10
	for i in range(steps + 1):
		var t: float = float(i) / float(steps)
		var y: float = lerpf(0.0, -46.0, t)
		var x: float = 10.0 + sin(t * PI) * 12.0
		top_pts.append(Vector2(x, y))
		bot_pts.append(Vector2(x, -y))
	for i in range(top_pts.size() - 1):
		draw_line(top_pts[i], top_pts[i + 1], INK, 9.0)
		draw_line(bot_pts[i], bot_pts[i + 1], INK, 9.0)
	for i in range(top_pts.size() - 1):
		draw_line(top_pts[i], top_pts[i + 1], WOOD, 5.0)
		draw_line(bot_pts[i], bot_pts[i + 1], WOOD, 5.0)

	# grip
	draw_line(Vector2(10, -10), Vector2(10, 10), INK, 12.0)
	draw_line(Vector2(10, -10), Vector2(10, 10), Color(0.3, 0.22, 0.12, 1), 8.0)

	# string
	var nock := Vector2(10 - pull, 0)
	var string_col := Color(0.92, 0.9, 0.82, 1)
	draw_line(limb_top, nock, string_col, 2.0)
	draw_line(limb_bot, nock, string_col, 2.0)

	# nocked arrow
	if nocked:
		draw_line(nock, nock + Vector2(52, 0), Color(0.5, 0.35, 0.18, 1), 3.0)
		var head := PackedVector2Array([
			nock + Vector2(60, 0), nock + Vector2(50, -4), nock + Vector2(50, 4),
		])
		draw_colored_polygon(head, Color(0.85, 0.86, 0.9, 1))
		draw_line(nock, nock + Vector2(7, -5), string_col, 2.0)
		draw_line(nock, nock + Vector2(7, 5), string_col, 2.0)
