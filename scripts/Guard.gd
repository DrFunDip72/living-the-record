extends Node2D

signal shouted(pos: Vector2)
signal caught_player

enum St { PATROL, LOOK, SUSPICIOUS, CHASE }

const VIEW_DIST := 172.0
const VIEW_HALF_ANGLE := 0.58
const CATCH_DIST := 24.0
const OBSTACLE_MASK := 2
const INK := Color(0.08, 0.06, 0.06, 1)

@export var patrol_speed: float = 68.0
@export var chase_speed: float = 152.0

var st: int = St.PATROL
var facing: Vector2 = Vector2.RIGHT
var target_point: Vector2 = Vector2.ZERO
var last_known: Vector2 = Vector2.ZERO
var timer: float = 0.0
var lost_timer: float = 0.0
var sweep_dir: float = 1.0
var bounds: Rect2 = Rect2(70, 70, 820, 400)
var player: Node2D = null
var alerted_cooldown: float = 0.0


func setup(p_player: Node2D, p_bounds: Rect2) -> void:
	player = p_player
	bounds = p_bounds
	_pick_patrol_point()


func _process(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		return
	alerted_cooldown = maxf(0.0, alerted_cooldown - delta)
	var sees := _can_see_player()

	match st:
		St.PATROL:
			_move_toward(target_point, patrol_speed, delta)
			if position.distance_to(target_point) < 14.0:
				st = St.LOOK
				timer = randf_range(0.8, 1.7)
				sweep_dir = 1.0 if randf() < 0.5 else -1.0
			if sees:
				_begin_chase()
		St.LOOK:
			timer -= delta
			facing = facing.rotated(sweep_dir * 1.5 * delta)
			if timer <= 0.0:
				_pick_patrol_point()
				st = St.PATROL
			if sees:
				_begin_chase()
		St.SUSPICIOUS:
			_move_toward(last_known, patrol_speed * 1.35, delta)
			if position.distance_to(last_known) < 16.0:
				st = St.LOOK
				timer = randf_range(1.2, 2.0)
				sweep_dir = 1.0 if randf() < 0.5 else -1.0
			if sees:
				_begin_chase()
		St.CHASE:
			if sees:
				lost_timer = 0.0
				last_known = player.global_position
			else:
				lost_timer += delta
				if lost_timer > 1.6:
					st = St.SUSPICIOUS
			_move_toward(last_known, chase_speed, delta)
			if position.distance_to(player.global_position) < CATCH_DIST:
				caught_player.emit()

	queue_redraw()


func _begin_chase() -> void:
	last_known = player.global_position
	lost_timer = 0.0
	if st != St.CHASE:
		st = St.CHASE
		if alerted_cooldown <= 0.0:
			alerted_cooldown = 2.5
			shouted.emit(player.global_position)


func alert(pos: Vector2) -> void:
	if st == St.CHASE:
		return
	last_known = pos
	st = St.SUSPICIOUS


func _pick_patrol_point() -> void:
	target_point = Vector2(
		randf_range(bounds.position.x, bounds.position.x + bounds.size.x),
		randf_range(bounds.position.y, bounds.position.y + bounds.size.y)
	)


func _move_toward(dest: Vector2, speed: float, delta: float) -> void:
	var to: Vector2 = dest - position
	if to.length() < 2.0:
		return
	var dir: Vector2 = to.normalized()
	facing = facing.lerp(dir, 1.0 - exp(-8.0 * delta)).normalized()
	position += dir * speed * delta
	position.x = clampf(position.x, bounds.position.x - 30.0, bounds.position.x + bounds.size.x + 30.0)
	position.y = clampf(position.y, bounds.position.y - 30.0, bounds.position.y + bounds.size.y + 30.0)


func _can_see_player() -> bool:
	if player == null or not is_instance_valid(player):
		return false
	var to: Vector2 = player.global_position - global_position
	var dist := to.length()
	if dist > VIEW_DIST:
		return false
	if absf(facing.angle_to(to.normalized())) > VIEW_HALF_ANGLE:
		return false
	var space := get_world_2d().direct_space_state
	var q := PhysicsRayQueryParameters2D.create(global_position, player.global_position, OBSTACLE_MASK)
	return space.intersect_ray(q).is_empty()


func _cone_color() -> Color:
	match st:
		St.CHASE:
			return Color(1.0, 0.25, 0.2, 0.30)
		St.SUSPICIOUS:
			return Color(1.0, 0.6, 0.15, 0.26)
		_:
			return Color(1.0, 0.95, 0.4, 0.20)


func _draw() -> void:
	# vision cone
	var pts := PackedVector2Array()
	pts.append(Vector2.ZERO)
	var base := facing.angle()
	var steps := 12
	for i in range(steps + 1):
		var t: float = float(i) / float(steps)
		var ang: float = base - VIEW_HALF_ANGLE + t * (VIEW_HALF_ANGLE * 2.0)
		pts.append(Vector2(cos(ang), sin(ang)) * VIEW_DIST)
	draw_colored_polygon(pts, _cone_color())

	# body
	draw_circle(Vector2.ZERO, 14.0, INK)
	var body_col := Color(0.75, 0.2, 0.2, 1)
	if st == St.SUSPICIOUS:
		body_col = Color(0.9, 0.55, 0.15, 1)
	elif st == St.CHASE:
		body_col = Color(1.0, 0.32, 0.25, 1)
	draw_circle(Vector2.ZERO, 11.0, body_col)
	# lantern / facing nub
	draw_circle(facing * 15.0, 5.0, Color(1, 0.92, 0.6, 0.95))

	# state mark
	if st == St.CHASE:
		draw_line(Vector2(0, -32), Vector2(0, -20), Color(1, 0.9, 0.2, 1), 4.0)
		draw_circle(Vector2(0, -15), 2.4, Color(1, 0.9, 0.2, 1))
	elif st == St.SUSPICIOUS:
		draw_arc(Vector2(0, -26), 6.0, -2.6, 1.2, 10, Color(1, 0.8, 0.3, 1), 3.0)
		draw_circle(Vector2(0, -14), 2.2, Color(1, 0.8, 0.3, 1))
