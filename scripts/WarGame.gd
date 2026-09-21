extends Node2D

signal game_finished(won: bool, score: int)

const UNIT_SCENE := preload("res://scenes/WarUnit.tscn")

const STATS := {
	"sword":  {"hp": 34.0, "dmg": 7.0, "range": 28.0, "atk": 0.85, "spd": 62.0, "name": "Swordmen"},
	"spear":  {"hp": 30.0, "dmg": 9.0, "range": 48.0, "atk": 1.0,  "spd": 54.0, "name": "Spearmen"},
	"archer": {"hp": 20.0, "dmg": 6.5, "range": 165.0,"atk": 1.25, "spd": 50.0, "name": "Archers"},
}

# Three engagements drawn from the war chapters.
const LEVELS := [
	{
		"name": "Ambush at the River Sidon",
		"ref": "Alma 43",
		"brief": "Moroni hid his armies on both sides of the valley and let Zerahemnah march between them. Hide your men in the trees -- they spring when the enemy is close, or when you press CHARGE. Don't let the column escape west.",
		"objective": "destroy_all",
		"forest": [Rect2(120, 110, 260, 120), Rect2(120, 316, 260, 120), Rect2(560, 90, 220, 110)],
		"water": [Rect2(0, 250, 960, 44)],
		"zones": [Rect2(130, 120, 240, 100), Rect2(130, 326, 240, 100)],
		"roster": {"sword": 4, "spear": 4, "archer": 3},
		"enemy": [
			{"kind": "sword", "n": 5, "at": Vector2(930, 240), "path": [Vector2(600, 250), Vector2(300, 262), Vector2(60, 268)]},
			{"kind": "spear", "n": 3, "at": Vector2(930, 300), "path": [Vector2(620, 300), Vector2(320, 292), Vector2(60, 288)]},
			{"kind": "archer", "n": 2, "at": Vector2(940, 268), "path": [Vector2(640, 272), Vector2(340, 276), Vector2(70, 278)]},
		],
	},
	{
		"name": "The Walls of Noah",
		"ref": "Alma 49",
		"brief": "Moroni had ringed the city with banks of earth, leaving one narrow entrance. Hold that gap. Survive the assault and the city stands.",
		"objective": "hold",
		"hold_time": 42.0,
		"forest": [],
		"walls": [Rect2(300, 70, 34, 180), Rect2(300, 330, 34, 180)],
		"water": [],
		"zones": [Rect2(60, 90, 220, 360)],
		"roster": {"sword": 4, "spear": 4, "archer": 4},
		"waves": [
			{"t": 1.0, "kind": "sword", "n": 4},
			{"t": 14.0, "kind": "spear", "n": 4},
			{"t": 28.0, "kind": "sword", "n": 5},
			{"t": 33.0, "kind": "archer", "n": 3},
		],
	},
	{
		"name": "The Decoy at Mulek",
		"ref": "Alma 52",
		"brief": "Teancum's small force drew Jacob's army out of the city, and Moroni took it while it stood empty. Defenders behind the walls barely take damage -- send a small band to pull them out, then take the empty city.",
		"objective": "capture",
		"city": Rect2(780, 190, 150, 160),
		"forest": [Rect2(80, 70, 200, 120), Rect2(80, 350, 200, 120)],
		"water": [],
		"zones": [Rect2(70, 80, 200, 100), Rect2(70, 360, 200, 100)],
		"roster": {"sword": 5, "spear": 3, "archer": 3},
		"enemy": [
			{"kind": "sword", "n": 4, "at": Vector2(840, 230), "path": []},
			{"kind": "spear", "n": 3, "at": Vector2(860, 300), "path": []},
			{"kind": "archer", "n": 2, "at": Vector2(880, 265), "path": []},
		],
		"lure_line": 520.0,
	},
]

var level_index: int = 0
var level: Dictionary = {}
var phase: String = "prep"       # prep | battle | done
var roster: Dictionary = {}
var chosen_kind: String = "sword"
var selected: Array = []
var score: int = 0
var finished: bool = false
var hold_timer: float = 0.0
var battle_time: float = 0.0
var wave_idx: int = 0
var escaped_count: int = 0
const ESCAPE_LIMIT := 4
var drag_start = null
var drag_now = null

