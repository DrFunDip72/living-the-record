extends Node2D

var team: int = 0
var damage: float = 6.0
var velocity: Vector2 = Vector2.ZERO
var gravity: float = 260.0
var spent: bool = false


func setup(p_team: int, p_damage: float, target_pos: Vector2) -> void:
	team = p_team
	damage = p_damage
	var to: Vector2 = target_pos - position
	var t: float = clampf(absf(to.x) / 420.0, 0.25, 1.2)
	velocity = Vector2(to.x / t, (to.y - 0.5 * gravity * t * t) / t)


func _process(delta: float) -> void:
	if spent:
		return
	velocity.y += gravity * delta
	position += velocity * delta
	rotation = velocity.angle()

	for u in get_tree().get_nodes_in_group("lane_unit"):
		if not is_instance_valid(u) or u.dead or u.team == team:
			continue
		if position.distance_to(u.position + Vector2(0, -22)) < 18.0:
			spent = true
			u.take_hit(damage)
			queue_free()
			return

	for f in get_tree().get_nodes_in_group("lane_fort"):
		if not is_instance_valid(f) or f.team == team or f.dead:
			continue
		if absf(position.x - f.position.x) < 30.0 and position.y > -120.0:
			spent = true
			f.take_hit(damage)
			queue_free()
			return

	if position.y > 396.0 or position.x < -60.0 or position.x > 1020.0:
		queue_free()
	queue_redraw()


func _draw() -> void:
	draw_line(Vector2(-14, 0), Vector2(6, 0), Color(0.5, 0.36, 0.18, 1), 2.5)
	var head := PackedVector2Array([Vector2(11, 0), Vector2(4, -3), Vector2(4, 3)])
	draw_colored_polygon(head, Color(0.88, 0.9, 0.95, 1))
