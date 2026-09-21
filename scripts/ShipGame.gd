extends Node2D

signal game_finished(won: bool, score: int)

# 1 Nephi 18: calm crossing -> Nephi bound, compass dead, storm, awful steering
# -> Nephi loosed, compass works, great calm -> the promised land.

const SHIP_Y := 432.0
const MAX_HULL := 8
const CALM1_TIME := 20.0
const MIN_STORM := 10.0
const MAX_STORM := 32.0
const CALM2_TIME := 18.0

var phase: String = "calm1"   # calm1 | binding | storm | loosed | calm2 | done
var phase_t: float = 0.0
var total_t: float = 0.0
var hull: int = MAX_HULL
var invuln: float = 0.0
var finished: bool = false
var score: int = 0
var passed: int = 0

var ship_x: float = 480.0
var ship_vx: float = 0.0
var steer: float = 0.0          # smoothed rudder input
var storm_k: float = 0.0        # 0 calm .. 1 full storm
var wind: float = 0.0
var wind_target: float = 0.0
var wind_timer: float = 0.0
var scroll: float = 0.0
var spawn_t: float = 1.0
var flash: float = 0.0
var compass_ang: float = -PI / 2.0
var banner_t: float = 0.0

var obstacles: Array = []       # {type, x, y, r, w, t, hit}
var rain: Array = []

@onready var hull_bar: ProgressBar = $UI/HullBar
@onready var hull_label: Label = $UI/HullBar/HullLabel
@onready var progress_bar: ProgressBar = $UI/ProgressBar
@onready var phase_label: Label = $UI/PhaseLabel
@onready var banner: Label = $UI/Banner
@onready var hint_label: Label = $UI/HintLabel
@onready var compass: Control = $UI/Compass


func _ready() -> void:
	randomize()
	hull_bar.max_value = MAX_HULL
	progress_bar.max_value = 100.0
	compass.draw.connect(_draw_compass)
	for i in range(90):
		rain.append(Vector2(randf() * 960.0, randf() * 540.0))
	Touch.configure({"joystick": true})
	hint_label.text = "A / D or arrow keys to steer." if not Touch.active else "Drag your left thumb to steer."
	_say("\"...we did put forth into the sea and were driven forth before the wind towards the promised land.\"", 4.0)
	_update_hud()


func _exit_tree() -> void:
	Touch.clear()


func _say(text: String, secs: float) -> void:
	banner.text = text
	banner_t = secs


func _process(delta: float) -> void:
	if finished:
		return
	total_t += delta
	phase_t += delta
	invuln = maxf(0.0, invuln - delta)
	flash = maxf(0.0, flash - delta * 2.5)
	if banner_t > 0.0:
		banner_t -= delta
		if banner_t <= 0.0:
			banner.text = ""

	_update_phase()

	var target_k: float = 1.0 if phase == "storm" or phase == "binding" else 0.0
	if phase == "binding":
		target_k = clampf(phase_t / 3.0, 0.0, 1.0)
	storm_k = move_toward(storm_k, target_k, delta * (0.6 if target_k > storm_k else 0.9))

	_steer(delta)
	_scroll_and_spawn(delta)
	_collide()

	# compass: steady toward the promised land when it works, spinning when it doesn't
	if storm_k > 0.2:
		compass_ang += delta * (6.0 + sin(total_t * 3.0) * 4.0)
	else:
		compass_ang = lerp_angle(compass_ang, -PI / 2.0, delta * 4.0)

	_update_hud()
	queue_redraw()
	compass.queue_redraw()


func _update_phase() -> void:
	match phase:
		"calm1":
			if phase_t >= CALM1_TIME:
				_enter("binding")
				_say("Laman and Lemuel began to make merry... they did bind Nephi with cords, and the compass did cease to work.", 5.0)
		"binding":
			if phase_t >= 3.0:
				_enter("storm")
				_say("\"...there arose a great storm, yea, a great and terrible tempest...\"", 4.0)
		"storm":
			var desperate := hull <= 3 and phase_t >= MIN_STORM
			if desperate or phase_t >= MAX_STORM:
				_enter("loosed")
				_say("About to be swallowed up, they repented and loosed Nephi. He took the compass -- and it did work.", 5.0)
		"loosed":
			if phase_t >= 3.0:
				_enter("calm2")
				_say("\"...after I had prayed the winds did cease, and the storm did cease, and there was a great calm.\"", 4.0)
		"calm2":
			if phase_t >= CALM2_TIME:
				_arrive()


func _enter(p: String) -> void:
	phase = p
	phase_t = 0.0
	if p == "loosed":
		# clear the worst of the storm off the water
		obstacles = obstacles.filter(func(o): return o["type"] == "rock")


