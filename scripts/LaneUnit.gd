extends Node2D

signal died(unit: Node)

const INK := Color(0.07, 0.06, 0.08, 1)

var team: int = 0          # 0 = player (moves right), 1 = enemy (moves left)
var kind: String = "sword"
var hp: float = 40.0
var max_hp: float = 40.0
var damage: float = 7.0
var attack_range: float = 34.0
var attack_cooldown: float = 0.8
var move_speed: float = 52.0
var is_ranged: bool = false
var buff: float = 1.0

var cd: float = 0.0
var walk_phase: float = 0.0
var attacking: bool = false
var swing: float = 0.0
var flash: float = 0.0
var arrows_root: Node = null
var dead: bool = false


func configure(p_team: int, p_kind: String, stats: Dictionary) -> void:
	team = p_team
	kind = p_kind
	max_hp = stats["hp"]
	hp = max_hp
	damage = stats["dmg"]
	attack_range = stats["range"]
	attack_cooldown = stats["atk"]
	move_speed = stats["spd"]
	is_ranged = stats.get("ranged", false)
	add_to_group("lane_unit")
	add_to_group("lane_team_%d" % team)


func dir() -> float:
	return 1.0 if team == 0 else -1.0


func _process(delta: float) -> void:
	if dead:
		return
	cd = maxf(0.0, cd - delta)
	swing = maxf(0.0, swing - delta * 4.0)
	flash = maxf(0.0, flash - delta * 5.0)

	var target = _find_target()
	if target == null:
		attacking = false
		position.x += dir() * move_speed * delta
		walk_phase += delta * 8.0
	else:
		attacking = true
		if cd <= 0.0:
			cd = attack_cooldown
			swing = 1.0
			if is_ranged:
				_shoot(target)
			else:
				target.take_hit(damage * buff)
	buff = 1.0
	queue_redraw()


func _find_target():
	var best = null
	var best_d: float = attack_range
	for u in get_tree().get_nodes_in_group("lane_unit"):
		if not is_instance_valid(u) or u.dead or u.team == team:
			continue
		var dx: float = (u.position.x - position.x) * dir()
		if dx < -6.0:
			continue
		var d: float = absf(u.position.x - position.x)
		if d <= best_d:
			best_d = d
			best = u
	if best != null:
		return best
	for f in get_tree().get_nodes_in_group("lane_fort"):
		if not is_instance_valid(f) or f.team == team or f.hp <= 0.0:
			continue
		var dxf: float = (f.position.x - position.x) * dir()
		if dxf >= -6.0 and absf(f.position.x - position.x) <= attack_range + 26.0:
			return f
	return null


func _shoot(target) -> void:
	if arrows_root == null:
		return
	var arrow := preload("res://scenes/LaneArrow.tscn").instantiate()
	arrow.position = position + Vector2(dir() * 14.0, -26.0)
	arrow.setup(team, damage * buff, target.position + Vector2(0, -20.0))
	arrows_root.add_child(arrow)


func take_hit(amount: float) -> void:
	if dead:
		return
	hp -= amount
	flash = 1.0
	if hp <= 0.0:
		dead = true
		died.emit(self)
		queue_free()


func apply_buff(mult: float) -> void:
	buff = maxf(buff, mult)


func _body_color() -> Color:
	var base: Color
	if team == 0:
		base = Color(0.35, 0.6, 0.95, 1)
		if kind == "captain":
			base = Color(0.55, 0.8, 1.0, 1)
		elif kind == "shield":
			base = Color(0.4, 0.75, 0.8, 1)
	else:
		base = Color(0.9, 0.35, 0.3, 1)
		if kind == "captain":
			base = Color(1.0, 0.5, 0.35, 1)
	if flash > 0.0:
		base = base.lerp(Color(1, 1, 1, 1), flash)
	return base


