extends Node2D

signal resolved(kind: String, pos: Vector2, points: int)

const GRAVITY := 560.0

var velocity: Vector2 = Vector2.ZERO
var spent: bool = false


func _process(delta: float) -> void:
	if spent:
		return
	velocity.y += GRAVITY * delta
	position += velocity * delta
	rotation = velocity.angle()
	queue_redraw()

	for a in get_tree().get_nodes_in_group("hunt_animal"):
		if not is_instance_valid(a):
			continue
		var kind: String = a.hit_test(global_position)
		if kind != "":
			spent = true
			var pts: int = a.points if kind == "vital" else 0
			a.on_hit(kind)
			resolved.emit(kind, global_position, pts)
			queue_free()
			return

	if position.y > 505.0 or position.x < -120.0 or position.x > 1090.0:
		spent = true
		resolved.emit("ground", global_position, 0)
		queue_free()


func _draw() -> void:
	draw_line(Vector2(-26, 0), Vector2(10, 0), Color(0.5, 0.35, 0.18, 1), 3.0)
	var head := PackedVector2Array([Vector2(16, 0), Vector2(6, -4), Vector2(6, 4)])
	draw_colored_polygon(head, Color(0.85, 0.86, 0.9, 1))
	draw_line(Vector2(-26, 0), Vector2(-20, -5), Color(0.9, 0.9, 0.85, 1), 2.0)
	draw_line(Vector2(-26, 0), Vector2(-20, 5), Color(0.9, 0.9, 0.85, 1), 2.0)
