extends Node2D

@export var length: float = 74.0
@export var color: Color = Color(1, 0.92, 0.5, 0.85)

var aim: float = 0.0
var ready_to_fire: bool = true


func set_state(angle: float, p_ready: bool) -> void:
	aim = angle
	ready_to_fire = p_ready
	queue_redraw()


func _draw() -> void:
	var col: Color = color if ready_to_fire else Color(0.7, 0.7, 0.7, 0.45)
	var dir := Vector2(cos(aim), sin(aim))
	var start := dir * 22.0
	# dashed guide
	var seg := 8.0
	var d := start.length()
	while d < length - 10.0:
		var a := dir * d
		var b := dir * minf(d + seg * 0.55, length - 10.0)
		draw_line(a, b, col, 2.0)
		d += seg
	var tip := dir * length
	var perp := Vector2(-dir.y, dir.x)
	var head := PackedVector2Array([tip, tip - dir * 10.0 + perp * 5.0, tip - dir * 10.0 - perp * 5.0])
	draw_colored_polygon(head, col)