func _input_axis() -> float:
	var x := 0.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		x += 1.0
	if Touch.active and absf(Touch.move_vector.x) > 0.1:
		x = Touch.move_vector.x
	return clampf(x, -1.0, 1.0)


func _steer(delta: float) -> void:
	var raw: float = _input_axis()
	# calm: crisp rudder. storm (Nephi bound): the helm answers late and weakly
	var response: float = lerpf(14.0, 1.6, storm_k)
	steer = lerpf(steer, raw, 1.0 - exp(-response * delta))
	var accel: float = lerpf(1500.0, 420.0, storm_k)
	var max_v: float = lerpf(330.0, 260.0, storm_k)
	var drag: float = lerpf(9.0, 0.9, storm_k)   # storm: the ship keeps sliding

	wind_timer -= delta
	if wind_timer <= 0.0:
		wind_timer = randf_range(0.9, 2.0)
		wind_target = randf_range(-1.0, 1.0) * 330.0 * storm_k
	wind = lerpf(wind, wind_target, 1.0 - exp(-2.5 * delta))

	ship_vx += (steer * accel + wind) * delta
	ship_vx -= ship_vx * drag * delta
	ship_vx = clampf(ship_vx, -max_v, max_v)
	ship_x += ship_vx * delta
	if ship_x < 40.0 or ship_x > 920.0:
		ship_x = clampf(ship_x, 40.0, 920.0)
		ship_vx *= -0.3


func _scroll_and_spawn(delta: float) -> void:
	var speed: float = lerpf(170.0, 235.0, storm_k)
	scroll += speed * delta
	for o in obstacles:
		o["y"] += speed * delta * (1.25 if o["type"] == "wave" else 1.0)
		o["t"] += delta
		if o["type"] == "whirl":
			var dx: float = o["x"] - ship_x
			var dy: float = o["y"] - SHIP_Y
			if absf(dy) < 130.0 and absf(dx) < 170.0:
				ship_vx += signf(dx) * 260.0 * delta
	var before := obstacles.size()
	obstacles = obstacles.filter(func(o): return o["y"] < 620.0)
	passed += before - obstacles.size()

	for i in range(rain.size()):
		var r: Vector2 = rain[i]
		r += Vector2(wind * 0.4 - 60.0, 900.0) * delta
		if r.y > 540.0:
			r = Vector2(randf() * 1000.0, -10.0)
		rain[i] = r

	if phase == "loosed" or phase == "binding":
		return
	spawn_t -= delta
	if spawn_t > 0.0:
		return
	if phase == "storm":
		spawn_t = randf_range(0.55, 1.0)
		var roll := randf()
		if roll < 0.35:
			_spawn_rock()
		elif roll < 0.62:
			obstacles.append({"type": "wave", "x": randf_range(120, 840), "y": -40.0, "w": randf_range(260, 460), "t": 0.0, "hit": false, "r": 0.0})
		elif roll < 0.8:
			obstacles.append({"type": "whirl", "x": randf_range(140, 820), "y": -60.0, "r": 34.0, "t": 0.0, "hit": false, "w": 0.0})
		else:
			obstacles.append({"type": "bolt", "x": clampf(ship_x + randf_range(-140, 140), 60, 900), "y": 0.0, "w": 70.0, "t": 0.0, "hit": false, "r": 0.0})
	else:
		spawn_t = randf_range(0.9, 1.6) if phase == "calm1" else randf_range(1.1, 1.9)
		if randf() < 0.7:
			_spawn_rock()
		else:
			obstacles.append({"type": "log", "x": randf_range(80, 880), "y": -30.0, "r": 16.0, "t": 0.0, "hit": false, "w": 70.0})


func _spawn_rock() -> void:
	obstacles.append({"type": "rock", "x": randf_range(60, 900), "y": -40.0, "r": randf_range(20, 34), "t": 0.0, "hit": false, "w": 0.0})


func _collide() -> void:
	if invuln > 0.0:
		return
	var ship_pts := [Vector2(ship_x, SHIP_Y - 20.0), Vector2(ship_x, SHIP_Y + 14.0)]
	for o in obstacles:
		if o["hit"]:
			continue
		match o["type"]:
			"rock", "log":
				for sp in ship_pts:
					if sp.distance_to(Vector2(o["x"], o["y"])) < o["r"] + 13.0:
						o["hit"] = true
						_damage(1, o["x"])
						return
			"whirl":
				if Vector2(ship_x, SHIP_Y).distance_to(Vector2(o["x"], o["y"])) < o["r"]:
					o["hit"] = true
					_damage(2, o["x"])
					return
			"wave":
				if absf(o["y"] - SHIP_Y) < 14.0 and absf(ship_x - o["x"]) < o["w"] * 0.5:
					o["hit"] = true
					ship_vx += randf_range(-1.0, 1.0) * 380.0
					_damage(1, o["x"])
					return
			"bolt":
				# 1.1s warning, then the strike
				if o["t"] >= 1.1 and o["t"] < 1.3:
					o["hit"] = true
					flash = 1.0
					if absf(ship_x - o["x"]) < o["w"] * 0.5:
						_damage(2, o["x"])
						return


