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
		"brief": "Moroni hid his armies on both sides of the valley and let Zerahemnah march between them. Hide your companies in the trees -- they wait silently for your order. When the column is between them, strike. Don't let it escape west.",
		"objective": "destroy_all",
		"forest": [Rect2(120, 110, 260, 120), Rect2(120, 316, 260, 120), Rect2(560, 90, 220, 110)],
		"water": [Rect2(0, 250, 960, 44)],
		"zones": [Rect2(130, 120, 240, 100), Rect2(130, 326, 240, 100)],
		"companies": [
			{"kind": "sword", "n": 3}, {"kind": "sword", "n": 3},
			{"kind": "spear", "n": 3}, {"kind": "archer", "n": 3},
		],
		"enemy": [
			{"kind": "sword", "n": 6, "at": Vector2(930, 240), "path": [Vector2(600, 250), Vector2(300, 262), Vector2(60, 268)]},
			{"kind": "spear", "n": 4, "at": Vector2(930, 300), "path": [Vector2(620, 300), Vector2(320, 292), Vector2(60, 288)]},
			{"kind": "archer", "n": 2, "at": Vector2(940, 268), "path": [Vector2(640, 272), Vector2(340, 276), Vector2(70, 278)]},
		],
	},
	{
		"name": "The Walls of Noah",
		"ref": "Alma 49",
		"brief": "Moroni had ringed the city with banks of earth, leaving one narrow entrance. Your companies hold where you put them. Guard that gap until the assault breaks and the city stands.",
		"objective": "hold",
		"hold_time": 42.0,
		"forest": [],
		"walls": [Rect2(300, 70, 34, 180), Rect2(300, 330, 34, 180)],
		"water": [],
		"zones": [Rect2(60, 90, 220, 360)],
		"companies": [
			{"kind": "sword", "n": 4}, {"kind": "spear", "n": 4}, {"kind": "archer", "n": 4},
		],
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
		"brief": "Teancum's small band drew Jacob's army out of the city, and Moroni took it while it stood empty. Defenders behind the walls barely take damage -- MOVE Teancum's band close to lure them out, run it back, then send the rest to take the empty city.",
		"objective": "capture",
		"city": Rect2(780, 190, 150, 160),
		"forest": [Rect2(80, 70, 200, 120), Rect2(80, 350, 200, 120)],
		"water": [],
		"zones": [Rect2(70, 80, 200, 100), Rect2(70, 360, 200, 100)],
		"companies": [
			{"kind": "sword", "n": 2, "name": "Teancum's band"},
			{"kind": "sword", "n": 3}, {"kind": "spear", "n": 3}, {"kind": "archer", "n": 3},
		],
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
var companies: Array = []        # {kind, n, name, placed, units}
var chosen_company: int = 0      # prep: which company the next tap places
var selected_company: int = -1   # battle: which company takes orders
var move_mode: bool = false      # battle: the next tap on the ground is the destination
var score: int = 0
var finished: bool = false
var hold_timer: float = 0.0
var battle_time: float = 0.0
var wave_idx: int = 0
var escaped_count: int = 0
var flash_status_t: float = 0.0
const ESCAPE_LIMIT := 4
const SLOT_GAP := 24.0

@onready var units_root: Node2D = $Units
@onready var arrows_root: Node2D = $Arrows
@onready var title_label: Label = $UI/TitleLabel
@onready var brief_label: Label = $UI/BriefLabel
@onready var status_label: Label = $UI/StatusLabel
@onready var begin_button: Button = $UI/BeginButton
@onready var roster_bar: HBoxContainer = $UI/RosterBar
@onready var charge_button: Button = $UI/ChargeButton
@onready var command_panel: VBoxContainer = $UI/CommandPanel

var company_buttons: Array = []
var badge_layer: Node2D


func _ready() -> void:
	randomize()
	begin_button.pressed.connect(_begin_battle)
	charge_button.pressed.connect(_charge_all)
	badge_layer = Node2D.new()
	badge_layer.z_index = 10
	badge_layer.draw.connect(_draw_badges)
	add_child(badge_layer)
	for cmd in ["ATTACK", "MOVE", "HOLD"]:
		var b := Button.new()
		b.custom_minimum_size = Vector2(132, 50)
		b.add_theme_font_size_override("font_size", 17)
		b.text = cmd
		b.pressed.connect(_on_command.bind(cmd))
		command_panel.add_child(b)
	command_panel.visible = false
	_load_level(0)


func _load_level(idx: int) -> void:
	level_index = idx
	level = LEVELS[idx]
	phase = "prep"
	hold_timer = 0.0
	battle_time = 0.0
	wave_idx = 0
	escaped_count = 0
	selected_company = -1
	move_mode = false
	for c in units_root.get_children():
		c.queue_free()
	for c in arrows_root.get_children():
		c.queue_free()

	companies.clear()
	var count_by_kind := {}
	for c in level["companies"]:
		var k: String = c["kind"]
		count_by_kind[k] = count_by_kind.get(k, 0) + 1
		var nm: String = c.get("name", "%s %s" % [["1st", "2nd", "3rd"][count_by_kind[k] - 1], STATS[k]["name"]])
		companies.append({"kind": k, "n": int(c["n"]), "name": nm, "placed": false, "units": []})
	for b in company_buttons:
		b.queue_free()
	company_buttons.clear()
	for i in range(companies.size()):
		var b := Button.new()
		b.custom_minimum_size = Vector2(138, 46)
		b.add_theme_font_size_override("font_size", 13)
		b.pressed.connect(_on_company_button.bind(i))
		roster_bar.add_child(b)
		company_buttons.append(b)
	chosen_company = 0

	title_label.text = "%s  (%s)" % [level["name"], level["ref"]]
	brief_label.text = level["brief"]
	begin_button.visible = true
	begin_button.text = "Begin Battle"
	charge_button.visible = false
	command_panel.visible = false
	_refresh_companies()
	_update_status()
	queue_redraw()


func _alive(ci: int) -> Array:
	var out: Array = []
	if ci < 0 or ci >= companies.size():
		return out
	for u in companies[ci]["units"]:
		if is_instance_valid(u) and not u.dead:
			out.append(u)
	return out


func _refresh_companies() -> void:
	if badge_layer:
		badge_layer.queue_redraw()
	for i in range(companies.size()):
		var c: Dictionary = companies[i]
		var b: Button = company_buttons[i]
		if phase == "prep":
			var mark := "  <" if i == chosen_company else ""
			b.text = "%d. %s x%d\n%s%s" % [i + 1, c["name"], c["n"], "placed" if c["placed"] else "tap to place", mark]
			b.disabled = false
		else:
			var alive := _alive(i).size()
			var state := "fallen" if alive == 0 else _company_order(i)
			b.text = "%d. %s (%d)\n%s%s" % [i + 1, c["name"], alive, state, "  <" if i == selected_company else ""]
			b.disabled = alive == 0 or phase != "battle"


func _company_order(ci: int) -> String:
	for u in _alive(ci):
		if u.concealed:
			return "hidden"
		return {"hold": "holding", "move": "marching", "attack": "attacking"}.get(u.order, u.order)
	return ""


func _on_company_button(i: int) -> void:
	if phase == "prep":
		chosen_company = i
		_refresh_companies()
		_update_status()
	elif phase == "battle":
		_select_company(-1 if i == selected_company else i)


func _select_company(i: int) -> void:
	for c in companies:
		for u in c["units"]:
			if is_instance_valid(u):
				u.selected = false
	selected_company = i
	move_mode = false
	for u in _alive(i):
		u.selected = true
	command_panel.visible = i >= 0 and phase == "battle"
	_refresh_companies()
	_update_status()


func _on_command(cmd: String) -> void:
	if phase != "battle" or selected_company < 0:
		return
	var nm: String = companies[selected_company]["name"]
	match cmd:
		"ATTACK":
			for u in _alive(selected_company):
				u.charge()
			_select_company(-1)
			_flash_status("%s: ATTACK!" % nm)
		"MOVE":
			move_mode = true
			_update_status()
		"HOLD":
			for u in _alive(selected_company):
				u.order_hold()
			_select_company(-1)
			_flash_status("%s: hold this ground." % nm)


func _flash_status(t: String) -> void:
	status_label.text = t
	flash_status_t = 1.6


func _slot(i: int, n: int) -> Vector2:
	var cols: int = mini(n, 3)
	var rows: int = int(ceil(float(n) / cols))
	return Vector2((i % cols - (cols - 1) * 0.5) * SLOT_GAP, (i / cols - (rows - 1) * 0.5) * SLOT_GAP)


func _move_company(ci: int, p: Vector2) -> void:
	var men := _alive(ci)
	for k in range(men.size()):
		men[k].order_move(p + _slot(k, men.size()))
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if finished:
		return
	if event is InputEventMouseButton and event.pressed:
		var mb := event as InputEventMouseButton
		var p: Vector2 = get_global_mouse_position()
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if phase == "prep":
				_try_place(p)
			elif phase == "battle":
				_battle_tap(p)
		elif mb.button_index == MOUSE_BUTTON_RIGHT and phase == "battle" and selected_company >= 0:
			var nm: String = companies[selected_company]["name"]
			_move_company(selected_company, p)
			_select_company(-1)
			_flash_status("%s: marching." % nm)


func _battle_tap(p: Vector2) -> void:
	if move_mode and selected_company >= 0:
		var nm: String = companies[selected_company]["name"]
		_move_company(selected_company, p)
		_select_company(-1)
		_flash_status("%s: marching." % nm)
		return
	# tap one of your men to select his whole company; tap open ground to deselect
	var best := -1
	var best_d := 40.0
	for i in range(companies.size()):
		for u in _alive(i):
			var d: float = u.global_position.distance_to(p)
			if d < best_d:
				best_d = d
				best = i
	_select_company(best)


func _try_place(p: Vector2) -> void:
	var c: Dictionary = companies[chosen_company]
	var zone = null
	for z in level["zones"]:
		if (z as Rect2).has_point(p):
			zone = z
			break
	if zone == null:
		status_label.text = "Place your companies inside the highlighted ground."
		return
	# keep the whole formation inside the zone
	var n: int = c["n"]
	var cols: int = mini(n, 3)
	var rows: int = int(ceil(float(n) / cols))
	var half := Vector2((cols - 1) * 0.5 * SLOT_GAP + 10.0, (rows - 1) * 0.5 * SLOT_GAP + 10.0)
	var z: Rect2 = zone
	var center := Vector2(
		clampf(p.x, z.position.x + half.x, z.end.x - half.x),
		clampf(p.y, z.position.y + half.y, z.end.y - half.y))
	for u in c["units"]:
		if is_instance_valid(u):
			u.queue_free()
	c["units"] = []
	for k in range(n):
		var pos := center + _slot(k, n)
		var u := _spawn(0, c["kind"], pos)
		u.company = chosen_company
		for f in level.get("forest", []):
			if (f as Rect2).has_point(pos):
				u.set_concealed(true)
				break
		c["units"].append(u)
	c["placed"] = true
	# move on to the next company still waiting to be placed
	for k in range(companies.size()):
		var j: int = (chosen_company + 1 + k) % companies.size()
		if not companies[j]["placed"]:
			chosen_company = j
			break
	_refresh_companies()
	_update_status()


func _spawn(team: int, kind: String, pos: Vector2) -> Node2D:
	var u := UNIT_SCENE.instantiate()
	u.position = pos
	units_root.add_child(u)
	u.configure(team, kind, STATS[kind])
	u.arrows_root = arrows_root
	u.forests = level.get("forest", [])
	u.died.connect(_on_unit_died)
	return u


func _begin_battle() -> void:
	if phase != "prep":
		return
	var left := 0
	for c in companies:
		if not c["placed"]:
			left += 1
	if left > 0:
		status_label.text = "Place every company first (%d still waiting)." % left
		return
	phase = "battle"
	begin_button.visible = false
	charge_button.visible = true
	charge_button.text = "ALL ATTACK!"
	for e in level.get("enemy", []):
		for i in range(int(e["n"])):
			var pos: Vector2 = e["at"] + Vector2(randf_range(-26, 26), randf_range(-24, 24))
			var u := _spawn(1, e["kind"], pos)
			if not (e["path"] as Array).is_empty():
				u.set_patrol(e["path"])
			elif level["objective"] == "capture":
				u.guard_radius = 230.0
	_refresh_companies()
	_update_status()
	queue_redraw()


func _charge_all() -> void:
	if phase != "battle":
		return
	for i in range(companies.size()):
		for u in _alive(i):
			u.charge()
	_select_company(-1)
	_flash_status("ALL COMPANIES -- ATTACK!")


func _process(delta: float) -> void:
	if finished or phase != "battle":
		return
	battle_time += delta
	flash_status_t = maxf(0.0, flash_status_t - delta)
	queue_redraw()
	_refresh_companies()

	# level 2 sends timed assault waves at the gap
	if level["objective"] == "hold":
		hold_timer += delta
		var waves: Array = level.get("waves", [])
		while wave_idx < waves.size() and battle_time >= float(waves[wave_idx]["t"]):
			var w: Dictionary = waves[wave_idx]
			for i in range(int(w["n"])):
				var u := _spawn(1, w["kind"], Vector2(randf_range(880, 940), randf_range(140, 420)))
				u.order_move(Vector2(316, 290))
				u.aggressive = true
			wave_idx += 1
		if hold_timer >= float(level["hold_time"]):
			_finish(true)
			return

	# level 3: once the garrison is lured out, the city is open
	if level["objective"] == "capture":
		var city: Rect2 = level["city"]
		# the garrison takes the bait only against a small band; a big army sees it hold the walls
		var near_count := 0
		var seen_count := 0
		for u in units_root.get_children():
			if u.team == 0 and not u.dead and not u.concealed:
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
	if phase == "battle":
		call_deferred("_refresh_companies")


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
			status_label.text = "PREPARE -- red dashes are the scouts' report. Tap the lit ground to place %s. Men in the trees stay hidden." % companies[chosen_company]["name"]
		"battle":
			if flash_status_t > 0.0:
				return
			var extra := ""
			if level["objective"] == "hold":
				extra = "   Hold: %ds" % int(maxf(float(level["hold_time"]) - hold_timer, 0.0))
			elif level["objective"] == "destroy_all":
				extra = "   Escaped: %d / %d" % [escaped_count, ESCAPE_LIMIT]
			elif level["objective"] == "capture":
				extra = "   City holds while any defender is inside"
			var lead := "Your men wait for orders -- tap a company."
			if selected_company >= 0:
				var nm: String = companies[selected_company]["name"]
				lead = ("%s: tap where they should go." % nm) if move_mode else ("%s: ATTACK, MOVE, or HOLD?" % nm)
			status_label.text = "%s   Yours %d  Theirs %d%s" % [lead, friends, foes, extra]
		_:
			pass


func _finish(won: bool) -> void:
	if finished:
		return
	_select_company(-1)
	command_panel.visible = false
	if won and level_index < LEVELS.size() - 1:
		score += 150
		phase = "done"
		_refresh_companies()
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

	# where each marching company is headed
	for i in range(companies.size()):
		for u in _alive(i):
			if u.order == "move" and u.move_target != null:
				draw_circle(u.move_target, 3.0, Color(0.6, 1.0, 0.6, 0.6))


func _draw_badges() -> void:
	# a numbered banner over each company so you know which is which
	var font := ThemeDB.fallback_font
	for i in range(companies.size()):
		var men := _alive(i)
		if men.is_empty():
			continue
		var c := Vector2.ZERO
		var top := INF
		for u in men:
			c += u.global_position
			top = minf(top, u.global_position.y)
		c /= men.size()
		var at := Vector2(c.x, top - 32.0)
		var col := Color(0.55, 1.0, 0.55, 1) if i == selected_company else Color(0.35, 0.55, 0.95, 0.95)
		badge_layer.draw_line(at + Vector2(-9, 0), at + Vector2(-9, 18), Color(0.15, 0.12, 0.1, 1), 2.0)
		badge_layer.draw_rect(Rect2(at + Vector2(-9, -2), Vector2(18, 14)), col)
		badge_layer.draw_string(font, at + Vector2(-4, 10), str(i + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.05, 0.05, 0.08, 1))


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
