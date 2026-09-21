extends Node2D

signal destroyed(team: int)

const INK := Color(0.07, 0.06, 0.08, 1)

var team: int = 0
var hp: float = 120.0
var max_hp: float = 120.0
var crossbow_level: int = 1
var crossbow_range: float = 300.0
var arrows_root: Node = null
var cd: float = 0.0
var flash: float = 0.0
var dead: bool = false


func _ready() -> void:
	add_to_group("lane_fort")


func dir() -> float:
	return 1.0 if team == 0 else -1.0


func _process(delta: float) -> void:
	if dead:
		return
	flash = maxf(0.0, flash - delta * 5.0)
	cd = maxf(0.0, cd - delta)
	if cd <= 0.0:
		var target = _find_target()
		if target != null:
			cd = maxf(0.35, 1.5 - crossbow_level * 0.22)
			_shoot(target)
	queue_redraw()


func _find_target():
	var best = null
	var best_d: float = crossbow_range
	for u in get_tree().get_nodes_in_group("lane_unit"):
		if not is_instance_valid(u) or u.dead or u.team == team:
			continue
		var d: float = absf(u.position.x - position.x)
		if d <= best_d:
			best_d = d
			best = u
	return best


func _shoot(target) -> void:
	if arrows_root == null:
		return
	var arrow := preload("res://scenes/LaneArrow.tscn").instantiate()
	arrow.position = position + Vector2(dir() * 12.0, -86.0)
	arrow.setup(team, 4.0 + crossbow_level * 3.0, target.position + Vector2(0, -22.0))
	arrows_root.add_child(arrow)


func take_hit(amount: float) -> void:
	if dead:
		return
	hp -= amount
	flash = 1.0
	if hp <= 0.0:
		hp = 0.0
		dead = true
		destroyed.emit(team)
	queue_redraw()


func _draw() -> void:
	var f := dir()
	var base: Color = Color(0.5, 0.62, 0.8, 1) if team == 0 else Color(0.72, 0.42, 0.38, 1)
	if flash > 0.0:
		base = base.lerp(Color(1, 1, 1, 1), flash * 0.7)

	var body := PackedVector2Array([
		Vector2(-34, 0), Vector2(34, 0), Vector2(28, -92), Vector2(-28, -92),
	])
	draw_colored_polygon(body, INK)
	var body_in := PackedVector2Array([
		Vector2(-29, -4), Vector2(29, -4), Vector2(24, -88), Vector2(-24, -88),
	])
	draw_colored_polygon(body_in, base)

	for i in range(4):
		var bx: float = -30.0 + i * 18.0
		draw_rect(Rect2(bx, -110, 13, 20), INK)
		draw_rect(Rect2(bx + 2, -107, 9, 15), base.darkened(0.15))

	draw_rect(Rect2(-9, -46, 18, 46), Color(0.16, 0.12, 0.1, 1))

	# crossbow on top
	draw_line(Vector2(0, -116), Vector2(f * 22, -120), Color(0.4, 0.3, 0.16, 1), 5.0)
	draw_line(Vector2(f * 12, -110), Vector2(f * 12, -130), Color(0.85, 0.87, 0.92, 1), 3.0)
	for i in range(crossbow_level):
		draw_circle(Vector2(-18 + i * 9, -126), 3.0, Color(1, 0.85, 0.3, 1))
