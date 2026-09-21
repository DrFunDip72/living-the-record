extends Node2D

signal game_finished(won: bool, score: int)

# Stack-the-courses temple builder. Each stone you set is trimmed to whatever
# overlapped the stone below -- sloppy work leaves you less to build with.

const COURSE_H := 30.0
const BASE_W := 210.0
const TARGET_COURSES := 12
const PERFECT_TOL := 6.0
const GROUND_Y := 470.0

const STONE_COLS := [
	Color(0.55, 0.52, 0.46, 1), Color(0.62, 0.58, 0.5, 1),
	Color(0.5, 0.47, 0.42, 1), Color(0.66, 0.61, 0.52, 1),
]

var stack: Array = []          # [{x, w, y, col}]
var cur_x: float = 480.0
var cur_w: float = BASE_W
var cur_y: float = 0.0
var swing_t: float = 0.0
var swing_speed: float = 1.5
var swing_amp: float = 210.0
var scroll: float = 0.0
var courses: int = 0
var perfects: int = 0
var score: int = 0
var finished: bool = false
var placing: bool = true
var _mouse_was_pressed: bool = false
var falling: Array = []        # trimmed offcuts

@onready var course_label: Label = $UI/CourseLabel
@onready var score_label: Label = $UI/ScoreLabel
@onready var msg_label: Label = $UI/MessageLabel
@onready var hint_label: Label = $UI/HintLabel


func _ready() -> void:
	randomize()
	hint_label.text = "Click (or SPACE) to set each stone. Overhang is cut away -- keep the courses square."
	var base_y: float = GROUND_Y - COURSE_H
	stack.append({"x": 480.0, "w": BASE_W, "y": base_y, "col": STONE_COLS[0]})
	courses = 1
	_next_stone()
	_update_hud()


func _next_stone() -> void:
	var top: Dictionary = stack[stack.size() - 1]
	cur_w = top["w"]
	cur_y = top["y"] - COURSE_H
	swing_speed = 1.4 + courses * 0.14
	swing_amp = clampf(200.0 + courses * 6.0, 160.0, 330.0)
	swing_t = randf() * TAU
	placing = true


func _process(delta: float) -> void:
	if finished:
		return

	if placing:
		swing_t += swing_speed * delta
		cur_x = 480.0 + sin(swing_t) * swing_amp

	for f in falling:
		f["vy"] += 900.0 * delta
		f["y"] += f["vy"] * delta
		f["rot"] += f["spin"] * delta
	falling = falling.filter(func(f): return f["y"] < 700.0)

	var pressed := Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	var clicked := (pressed and not _mouse_was_pressed) or Input.is_action_just_pressed("ui_accept") or Input.is_key_pressed(KEY_SPACE)
	_mouse_was_pressed = pressed
	if placing and clicked:
		_place()

	queue_redraw()


func _place() -> void:
	placing = false
	var top: Dictionary = stack[stack.size() - 1]
	var left: float = maxf(cur_x - cur_w * 0.5, top["x"] - top["w"] * 0.5)
	var right: float = minf(cur_x + cur_w * 0.5, top["x"] + top["w"] * 0.5)

	if right - left <= 6.0:
		_drop_offcut(cur_x, cur_w)
		msg_label.text = "The stone missed the course entirely."
		_finish(false)
		return

	var offset: float = absf(cur_x - top["x"])
	var new_w: float = right - left
	var new_x: float = (left + right) * 0.5

	# trimmed offcuts tumble away
	if cur_x - cur_w * 0.5 < left:
		_drop_offcut((cur_x - cur_w * 0.5 + left) * 0.5, left - (cur_x - cur_w * 0.5))
	if cur_x + cur_w * 0.5 > right:
		_drop_offcut((right + cur_x + cur_w * 0.5) * 0.5, (cur_x + cur_w * 0.5) - right)

	if offset <= PERFECT_TOL:
		perfects += 1
		score += 25
		new_w = minf(new_w + 8.0, BASE_W)
		new_x = top["x"]
		msg_label.text = "Set true!  +25"
		Fx.spawn_hit_burst(self, Vector2(new_x, cur_y - scroll), Color(1, 0.9, 0.5, 1), 12)
	else:
		score += 10
		msg_label.text = ""

	stack.append({"x": new_x, "w": new_w, "y": cur_y, "col": STONE_COLS[courses % STONE_COLS.size()]})
	courses += 1
	score += 10

	# keep the working course near the middle of the screen
	if cur_y - scroll < 250.0:
		scroll -= COURSE_H

	if courses >= TARGET_COURSES:
		msg_label.text = "The temple stands."
		_finish(true)
		return

	_update_hud()
	get_tree().create_timer(0.12).timeout.connect(_next_stone)