func _draw() -> void:
	var f := dir()
	var col := _body_color()
	var step: float = sin(walk_phase) * (5.0 if not attacking else 0.0)

	# legs
	draw_line(Vector2(0, -14), Vector2(-4 + step, 0), INK, 3.5)
	draw_line(Vector2(0, -14), Vector2(4 - step, 0), INK, 3.5)
	# torso
	draw_line(Vector2(0, -14), Vector2(0, -34), col, 5.0)
	# head
	draw_circle(Vector2(0, -41), 6.5, INK)
	draw_circle(Vector2(0, -41), 5.0, col)

	var arm_y: float = -28.0
	var reach: float = 12.0 + swing * 9.0

	match kind:
		"sword":
			draw_line(Vector2(0, arm_y), Vector2(f * reach, arm_y - 2), col, 3.5)
			draw_line(Vector2(f * reach, arm_y - 2), Vector2(f * (reach + 18), arm_y - 12 - swing * 6.0), Color(0.88, 0.9, 0.95, 1), 3.5)
		"spear":
			draw_line(Vector2(0, arm_y), Vector2(f * reach, arm_y), col, 3.5)
			draw_line(Vector2(f * (reach - 10), arm_y - 4), Vector2(f * (reach + 34), arm_y - 8), Color(0.72, 0.6, 0.4, 1), 3.0)
			var tip := PackedVector2Array([
				Vector2(f * (reach + 42), arm_y - 8), Vector2(f * (reach + 32), arm_y - 13),
				Vector2(f * (reach + 32), arm_y - 3),
			])
			draw_colored_polygon(tip, Color(0.88, 0.9, 0.95, 1))
		"shield":
			draw_line(Vector2(0, arm_y), Vector2(f * reach, arm_y), col, 3.5)
			draw_line(Vector2(f * reach, arm_y - 2), Vector2(f * (reach + 12), arm_y - 8), Color(0.88, 0.9, 0.95, 1), 3.0)
			var sh := PackedVector2Array([
				Vector2(f * 12, -36), Vector2(f * 20, -30),
				Vector2(f * 20, -12), Vector2(f * 12, -6),
			])
			draw_colored_polygon(sh, INK)
			var sh_in := PackedVector2Array([
				Vector2(f * 13, -34), Vector2(f * 18, -29),
				Vector2(f * 18, -13), Vector2(f * 13, -8),
			])
			draw_colored_polygon(sh_in, col.lightened(0.15))
		"archer":
			draw_line(Vector2(0, arm_y), Vector2(f * 12, arm_y - 4), col, 3.5)
			var pts := PackedVector2Array()
			for i in range(9):
				var t: float = float(i) / 8.0
				var a: float = lerpf(-1.0, 1.0, t)
				pts.append(Vector2(f * (14.0 + cos(a) * 5.0), arm_y - 4 + sin(a) * 13.0))
			for i in range(pts.size() - 1):
				draw_line(pts[i], pts[i + 1], Color(0.55, 0.38, 0.18, 1), 2.5)
			draw_line(pts[0], pts[pts.size() - 1], Color(0.9, 0.88, 0.8, 1), 1.5)
		"captain":
			draw_line(Vector2(0, arm_y), Vector2(f * reach, arm_y - 4), col, 4.0)
			draw_line(Vector2(f * reach, arm_y - 4), Vector2(f * (reach + 22), arm_y - 18 - swing * 8.0), Color(1, 0.92, 0.6, 1), 4.0)
			draw_line(Vector2(0, -47), Vector2(f * -6, -56), Color(1, 0.85, 0.3, 1), 3.0)

	# hp pip
	var w := 22.0
	var frac: float = clampf(hp / max_hp, 0.0, 1.0)
	draw_rect(Rect2(-w * 0.5, -56, w, 4), Color(0, 0, 0, 0.55))
	draw_rect(Rect2(-w * 0.5, -56, w * frac, 4), Color(0.4, 0.95, 0.4, 1) if team == 0 else Color(0.95, 0.5, 0.4, 1))