@onready var units_root: Node2D = $Units
@onready var arrows_root: Node2D = $Arrows
@onready var title_label: Label = $UI/TitleLabel
@onready var brief_label: Label = $UI/BriefLabel
@onready var status_label: Label = $UI/StatusLabel
@onready var begin_button: Button = $UI/BeginButton
@onready var roster_bar: HBoxContainer = $UI/RosterBar
@onready var charge_button: Button = $UI/ChargeButton

var roster_buttons: Dictionary = {}


func _ready() -> void:
	randomize()
	begin_button.pressed.connect(_begin_battle)
	charge_button.pressed.connect(_charge)
	_load_level(0)


func _load_level(idx: int) -> void:
	level_index = idx
	level = LEVELS[idx]
	phase = "prep"
	hold_timer = 0.0
	battle_time = 0.0
	wave_idx = 0
	escaped_count = 0
	selected.clear()
	for c in units_root.get_children():
		c.queue_free()
	for c in arrows_root.get_children():
		c.queue_free()

	roster = (level["roster"] as Dictionary).duplicate()
	for c in roster_bar.get_children():
		c.queue_free()
	roster_buttons.clear()
	for kind in ["sword", "spear", "archer"]:
		if not roster.has(kind):
			continue
		var b := Button.new()
		b.custom_minimum_size = Vector2(150, 44)
		b.add_theme_font_size_override("font_size", 14)
		b.pressed.connect(func(): chosen_kind = kind; _refresh_roster())
		roster_bar.add_child(b)
		roster_buttons[kind] = b
	chosen_kind = "sword"

	title_label.text = "%s  (%s)" % [level["name"], level["ref"]]
	brief_label.text = level["brief"]
	begin_button.visible = true
	begin_button.text = "Begin Battle"
	charge_button.visible = false
	_refresh_roster()
	_update_status()
	queue_redraw()


func _refresh_roster() -> void:
	for kind in roster_buttons:
		var b: Button = roster_buttons[kind]
		var left: int = roster.get(kind, 0)
		b.text = "%s  x%d%s" % [STATS[kind]["name"], left, "  <" if kind == chosen_kind else ""]
		b.disabled = left <= 0


func _unhandled_input(event: InputEvent) -> void:
	if finished:
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		var p: Vector2 = get_global_mouse_position()
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if phase == "prep" and mb.pressed:
				_try_place(p)
			elif phase == "battle":
				if mb.pressed:
					drag_start = p
					drag_now = p
				else:
					_finish_drag(p)
		elif mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed and phase == "battle":
			for u in selected:
				if is_instance_valid(u):
					u.order_move(p + Vector2(randf_range(-18, 18), randf_range(-18, 18)))
	elif event is InputEventMouseMotion and drag_start != null:
		drag_now = get_global_mouse_position()
		queue_redraw()


func _finish_drag(p: Vector2) -> void:
	var rect := Rect2(drag_start, p - drag_start).abs()
	drag_start = null
	drag_now = null
	for u in selected:
		if is_instance_valid(u):
			u.selected = false
	selected.clear()
	if rect.size.length() < 8.0:
		# click-select nearest friendly
		var best = null
		var best_d := 34.0
		for u in units_root.get_children():
			if u.team != 0 or u.dead:
				continue
			var d: float = u.global_position.distance_to(p)
			if d < best_d:
				best_d = d
				best = u
		if best != null:
			best.selected = true
			selected.append(best)
	else:
		for u in units_root.get_children():
			if u.team == 0 and not u.dead and rect.has_point(u.global_position):
				u.selected = true
				selected.append(u)
	_update_status()
	queue_redraw()


func _try_place(p: Vector2) -> void:
	if roster.get(chosen_kind, 0) <= 0:
		return
	var inside := false
	for z in level["zones"]:
		if (z as Rect2).has_point(p):
			inside = true
			break
	if not inside:
		status_label.text = "Place your men inside the highlighted ground."
		return
	roster[chosen_kind] -= 1
	var u := _spawn(0, chosen_kind, p)
	# in cover? then conceal for the ambush
	for f in level.get("forest", []):
		if (f as Rect2).has_point(p):
			u.set_concealed(true)
			break
	_refresh_roster()
	_update_status()


func _spawn(team: int, kind: String, pos: Vector2) -> Node2D:
	var u := UNIT_SCENE.instantiate()
	u.position = pos
	units_root.add_child(u)
	u.configure(team, kind, STATS[kind])
	u.arrows_root = arrows_root
	u.died.connect(_on_unit_died)
	return u