func _drop_offcut(x: float, w: float) -> void:
	if w <= 1.0:
		return
	falling.append({"x": x, "w": w, "y": cur_y, "vy": 0.0, "rot": 0.0, "spin": randf_range(-4.0, 4.0)})


func _update_hud() -> void:
	course_label.text = "Course %d / %d" % [courses, TARGET_COURSES]
	score_label.text = "Score: %d    Set true: %d" % [score, perfects]


func _finish(won: bool) -> void:
	finished = true
	if won:
		score += 200 + perfects * 15
	_update_hud()
	var flash := ColorRect.new()
	flash.color = Color(1, 0.9, 0.5, 0.4) if won else Color(1, 0.25, 0.2, 0.42)
	flash.anchor_right = 1.0
	flash.anchor_bottom = 1.0
	add_child(flash)
	get_tree().create_timer(0.5).timeout.connect(func(): game_finished.emit(won, score))


func _draw() -> void:
	# ground
	draw_rect(Rect2(0, GROUND_Y - scroll, 960, 540), Color(0.3, 0.28, 0.2, 1))
	draw_rect(Rect2(0, GROUND_Y - scroll, 960, 6), Color(0.42, 0.39, 0.28, 1))

	# placed courses
	for b in stack:
		var y: float = b["y"] - scroll
		draw_rect(Rect2(b["x"] - b["w"] * 0.5, y, b["w"], COURSE_H), Color(0.12, 0.1, 0.09, 1))
		draw_rect(Rect2(b["x"] - b["w"] * 0.5 + 2.0, y + 2.0, b["w"] - 4.0, COURSE_H - 4.0), b["col"])
		# masonry joints
		var jx: float = b["x"] - b["w"] * 0.5 + 18.0
		while jx < b["x"] + b["w"] * 0.5 - 8.0:
			draw_line(Vector2(jx, y + 3), Vector2(jx, y + COURSE_H - 3), Color(0, 0, 0, 0.18), 1.5)
			jx += 26.0

	# finished roof
	if finished and courses >= TARGET_COURSES:
		var top: Dictionary = stack[stack.size() - 1]
		var ty: float = top["y"] - scroll
		var roof := PackedVector2Array([
			Vector2(top["x"] - top["w"] * 0.7, ty), Vector2(top["x"] + top["w"] * 0.7, ty),
			Vector2(top["x"], ty - 54.0),
		])
		draw_colored_polygon(roof, Color(0.85, 0.72, 0.35, 1))

	# tumbling offcuts
	for f in falling:
		draw_set_transform(Vector2(f["x"], f["y"] - scroll), f["rot"], Vector2.ONE)
		draw_rect(Rect2(-f["w"] * 0.5, 0, f["w"], COURSE_H), Color(0.45, 0.42, 0.37, 0.9))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	# swinging stone + crane line
	if placing and not finished:
		var y: float = cur_y - scroll
		draw_line(Vector2(cur_x, 0), Vector2(cur_x, y), Color(0.25, 0.22, 0.2, 0.8), 2.0)
		draw_rect(Rect2(cur_x - cur_w * 0.5, y, cur_w, COURSE_H), Color(0.12, 0.1, 0.09, 1))
		draw_rect(Rect2(cur_x - cur_w * 0.5 + 2.0, y + 2.0, cur_w - 4.0, COURSE_H - 4.0), Color(0.72, 0.66, 0.54, 1))
		# alignment guide against the course below
		var top2: Dictionary = stack[stack.size() - 1]
		draw_line(Vector2(top2["x"], y + COURSE_H + 4), Vector2(top2["x"], top2["y"] - scroll), Color(1, 0.9, 0.4, 0.35), 1.5)
