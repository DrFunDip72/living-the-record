extends Node2D

signal killed(points: int)
signal escaped

enum St { GRAZE, WALK, FLEE, DYING }

const INK := Color(0.08, 0.07, 0.06, 1)
const BLOOD := Color(0.62, 0.08, 0.06, 1)

# down-range perspective band
const NEAR_Y := 432.0
const FAR_Y := 250.0
const NEAR_SCALE := 1.15
const FAR_SCALE := 0.34

var st: int = St.GRAZE
var facing: int = 1
var walk_speed: float = 26.0
var flee_speed: float = 210.0
var state_timer: float = 1.2
var depth: float = 0.0
var points: int = 10
var bob: float = 0.0
var coat: Color = Color(0.5, 0.34, 0.2, 1)
var dead: bool = false
var wounded: bool = false
var bleed_timer: float = 0.0
var bleed_life: float = 9.0
var drops: Array = []


func _ready() -> void:
	add_to_group("hunt_animal")


func setup(p_depth: float) -> void:
	depth = clampf(p_depth, 0.0, 1.0)
	var sc: float = lerpf(NEAR_SCALE, FAR_SCALE, depth)
	scale = Vector2(sc, sc)
	position.y = lerpf(NEAR_Y, FAR_Y, depth)
	points = 10 + int(round(depth * 26.0))
	walk_speed = lerpf(34.0, 16.0, depth)
	flee_speed = lerpf(240.0, 110.0, depth)
	facing = 1 if randf() < 0.5 else -1
	position.x = randf_range(220.0, 740.0)
	coat = Color(0.46, 0.31, 0.18, 1).lerp(Color(0.55, 0.43, 0.3, 1), depth)
	queue_redraw()


func current_scale() -> float:
	return lerpf(NEAR_SCALE, FAR_SCALE, depth)


func _process(delta: float) -> void:
	bob += delta
	state_timer -= delta

	if wounded and st != St.DYING:
		bleed_timer -= delta
		bleed_life -= delta
		if bleed_timer <= 0.0:
			bleed_timer = 0.35
			drops.append({"p": Vector2(randf_range(-10, 10), randf_range(6, 18)), "a": 1.0})
		for d in drops:
			d["a"] -= delta * 0.5
		if bleed_life <= 0.0 and not dead:
			dead = true
			escaped.emit()
			queue_free()
			return

	var spd_mult: float = 0.42 if wounded else 1.0

	match st:
		St.GRAZE:
			if state_timer <= 0.0:
				st = St.WALK
				state_timer = randf_range(1.0, 2.4)
		St.WALK:
			position.x += facing * walk_speed * spd_mult * delta
			if state_timer <= 0.0:
				st = St.GRAZE
				state_timer = randf_range(0.8, 1.8)
			if position.x < 170.0:
				facing = 1
			elif position.x > 790.0:
				facing = -1
		St.FLEE:
			position.x += facing * flee_speed * spd_mult * delta
			if position.x < -80.0 or position.x > 1040.0:
				if not dead:
					dead = true
					escaped.emit()
					queue_free()
				return
		St.DYING:
			rotation = lerpf(rotation, facing * 1.5, delta * 8.0)
			modulate.a = maxf(modulate.a - delta * 1.5, 0.0)
			if modulate.a <= 0.02:
				queue_free()
				return

	queue_redraw()


func spook(from_x: float) -> void:
	if st == St.FLEE or st == St.DYING:
		return
	facing = 1 if from_x < position.x else -1
	st = St.FLEE


# "vital" | "body" | ""
func hit_test(global_pos: Vector2) -> String:
	if st == St.DYING or dead:
		return ""
	var p: Vector2 = to_local(global_pos)
	p.x *= facing
	if Rect2(-4.0, -16.0, 26.0, 22.0).has_point(p):
		return "vital"
	if Rect2(-34.0, -26.0, 76.0, 48.0).has_point(p):
		return "body"
	return ""


