extends Node2D

signal resolved(kind: String, pos: Vector2, points: int)

const GRAVITY := 190.0
const NEAR_SCALE := 1.15
const FAR_SCALE := 0.34

var velocity: Vector2 = Vector2.ZERO
var travel: float = 0.0      # 0 = at the bow, 1 = far downrange
var travel_rate: float = 0.5
var spent: bool = false


func launch(dir: Vector2, power: float) -> void:
	velocity = dir * (260.0 + power * 340.0)
	travel_rate = 0.42 + power * 0.5
	scale = Vector2(NEAR_SCALE, NEAR_SCALE)


func _process(delta: float) -> void:
	if spent:
		return
	velocity.y += GRAVITY * delta
	position += velocity * delta
	travel = minf(travel + travel_rate * delta, 1.4)
	var sc: float = lerpf(NEAR_SCALE, FAR_SCALE, clampf(travel, 0.0, 1.0))
	scale = Vector2(sc, sc)
	rotation = velocity.angle()
	queue_redraw()

	# a hit needs the arrow to be at the same depth band as the animal
	for a in get_tree().get_nodes_in_group("hunt_animal"):
		if not is_instance_valid(a):
			continue
		if absf(sc - a.current_scale()) > 0.22:
			continue
		var kind: String = a.hit_test(global_position)
		if kind != "":
			spent = true
			var was_wounded: bool = a.wounded
			var pts: int = a.points if (kind == "vital" or was_wounded) else 0
			a.on_hit(kind)
			resolved.emit("vital" if (kind == "vital" or was_wounded) else "body", global_position, pts)
			queue_free()
			return

	if travel >= 1.35 or position.y > 500.0 or position.x < -80.0 or position.x > 1040.0 or position.y < 120.0:
		spent = true
		resolved.emit("ground", global_position, 0)
		queue_free()


func _draw() -> void:
	draw_line(Vector2(-26, 0), Vector2(10, 0), Color(0.5, 0.35, 0.18, 1), 3.0)
	var head := PackedVector2Array([Vector2(16, 0), Vector2(6, -4), Vector2(6, 4)])
	draw_colored_polygon(head, Color(0.85, 0.86, 0.9, 1))
	draw_line(Vector2(-26, 0), Vector2(-20, -5), Color(0.9, 0.9, 0.85, 1), 2.0)
	draw_line(Vector2(-26, 0), Vector2(-20, 5), Color(0.9, 0.9, 0.85, 1), 2.0)