func _damage(n: int, from_x: float) -> void:
	hull -= n
	invuln = 1.0
	flash = maxf(flash, 0.6)
	ship_vx += signf(ship_x - from_x) * 160.0
	Fx.spawn_hit_burst(self, Vector2(ship_x, SHIP_Y), Color(0.85, 0.75, 0.55, 1), 14)
	if hull <= 0:
		hull = 0
		_finish(false)


func _arrive() -> void:
	phase = "done"
	_say("\"...we did arrive at the promised land...\"", 3.0)
	_finish(true)


func _update_hud() -> void:
	hull_bar.value = hull
	hull_label.text = "Hull %d / %d" % [hull, MAX_HULL]
	var expected: float = CALM1_TIME + 3.0 + MAX_STORM * 0.75 + 3.0 + CALM2_TIME
	progress_bar.value = clampf(total_t / expected * 100.0, 0.0, 100.0) if phase != "done" else 100.0
	match phase:
		"calm1":
			phase_label.text = "Driven before the wind"
		"binding":
			phase_label.text = "Nephi is bound"
		"storm":
			phase_label.text = "NEPHI IS BOUND -- the compass is dead, the helm won't answer"
		"loosed", "calm2":
			phase_label.text = "Nephi is loosed -- the compass works"
		_:
			phase_label.text = "The promised land"


func _finish(won: bool) -> void:
	finished = true
	score = passed * 5 + hull * 60 + (400 if won else 0)
	var f := ColorRect.new()
	f.color = Color(0.4, 1, 0.5, 0.35) if won else Color(0.1, 0.15, 0.3, 0.6)
	f.anchor_right = 1.0
	f.anchor_bottom = 1.0
	$UI.add_child(f)
	get_tree().create_timer(1.2 if won else 0.6).timeout.connect(func(): game_finished.emit(won, score))


# ------------------------------------------------------------------ drawing

func _draw() -> void:
	var calm_sea := Color(0.16, 0.42, 0.6, 1)
	var storm_sea := Color(0.07, 0.12, 0.2, 1)
	draw_rect(Rect2(0, 0, 960, 540), calm_sea.lerp(storm_sea, storm_k))

	# moving swell lines
	var line_col := Color(1, 1, 1, lerpf(0.13, 0.22, storm_k))
	var amp: float = lerpf(6.0, 20.0, storm_k)
	var spacing := 46.0
	var off: float = fmod(scroll, spacing)
	var y := -spacing + off
	while y < 560.0:
		var prev := Vector2(0, y)
		var x := 24.0
		while x <= 960.0:
			var p := Vector2(x, y + sin(x * 0.02 + y * 0.05 + total_t * 1.5) * amp)
			draw_line(prev, p, line_col, 2.0)
			prev = p
			x += 24.0
		y += spacing

	for o in obstacles:
		_draw_obstacle(o)

	_draw_ship()

	# rain + dark sky in the storm
	if storm_k > 0.05:
		var rc := Color(0.8, 0.85, 1.0, 0.35 * storm_k)
		for r in rain:
			draw_line(r, r + Vector2(wind * 0.02 - 4.0, 14.0), rc, 1.5)
		draw_rect(Rect2(0, 0, 960, 540), Color(0, 0, 0.05, 0.25 * storm_k))
	if flash > 0.0:
		draw_rect(Rect2(0, 0, 960, 540), Color(1, 1, 0.9, 0.55 * flash))