func on_hit(kind: String) -> void:
	if kind == "vital" or wounded:
		st = St.DYING
		dead = true
		killed.emit(points if kind == "vital" else int(points * 0.7))
	else:
		wounded = true
		bleed_life = 9.0
		spook(position.x - facing * 60.0)


func _draw() -> void:
	var f := float(facing)
	var lift: float = sin(bob * 2.2) * 1.2
	var graze: bool = st == St.GRAZE
	var run: bool = st == St.FLEE

	# blood on the ground / flank
	for d in drops:
		if d["a"] > 0.0:
			draw_circle(d["p"], 2.6, Color(BLOOD.r, BLOOD.g, BLOOD.b, clampf(d["a"], 0.0, 0.85)))

	var limp: float = 0.0
	if wounded:
		limp = sin(bob * 6.0) * 3.0

	# legs
	var leg_swing: float = sin(bob * (13.0 if run else 3.0)) * (9.0 if run else 2.5)
	for i in range(4):
		var lx: float = (-20.0 + i * 13.0) * f
		var phase: float = leg_swing if i % 2 == 0 else -leg_swing
		draw_line(Vector2(lx, 10 + limp * (1.0 if i % 2 == 0 else 0.0)), Vector2(lx + phase * f, 44), INK, 4.0)

	# body
	var body := PackedVector2Array([
		Vector2(-32 * f, -4 + lift), Vector2(-24 * f, -18 + lift),
		Vector2(8 * f, -22 + lift), Vector2(28 * f, -16 + lift),
		Vector2(32 * f, -2 + lift), Vector2(24 * f, 12 + lift),
		Vector2(-20 * f, 14 + lift), Vector2(-32 * f, 6 + lift),
	])
	draw_colored_polygon(body, INK)
	var body_in := PackedVector2Array([
		Vector2(-27 * f, -3 + lift), Vector2(-20 * f, -14 + lift),
		Vector2(8 * f, -18 + lift), Vector2(24 * f, -12 + lift),
		Vector2(27 * f, -2 + lift), Vector2(20 * f, 9 + lift),
		Vector2(-18 * f, 10 + lift), Vector2(-27 * f, 4 + lift),
	])
	draw_colored_polygon(body_in, coat)

	# vital patch -- the spot to aim for
	var vital := PackedVector2Array([
		Vector2(0 * f, -14 + lift), Vector2(18 * f, -14 + lift),
		Vector2(18 * f, 2 + lift), Vector2(0 * f, 2 + lift),
	])
	draw_colored_polygon(vital, coat.darkened(0.45))

	if wounded:
		draw_circle(Vector2(6 * f, -6 + lift), 4.5, BLOOD)
		draw_line(Vector2(6 * f, -4 + lift), Vector2(4 * f, 12 + lift), BLOOD, 2.5)

	# neck + head
	var head_y: float = (16.0 if graze else -34.0) + lift
	var neck := PackedVector2Array([
		Vector2(24 * f, -16 + lift), Vector2(34 * f, -10 + lift),
		Vector2(46 * f, head_y + 10), Vector2(34 * f, head_y + 12),
	])
	draw_colored_polygon(neck, INK)
	var head := PackedVector2Array([
		Vector2(36 * f, head_y + 10), Vector2(54 * f, head_y + 5),
		Vector2(60 * f, head_y + 12), Vector2(52 * f, head_y + 19),
		Vector2(36 * f, head_y + 18),
	])
	draw_colored_polygon(head, INK)
	draw_circle(Vector2(48 * f, head_y + 11), 1.8, Color(1, 0.95, 0.85, 1))

	if not graze:
		draw_line(Vector2(34 * f, head_y + 6), Vector2(30 * f, head_y - 10), INK, 3.0)
		draw_line(Vector2(30 * f, head_y - 10), Vector2(36 * f, head_y - 16), INK, 2.5)
		draw_line(Vector2(40 * f, head_y + 6), Vector2(44 * f, head_y - 10), INK, 3.0)

	draw_line(Vector2(-31 * f, -6 + lift), Vector2(-38 * f, -14 + lift), INK, 4.0)