func _begin_battle() -> void:
	if phase != "prep":
		return
	var placed := 0
	for u in units_root.get_children():
		if u.team == 0:
			placed += 1
	if placed == 0:
		status_label.text = "Place at least one company first."
		return
	phase = "battle"
	begin_button.visible = false
	charge_button.visible = true
	for e in level.get("enemy", []):
		for i in range(int(e["n"])):
			var pos: Vector2 = e["at"] + Vector2(randf_range(-26, 26), randf_range(-24, 24))
			var u := _spawn(1, e["kind"], pos)
			if not (e["path"] as Array).is_empty():
				u.set_patrol(e["path"])
			elif level["objective"] == "capture":
				u.guard_radius = 230.0
	_update_status()


func _charge() -> void:
	if phase != "battle":
		return
	var targets = selected if not selected.is_empty() else units_root.get_children()
	for u in targets:
		if is_instance_valid(u) and u.team == 0 and not u.dead:
			u.charge()
	status_label.text = "CHARGE!"


func _process(delta: float) -> void:
	if finished or phase != "battle":
		return
	battle_time += delta

	# level 2 sends timed assault waves at the gap
	if level["objective"] == "hold":
		hold_timer += delta
		var waves: Array = level.get("waves", [])
		while wave_idx < waves.size() and battle_time >= float(waves[wave_idx]["t"]):
			var w: Dictionary = waves[wave_idx]
			for i in range(int(w["n"])):
				var u := _spawn(1, w["kind"], Vector2(randf_range(880, 940), randf_range(140, 420)))
				u.order_move(Vector2(316, 290))
			wave_idx += 1
		if hold_timer >= float(level["hold_time"]):
			_finish(true)
			return

	# level 3: once the garrison is lured past the line, the city is open
	if level["objective"] == "capture":
		var out_count := 0
		var total := 0
		for u in units_root.get_children():
			if u.team == 1 and not u.dead:
				total += 1
				if u.global_position.x < float(level["lure_line"]):
					out_count += 1
		var city: Rect2 = level["city"]
		# the garrison takes the bait only against a small band; a big army sees it hold the walls
		var near_count := 0
		var seen_count := 0
		for u in units_root.get_children():
			if u.team == 0 and not u.dead:
				var d: float = u.global_position.distance_to(city.get_center())
				if d < 400.0:
					near_count += 1
				if d < 640.0:
					seen_count += 1
		for u in units_root.get_children():
			if u.team == 1 and not u.dead and not u.aggressive:
				if near_count >= 1 and seen_count <= 3:
					u.aggressive = true
				else:
					u.guard_radius = 70.0
		# defenders behind the walls are hard to kill -- draw them out first
		for u in units_root.get_children():
			if u.team == 1 and not u.dead:
				u.damage_taken_mult = 0.35 if city.grow(20.0).has_point(u.global_position) else 1.0
		var defenders_inside := 0
		var ours_inside := 0
		for u in units_root.get_children():
			if u.dead:
				continue
			if city.grow(20.0).has_point(u.global_position):
				if u.team == 1:
					defenders_inside += 1
				else:
					ours_inside += 1
		if ours_inside > 0 and defenders_inside == 0:
			_finish(true)
			return

	if level["objective"] == "destroy_all":
		var enemies_left := 0
		for u in units_root.get_children():
			if u.team == 1 and not u.dead:
				if u.global_position.x < 70.0:
					escaped_count += 1
					u.dead = true
					u.queue_free()
					continue
				enemies_left += 1
		if escaped_count >= ESCAPE_LIMIT:
			_finish(false)
			return
		if enemies_left == 0:
			_finish(true)
			return

	var friends := 0
	for u in units_root.get_children():
		if u.team == 0 and not u.dead:
			friends += 1
	if friends == 0:
		_finish(false)
		return

	_update_status()


func _on_unit_died(unit: Node) -> void:
	if unit.team == 1:
		score += 15
	selected = selected.filter(func(u): return is_instance_valid(u))


func _update_status() -> void:
	var friends := 0
	var foes := 0
	for u in units_root.get_children():
		if u.dead:
			continue
		if u.team == 0:
			friends += 1
		else:
			foes += 1
	match phase:
		"prep":
			status_label.text = "PREPARE -- red dashes show the scouts' report of the enemy route. Click the lit ground to place %s." % STATS[chosen_kind]["name"]
		"battle":
			var extra := ""
			if level["objective"] == "hold":
				extra = "   Hold: %ds" % int(maxf(float(level["hold_time"]) - hold_timer, 0.0))
			elif level["objective"] == "destroy_all":
				extra = "   Escaped: %d / %d" % [escaped_count, ESCAPE_LIMIT]
			elif level["objective"] == "capture":
				extra = "   City holds while any defender is inside"
			status_label.text = "Drag to select, right-click to move, CHARGE to attack.   Yours %d   Theirs %d%s" % [friends, foes, extra]
		_:
			pass