func _draw_obstacle(o: Dictionary) -> void:
	var c := Vector2(o["x"], o["y"])
	match o["type"]:
		"rock":
			var r: float = o["r"]
			var pts := PackedVector2Array()
			for i in range(9):
				var a: float = TAU * float(i) / 9.0
				pts.append(c + Vector2(cos(a), sin(a)) * r * (0.85 + 0.15 * sin(i * 2.3 + r)))
			draw_colored_polygon(pts, Color(0.2, 0.19, 0.18, 1))
			draw_circle(c + Vector2(-r * 0.25, -r * 0.3), r * 0.35, Color(0.36, 0.34, 0.31, 1))
			draw_arc(c, r + 4.0, 0.0, TAU, 20, Color(1, 1, 1, 0.35), 2.0)
		"log":
			draw_line(c - Vector2(o["w"] * 0.5, 0), c + Vector2(o["w"] * 0.5, 0), Color(0.3, 0.2, 0.1, 1), 12.0)
			draw_line(c - Vector2(o["w"] * 0.5, -2), c + Vector2(o["w"] * 0.5, -2), Color(0.5, 0.36, 0.2, 1), 5.0)
		"wave":
			var w: float = o["w"]
			var pts2 := PackedVector2Array()
			for i in range(13):
				var t: float = float(i) / 12.0
				pts2.append(c + Vector2((t - 0.5) * w, -sin(t * PI) * 16.0))
			for i in range(pts2.size() - 1):
				draw_line(pts2[i], pts2[i + 1], Color(0.85, 0.92, 1.0, 0.9), 7.0)
				draw_line(pts2[i] + Vector2(0, 7), pts2[i + 1] + Vector2(0, 7), Color(0.3, 0.5, 0.7, 0.8), 5.0)
		"whirl":
			var spin: float = o["t"] * 4.0
			for k in range(3):
				var rr: float = o["r"] + k * 22.0
				draw_arc(c, rr, spin + k, spin + k + PI * 1.3, 18, Color(0.7, 0.85, 1.0, 0.6 - k * 0.15), 3.0)
			draw_circle(c, 12.0, Color(0.02, 0.04, 0.08, 0.9))
		"bolt":
			var t: float = o["t"]
			var half: float = o["w"] * 0.5
			if t < 1.1:
				var blink: float = 0.25 + 0.25 * sin(t * 30.0)
				draw_rect(Rect2(o["x"] - half, 0, o["w"], 540), Color(1, 0.95, 0.3, blink))
			elif t < 1.4:
				var x0: float = o["x"]
				var yy := 0.0
				var px := x0
				while yy < 540.0:
					var nx: float = x0 + randf_range(-18, 18)
					draw_line(Vector2(px, yy), Vector2(nx, yy + 40.0), Color(1, 1, 0.85, 1), 5.0)
					px = nx
					yy += 40.0


func _draw_ship() -> void:
	if invuln > 0.0 and int(invuln * 12.0) % 2 == 0:
		return
	var tilt: float = clampf(ship_vx / 330.0, -1.0, 1.0) * 0.35 + sin(total_t * 3.0) * 0.05 * (1.0 + storm_k * 3.0)
	draw_set_transform(Vector2(ship_x, SHIP_Y), tilt, Vector2.ONE)
	# wake
	draw_line(Vector2(-8, 30), Vector2(-22, 70), Color(1, 1, 1, 0.3), 3.0)
	draw_line(Vector2(8, 30), Vector2(22, 70), Color(1, 1, 1, 0.3), 3.0)
	var hull_pts := PackedVector2Array([
		Vector2(0, -38), Vector2(15, -16), Vector2(15, 24), Vector2(8, 34),
		Vector2(-8, 34), Vector2(-15, 24), Vector2(-15, -16),
	])
	draw_colored_polygon(hull_pts, Color(0.12, 0.08, 0.05, 1))
	var inner := PackedVector2Array([
		Vector2(0, -32), Vector2(11, -14), Vector2(11, 22), Vector2(6, 30),
		Vector2(-6, 30), Vector2(-11, 22), Vector2(-11, -14),
	])
	draw_colored_polygon(inner, Color(0.55, 0.37, 0.2, 1))
	for i in range(4):
		draw_line(Vector2(-10, -8 + i * 9), Vector2(10, -8 + i * 9), Color(0.38, 0.25, 0.13, 1), 1.5)
	# mast + sail (sail flaps in the storm)
	var billow: float = 10.0 + sin(total_t * (3.0 + storm_k * 12.0)) * (2.0 + storm_k * 8.0)
	var sail := PackedVector2Array([Vector2(-24, -4), Vector2(0, -4 - billow), Vector2(24, -4), Vector2(0, 2)])
	draw_colored_polygon(sail, Color(0.94, 0.92, 0.84, 1))
	draw_circle(Vector2(0, -4), 3.5, Color(0.25, 0.16, 0.08, 1))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_compass() -> void:
	var c := compass.size * 0.5
	var r: float = minf(c.x, c.y) - 4.0
	compass.draw_circle(c, r + 3.0, Color(0.08, 0.07, 0.06, 0.9))
	compass.draw_circle(c, r, Color(0.62, 0.5, 0.25, 1))
	compass.draw_circle(c, r - 5.0, Color(0.88, 0.82, 0.62, 1))
	var dir := Vector2(cos(compass_ang), sin(compass_ang))
	var col := Color(0.2, 0.55, 0.25, 1) if storm_k < 0.2 else Color(0.7, 0.2, 0.15, 1)
	compass.draw_line(c - dir * (r - 10.0), c + dir * (r - 8.0), col, 4.0)
	compass.draw_circle(c + dir * (r - 8.0), 4.0, col)
	compass.draw_circle(c, 3.0, Color(0.1, 0.08, 0.05, 1))
