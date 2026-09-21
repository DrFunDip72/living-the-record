extends Node2D

signal game_finished(won: bool, score: int)

const GUARD_SCENE := preload("res://scenes/Guard.tscn")
const PLAY_BOUNDS := Rect2(60, 90, 840, 400)

# Three camps, escalating. Each: guard count, tree layout, start, escape point.
const CAMPS := [
	{
		"guards": 3,
		"trees": [Vector2(300, 200), Vector2(520, 330), Vector2(420, 140), Vector2(660, 230), Vector2(250, 400)],
		"start": Vector2(90, 460),
		"goal": Vector2(880, 130),
	},
	{
		"guards": 4,
		"trees": [Vector2(260, 160), Vector2(420, 290), Vector2(600, 170), Vector2(700, 360), Vector2(340, 430), Vector2(520, 470)],
		"start": Vector2(90, 120),
		"goal": Vector2(880, 450),
	},
	{
		"guards": 5,
		"trees": [Vector2(240, 250), Vector2(390, 150), Vector2(390, 380), Vector2(560, 260), Vector2(700, 150), Vector2(720, 400), Vector2(500, 450)],
		"start": Vector2(90, 280),
		"goal": Vector2(880, 280),
	},
]

var camp: int = 0
var score: int = 0
var finished: bool = false
var spotted_count: int = 0

@onready var player: CharacterBody2D = $Player
@onready var camera: Camera2D = $Player/Camera2D
@onready var guards_root: Node2D = $Guards
@onready var trees_root: Node2D = $Trees
@onready var goal_area: Area2D = $Goal
@onready var goal_marker: Node2D = $Goal/Marker
@onready var status_label: Label = $UI/StatusLabel
@onready var camp_label: Label = $UI/CampLabel
@onready var alarm_label: Label = $UI/AlarmLabel


func _ready() -> void:
	randomize()
	goal_area.body_entered.connect(_on_goal_entered)
	status_label.text = "Reach the escape point. Break line of sight to lose them."
	_build_camp()


func _build_camp() -> void:
	for c in guards_root.get_children():
		c.queue_free()
	for t in trees_root.get_children():
		t.queue_free()

	var data: Dictionary = CAMPS[camp]
	camp_label.text = "Camp %d of %d" % [camp + 1, CAMPS.size()]

	for tpos in data["trees"]:
		trees_root.add_child(_make_tree(tpos))

	player.position = data["start"]
	goal_area.position = data["goal"]

	# guards spawn away from the player's start
	for i in range(int(data["guards"])):
		var g := GUARD_SCENE.instantiate()
		var gp := Vector2(
			randf_range(PLAY_BOUNDS.position.x + 200.0, PLAY_BOUNDS.position.x + PLAY_BOUNDS.size.x),
			randf_range(PLAY_BOUNDS.position.y, PLAY_BOUNDS.position.y + PLAY_BOUNDS.size.y)
		)
		if gp.distance_to(player.position) < 220.0:
			gp.x += 220.0
		g.position = gp
		guards_root.add_child(g)
		g.setup(player, PLAY_BOUNDS)
		g.shouted.connect(_on_guard_shout)
		g.caught_player.connect(_on_caught)


func _make_tree(pos: Vector2) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.position = pos
	body.collision_layer = 2
	body.collision_mask = 0

	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 26.0
	shape.shape = circle
	body.add_child(shape)

	var trunk := Polygon2D.new()
	trunk.polygon = PackedVector2Array([Vector2(-6, 8), Vector2(6, 8), Vector2(6, 30), Vector2(-6, 30)])
	trunk.color = Color(0.3, 0.19, 0.1, 1)
	body.add_child(trunk)

	var canopy := Polygon2D.new()
	var pts := PackedVector2Array()
	for i in range(10):
		var a: float = TAU * float(i) / 10.0
		pts.append(Vector2(cos(a), sin(a)) * (30.0 if i % 2 == 0 else 25.0))
	canopy.polygon = pts
	canopy.color = Color(0.11, 0.26, 0.13, 1)
	body.add_child(canopy)
	return body


func _on_guard_shout(pos: Vector2) -> void:
	if finished:
		return
	spotted_count += 1
	camera.shake(0.45)
	alarm_label.text = "SPOTTED -- they're calling for help!"
	alarm_label.modulate = Color(1, 0.4, 0.3, 1)
	get_tree().create_timer(1.6).timeout.connect(func():
		if is_instance_valid(alarm_label):
			alarm_label.text = ""
	)
	for g in guards_root.get_children():
		if is_instance_valid(g) and g.global_position.distance_to(pos) < 300.0:
			g.alert(pos)


func _on_caught() -> void:
	if finished:
		return
	camera.shake(0.9)
	_finish(false)


func _on_goal_entered(body: Node) -> void:
	if finished or not body.is_in_group("player"):
		return
	score += 100
	camp += 1
	if camp >= CAMPS.size():
		_finish(true)
	else:
		goal_marker.scale = Vector2(1.4, 1.4)
		_build_camp()


func _finish(won: bool) -> void:
	finished = true
	if won:
		score += maxi(0, 60 - spotted_count * 15)
	var flash := ColorRect.new()
	flash.color = Color(0.3, 1, 0.3, 0.4) if won else Color(1, 0.2, 0.2, 0.45)
	flash.anchor_right = 1.0
	flash.anchor_bottom = 1.0
	add_child(flash)
	get_tree().create_timer(0.4).timeout.connect(func(): game_finished.emit(won, score))
