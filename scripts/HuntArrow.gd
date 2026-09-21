extends Node2D

signal resolved(kind: String, pos: Vector2, points: int)

# The arrow flies to exactly where you aimed. No drop to guess -- but it takes time
# to get there, so you lead a moving animal.

var from: Vector2 = Vector2.ZERO
var to: Vector2 = Vector2.ZERO
var duration: float = 0.4
var end_scale: float = 0.5
var t: float = 0.0
var spent: bool = false


func launch(p_from: Vector2, p_to: Vector2, p_duration: float, p_end_scale: float) -> void:
	from = p_from
	to = p_to
	duration = maxf(p_duration, 0.05)
	end_scale = p_end_scale
	position = from
	rotation = (to - from).angle()


func _process(delta: float) -> void:
	if spent:
		return
	t = minf(t + delta / duration, 1.0)
	# fast off the string, easing as it shrinks into the distance
	var k: float = 1.0 - pow(1.0 - t, 1.6)
	var prev := position
	position = from.lerp(to, k)
	if position.distance_to(prev) > 0.1:
		rotation = (position - prev).angle()
	var sc: float = lerpf(1.1, end_scale, k)
	scale = Vector2(sc, sc)
	queue_redraw()

	if t >= 1.0:
		spent = true
		for a in get_tree().get_nodes_in_group("hunt_animal"):
			if not is_instance_valid(a):
				continue
			var kind: String = a.hit_test(to)
			if kind != "":
				var was_wounded: bool = a.wounded
				var pts: int = a.points if (kind == "vital" or was_wounded) else 0
				a.on_hit(kind)
				resolved.emit("vital" if (kind == "vital" or was_wounded) else "body", to, pts)
				queue_free()
				return
		resolved.emit("ground", to, 0)
		queue_free()


func _draw() -> void:
	draw_line(Vector2(-26, 0), Vector2(10, 0), Color(0.5, 0.35, 0.18, 1), 3.0)
	var head := PackedVector2Array([Vector2(16, 0), Vector2(6, -4), Vector2(6, 4)])
	draw_colored_polygon(head, Color(0.85, 0.86, 0.9, 1))
	draw_line(Vector2(-26, 0), Vector2(-20, -5), Color(0.9, 0.9, 0.85, 1), 2.0)
	draw_line(Vector2(-26, 0), Vector2(-20, 5), Color(0.9, 0.9, 0.85, 1), 2.0)
