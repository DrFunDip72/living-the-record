extends Node2D

signal game_finished(won: bool, score: int)

const ROUND_TIME := 45.0
const UNIT_SHAPE := preload("res://scenes/common/UnitShape.tscn")

const PROFILES := [
	{"speed": 90.0, "radius": 22.0, "points": 10, "color": Color(0.55, 0.4, 0.25, 1)},
	{"speed": 150.0, "radius": 16.0, "points": 20, "color": Color(0.4, 0.3, 0.2, 1)},
	{"speed": 230.0, "radius": 11.0, "points": 35, "color": Color(0.8, 0.75, 0.65, 1)},
]

var time_left: float = ROUND_TIME
var score: int = 0
var combo: int = 1
var spawn_timer: float = 0.6
var finished: bool = false
var _mouse_was_pressed: bool = false

@onready var timer_label: Label = $UI/TimerLabel
@onready var score_label: Label = $UI/ScoreLabel
@onready var combo_label: Label = $UI/ComboLabel
@onready var animals_container: Node2D = $AnimalsContainer
@onready var reticle: Node2D = $Reticle


func _ready() -> void:
	randomize()
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	_update_labels()


func _exit_tree() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _process(delta: float) -> void:
	if finished:
		return

	reticle.position = get_viewport().get_mouse_position()

	time_left -= delta
	if time_left <= 0.0:
		_finish()
		return

	spawn_timer -= delta
	if spawn_timer <= 0.0:
		_spawn_animal()
		spawn_timer = randf_range(0.5, 1.2)

	for a in animals_container.get_children():
		var dir: int = a.get_meta("dir")
		var speed: float = a.get_meta("speed")
		a.position.x += speed * dir * delta
		if a.position.x < -80.0 or a.position.x > 1040.0:
			a.queue_free()

	var mouse_pressed := Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	if mouse_pressed and not _mouse_was_pressed:
		_try_shoot(reticle.position)
	_mouse_was_pressed = mouse_pressed

	_update_labels()


func _spawn_animal() -> void:
	var profile: Dictionary = PROFILES[randi() % PROFILES.size()]
	var a := Node2D.new()
	var vis := UNIT_SHAPE.instantiate()
	a.add_child(vis)
	vis.fill_color = profile["color"]
	vis.outline_color = profile["color"].darkened(0.5)
	vis.radius = profile["radius"]
	var dir: int = 1 if randf() < 0.5 else -1
	a.position = Vector2(-40.0 if dir > 0 else 1000.0, randf_range(340.0, 480.0))
	a.set_meta("speed", profile["speed"])
	a.set_meta("dir", dir)
	a.set_meta("points", profile["points"])
	a.set_meta("hit_radius", profile["radius"] + 16.0)
	animals_container.add_child(a)


func _try_shoot(pos: Vector2) -> void:
	var best: Node2D = null
	var best_dist := INF
	for a in animals_container.get_children():
		var d: float = a.position.distance_to(pos)
		var hit_r: float = a.get_meta("hit_radius")
		if d <= hit_r and d < best_dist:
			best_dist = d
			best = a
	if best:
		var pts: int = int(best.get_meta("points")) * combo
		score += pts
		combo = min(combo + 1, 8)
		Fx.spawn_hit_burst(self, best.position, Color(1, 0.9, 0.3, 1), 12)
		best.queue_free()
	else:
		combo = 1
		Fx.spawn_hit_burst(self, pos, Color(0.7, 0.7, 0.7, 0.6), 6)


func _update_labels() -> void:
	timer_label.text = "Time: %d" % int(max(ceil(time_left), 0))
	score_label.text = "Score: %d" % score
	combo_label.text = "Combo x%d" % combo


func _finish() -> void:
	finished = true
	get_tree().create_timer(0.4).timeout.connect(func(): game_finished.emit(true, score))