func _finish(won: bool) -> void:
	if finished:
		return
	if won and level_index < LEVELS.size() - 1:
		score += 150
		phase = "done"
		status_label.text = "%s won. Advancing..." % level["name"]
		get_tree().create_timer(1.4).timeout.connect(func(): _load_level(level_index + 1))
		return
	finished = true
	if won:
		score += 300
	var flash := ColorRect.new()
	flash.color = Color(0.3, 1, 0.3, 0.4) if won else Color(1, 0.2, 0.2, 0.42)
	flash.anchor_right = 1.0
	flash.anchor_bottom = 1.0
	add_child(flash)
	get_tree().create_timer(0.5).timeout.connect(func(): game_finished.emit(won, score))


func _draw() -> void:
	# ground
	draw_rect(Rect2(0, 0, 960, 540), Color(0.33, 0.38, 0.24, 1))
	for w in level.get("water", []):
		draw_rect(w, Color(0.22, 0.4, 0.55, 1))
		draw_rect(Rect2((w as Rect2).position, Vector2((w as Rect2).size.x, 4)), Color(0.35, 0.55, 0.7, 1))
	for f in level.get("forest", []):
		draw_rect(f, Color(0.16, 0.28, 0.16, 1))
		var r: Rect2 = f
		var x: float = r.position.x + 18.0
		while x < r.position.x + r.size.x - 10.0:
			var y: float = r.position.y + 16.0
			while y < r.position.y + r.size.y - 8.0:
				draw_circle(Vector2(x, y), 11.0, Color(0.1, 0.22, 0.12, 1))
				y += 34.0
			x += 32.0
	for w in level.get("walls", []):
		draw_rect(w, Color(0.35, 0.33, 0.3, 1))
		draw_rect(Rect2((w as Rect2).position, Vector2((w as Rect2).size.x, 6)), Color(0.5, 0.48, 0.44, 1))
	if level.get("objective", "") == "capture":
		var c: Rect2 = level["city"]
		draw_rect(c, Color(0.5, 0.45, 0.3, 0.55))
		draw_rect(Rect2(c.position, Vector2(c.size.x, 6)), Color(0.8, 0.72, 0.4, 1))

	# scouting intel: where the enemy will come from
	if phase == "prep":
		for e in level.get("enemy", []):
			var pts: Array = [e["at"]] + (e["path"] as Array)
			for i in range(pts.size() - 1):
				_dashed(pts[i], pts[i + 1], Color(1, 0.35, 0.3, 0.75))
			if not (e["path"] as Array).is_empty():
				var last: Vector2 = pts[pts.size() - 1]
				var prev: Vector2 = pts[pts.size() - 2]
				var d := (last - prev).normalized()
				var pp := Vector2(-d.y, d.x)
				draw_colored_polygon(PackedVector2Array([last, last - d * 14 + pp * 8, last - d * 14 - pp * 8]), Color(1, 0.35, 0.3, 0.85))
			draw_circle(e["at"], 10.0, Color(0.85, 0.25, 0.2, 0.8))
		if level["objective"] == "hold":
			for y in [160.0, 290.0, 420.0]:
				_dashed(Vector2(930, y), Vector2(340, 290), Color(1, 0.35, 0.3, 0.6))

	# placement zones during prep
	if phase == "prep":
		for z in level["zones"]:
			draw_rect(z, Color(0.45, 0.9, 0.5, 0.18))
			draw_rect(z, Color(0.6, 1.0, 0.6, 0.5), false, 2.0)

	# selection box
	if drag_start != null and drag_now != null:
		var r := Rect2(drag_start, drag_now - drag_start).abs()
		draw_rect(r, Color(0.5, 1.0, 0.5, 0.12))
		draw_rect(r, Color(0.6, 1.0, 0.6, 0.8), false, 1.5)


func _dashed(a: Vector2, b: Vector2, col: Color) -> void:
	var dir := (b - a)
	var length := dir.length()
	if length < 1.0:
		return
	dir /= length
	var d := 0.0
	while d < length:
		draw_line(a + dir * d, a + dir * minf(d + 10.0, length), col, 3.0)
		d += 18.0
