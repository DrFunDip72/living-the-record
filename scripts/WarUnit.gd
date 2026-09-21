extends Node2D

signal died(unit: Node)

const INK := Color(0.07, 0.06, 0.08, 1)

var team: int = 0            # 0 = Nephite (player), 1 = Lamanite
var kind: String = "sword"
var hp: float = 30.0
var max_hp: float = 30.0
var damage: float = 6.0
var attack_range: float = 30.0
var attack_cd: float = 0.9
var speed: float = 58.0

var cd: float = 0.0
var dead: bool = false
var concealed: bool = false      # hidden in cover until it strikes
var ambush_ready: bool = false   # first strike from concealment hits hard
var move_target = null           # Vector2 or null
var path_points: Array = []
var flash: float = 0.0
var swing: float = 0.0
var phase: float = 0.0
var selected: bool = false
var arrows_root: Node = null
var aggressive: bool = false     # ordered to charge: seek enemies anywhere
var guard_radius: float = 0.0    # >0: defend this spot, chase intruders
var damage_taken_mult: float = 1.0  # <1 while behind city walls

const AMBUSH_RANGE := 115.0


func configure(p_team: int, p_kind: String, stats: Dictionary) -> void:
	team = p_team
	kind = p_kind
	max_hp = stats["hp"]
	hp = max_hp
	damage = stats["dmg"]
	attack_range = stats["range"]
	attack_cd = stats["atk"]
	speed = stats["spd"]
	phase = randf() * TAU
	add_to_group("war_unit")
	add_to_group("war_team_%d" % team)


func set_concealed(v: bool) -> void:
	concealed = v
	ambush_ready = v
	queue_redraw()


func order_move(p: Vector2) -> void:
	move_target = p
	path_points = []


func set_patrol(points: Array) -> void:
	path_points = points.duplicate()
	if not path_points.is_empty():
		move_target = path_points.pop_front()


func _process(delta: float) -> void:
	if dead:
		return
	cd = maxf(0.0, cd - delta)
	swing = maxf(0.0, swing - delta * 5.0)
	flash = maxf(0.0, flash - delta * 5.0)
	phase += delta

	var target = _find_target()

	if target != null:
		if concealed:
			spring()
		var to: Vector2 = target.global_position - global_position
		if to.length() > attack_range:
			position += to.normalized() * speed * delta
		elif cd <= 0.0:
			cd = attack_cd
			swing = 1.0
			var dmg: float = damage * (2.0 if ambush_ready else 1.0)
			ambush_ready = false
			if kind == "archer" and arrows_root != null:
				_shoot(target, dmg)
			else:
				target.take_hit(dmg)
	elif move_target != null:
		var to2: Vector2 = move_target - global_position
		if to2.length() < 8.0:
			if path_points.is_empty():
				move_target = null
			else:
				move_target = path_points.pop_front()
		else:
			position += to2.normalized() * speed * delta

	queue_redraw()


func spring() -> void:
	if not concealed:
		return
	set_concealed(false)
	ambush_ready = true
	aggressive = true
	# the rest of the hidden company springs with you
	for u in get_tree().get_nodes_in_group("war_team_%d" % team):
		if is_instance_valid(u) and u != self and u.concealed and u.global_position.distance_to(global_position) < 170.0:
			u.spring()


func charge() -> void:
	aggressive = true
	if concealed:
		spring()


func _find_target():
	var best = null
	var best_d: float = attack_range * 3.2
	if concealed:
		best_d = maxf(AMBUSH_RANGE, attack_range)
	elif aggressive:
		best_d = 420.0
	elif guard_radius > 0.0:
		best_d = guard_radius
	for u in get_tree().get_nodes_in_group("war_unit"):
		if not is_instance_valid(u) or u.dead or u.team == team:
			continue
		var d: float = global_position.distance_to(u.global_position)
		if d < best_d:
			best_d = d
			best = u
	return best


