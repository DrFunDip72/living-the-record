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
var aggressive: bool = false     # enemy only: seek targets far and wide
var guard_radius: float = 0.0    # enemy only: defend this spot, chase intruders
var damage_taken_mult: float = 1.0  # <1 while behind city walls

# player companies only move on orders
var company: int = -1
var order: String = "hold"       # hold | move | attack
var home: Vector2 = Vector2.ZERO
var ambush_run: float = 0.0
var forests: Array = []          # cover a halted company can hide in

const HOLD_REACH := 14.0         # how far past weapon reach a holding man will strike
const HOLD_LEASH := 26.0         # how far a holding man will step off his spot
const SEEN_WHEN_HIDDEN := 40.0   # the enemy only notices hidden men this close


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
	home = position
	add_to_group("war_unit")
	add_to_group("war_team_%d" % team)


func set_concealed(v: bool) -> void:
	concealed = v
	ambush_ready = v
	ambush_run = 0.0
	queue_redraw()


func order_move(p: Vector2) -> void:
	move_target = p
	path_points = []
	if team == 0:
		order = "move"
		# a marching company is out in the open
		if concealed:
			concealed = false
			queue_redraw()


func order_hold() -> void:
	order = "hold"
	move_target = null
	home = position


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

	if team == 0:
		_follow_orders(delta)
	else:
		_enemy_think(delta)
	queue_redraw()


# --- player men: nothing happens without an order ---------------------------

func _follow_orders(delta: float) -> void:
	match order:
		"move":
			# a marching company does not stop to fight
			if move_target == null:
				order_hold()
				return
			var to: Vector2 = move_target - global_position
			if to.length() < 6.0:
				position = move_target
				order_hold()
				for f in forests:
					if (f as Rect2).has_point(position):
						set_concealed(true)
						break
			else:
				position += to.normalized() * speed * delta
		"attack":
			var t = _nearest_foe(INF)
			if t != null:
				_close_and_strike(t, delta)
		_:
			# hold: hidden men stay silent; visible men defend their spot
			if concealed:
				return
			var t2 = _nearest_foe(attack_range + HOLD_REACH + HOLD_LEASH)
			if t2 != null:
				var d: float = global_position.distance_to(t2.global_position)
				if d <= attack_range:
					_strike(t2)
				elif global_position.distance_to(home) < HOLD_LEASH:
					position += (t2.global_position - global_position).normalized() * speed * delta
			elif global_position.distance_to(home) > 3.0:
				position += (home - global_position).normalized() * speed * 0.6 * delta


# --- enemies: march their route, fight what they notice ----------------------

func _enemy_think(delta: float) -> void:
	var target = _find_target()
	if target != null:
		_close_and_strike(target, delta)
	elif move_target != null:
		var to2: Vector2 = move_target - global_position
		if to2.length() < 8.0:
			if path_points.is_empty():
				move_target = null
			else:
				move_target = path_points.pop_front()
		else:
			position += to2.normalized() * speed * delta


func _close_and_strike(target, delta: float) -> void:
	var to: Vector2 = target.global_position - global_position
	if to.length() > attack_range:
		position += to.normalized() * speed * delta
		# surprise only works up close -- a long run gives the enemy time to form up
		if ambush_ready and team == 0:
			ambush_run += speed * delta
			if ambush_run > 110.0:
				ambush_ready = false
	else:
		_strike(target)


func _strike(target) -> void:
	if cd > 0.0:
		return
	if concealed:
		spring()
	cd = attack_cd
	swing = 1.0
	var dmg: float = damage * (2.0 if ambush_ready else 1.0)
	ambush_ready = false
	if kind == "archer" and arrows_root != null:
		_shoot(target, dmg)
	else:
		target.take_hit(dmg)


func spring() -> void:
	if not concealed:
		return
	concealed = false
	ambush_ready = true
	queue_redraw()
	if team == 1:
		aggressive = true
	# the rest of the hidden company is revealed with you
	for u in get_tree().get_nodes_in_group("war_team_%d" % team):
		if not is_instance_valid(u) or u == self or not u.concealed:
			continue
		if (team == 0 and u.company == company) or (team == 1 and u.global_position.distance_to(global_position) < 170.0):
			u.spring()


func charge() -> void:
	order = "attack"
	move_target = null
	if concealed:
		spring()


func _nearest_foe(max_d: float):
	var best = null
	var best_d: float = max_d
	for u in get_tree().get_nodes_in_group("war_unit"):
		if not is_instance_valid(u) or u.dead or u.team == team:
			continue
		var d: float = global_position.distance_to(u.global_position)
		if d < best_d:
			best_d = d
			best = u
	return best


func _find_target():
	var best = null
	var best_d: float = attack_range * 3.2
	if aggressive:
		best_d = 420.0
	elif guard_radius > 0.0:
		best_d = guard_radius
	for u in get_tree().get_nodes_in_group("war_unit"):
		if not is_instance_valid(u) or u.dead or u.team == team:
			continue
		var d: float = global_position.distance_to(u.global_position)
		# men hidden in the trees go unnoticed unless you walk right into them
		if u.concealed and d > SEEN_WHEN_HIDDEN:
			continue
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
	# your men fight back where they stand; only the enemy rushes in when struck
	if team == 1 and not aggressive:
		aggressive = true
		path_points = []
		move_target = null
		for u in get_tree().get_nodes_in_group("war_team_1"):
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