func _shoot(target, dmg: float) -> void:
	var arrow := preload("res://scenes/LaneArrow.tscn").instantiate()
	arrow.position = global_position
	arrow.gravity = 0.0
	arrow.max_y = 600.0
	arrow.target_group = "war_unit"
	arrow.hit_offset = Vector2.ZERO
	arrow.setup(team, dmg, target.global_position)
	arrow.velocity = (target.global_position - global_position).normalized() * 430.0
	arrows_root.add_child(arrow)


func take_hit(amount: float) -> void:
	if dead:
		return
	hp -= amount * damage_taken_mult
	flash = 1.0
	if concealed:
		spring()
	if not aggressive:
		aggressive = true
		path_points = []
		move_target = null
		for u in get_tree().get_nodes_in_group("war_team_%d" % team):
			if is_instance_valid(u) and u != self and not u.concealed and u.global_position.distance_to(global_position) < 220.0:
				u.aggressive = true
				u.path_points = []
				u.move_target = null
	if hp <= 0.0:
		dead = true
		died.emit(self)
		queue_free()


func _base_color() -> Color:
	var c: Color
	if team == 0:
		c = Color(0.35, 0.58, 0.95, 1)
		if kind == "archer":
			c = Color(0.4, 0.78, 0.7, 1)
		elif kind == "spear":
			c = Color(0.5, 0.62, 0.95, 1)
	else:
		c = Color(0.9, 0.35, 0.3, 1)
		if kind == "archer":
			c = Color(0.9, 0.55, 0.3, 1)
		elif kind == "spear":
			c = Color(0.85, 0.42, 0.38, 1)
	if flash > 0.0:
		c = c.lerp(Color(1, 1, 1, 1), flash)
	return c


func _draw() -> void:
	var a: float = 0.4 if concealed else 1.0
	var col := _base_color()
	col.a = a
	var wob: float = sin(phase * 3.0) * 1.2

	if selected:
		draw_arc(Vector2(0, 2), 15.0, 0.0, TAU, 20, Color(0.6, 1.0, 0.6, 0.9), 2.0)

	draw_circle(Vector2(0, 5), 9.0, Color(0, 0, 0, 0.22 * a))
	# body
	var body := PackedVector2Array([
		Vector2(-8, 8 + wob), Vector2(-6, -4), Vector2(6, -4), Vector2(8, 8 + wob),
	])
	var ink := INK
	ink.a = a
	draw_colored_polygon(body, ink)
	var body_in := PackedVector2Array([
		Vector2(-6, 6 + wob), Vector2(-4, -2), Vector2(4, -2), Vector2(6, 6 + wob),
	])
	draw_colored_polygon(body_in, col)
	draw_circle(Vector2(0, -8), 5.5, ink)
	draw_circle(Vector2(0, -8), 4.0, col.lightened(0.2))

	# weapon
	var swing_off: float = swing * 6.0
	match kind:
		"spear":
			draw_line(Vector2(6, -2), Vector2(24 + swing_off, -6), Color(0.72, 0.6, 0.4, a), 2.5)
			draw_colored_polygon(PackedVector2Array([
				Vector2(30 + swing_off, -6), Vector2(23 + swing_off, -10), Vector2(23 + swing_off, -2)]),
				Color(0.88, 0.9, 0.95, a))
		"archer":
			var pts := PackedVector2Array()
			for i in range(7):
				var t: float = float(i) / 6.0
				var ang: float = lerpf(-1.0, 1.0, t)
				pts.append(Vector2(10 + cos(ang) * 3.0, -2 + sin(ang) * 9.0))
			for i in range(pts.size() - 1):
				draw_line(pts[i], pts[i + 1], Color(0.55, 0.38, 0.18, a), 2.0)
		_:
			draw_line(Vector2(6, -2), Vector2(15 + swing_off, -10 - swing_off), Color(0.88, 0.9, 0.95, a), 2.5)

	# hp pip
	if hp < max_hp:
		var w := 18.0
		draw_rect(Rect2(-w * 0.5, -22, w, 3), Color(0, 0, 0, 0.5 * a))
		draw_rect(Rect2(-w * 0.5, -22, w * clampf(hp / max_hp, 0, 1), 3),
			Color(0.4, 0.95, 0.4, a) if team == 0 else Color(0.95, 0.5, 0.4, a))
