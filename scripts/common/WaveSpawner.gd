class_name WaveSpawner
extends Node

signal wave_cleared(wave_index: int)
signal all_waves_cleared
signal enemy_spawned(enemy: Node)

@export var enemy_scene: PackedScene
@export var mode: String = "fixed"  # "fixed" | "endless"
@export var base_count: int = 3
@export var count_growth: float = 1.15
@export var wave_pause: float = 2.0

var phases: Array = []  # fixed mode: [{"name", "count", "spawn_rect"}] or [{"name", "groups": [{"count", "spawn_rect", "type"}]}]
var container: Node2D
var target: Node2D

var _current_wave: int = 0
var _alive: Array = []
var _started: bool = false


func start(p_container: Node2D, p_target: Node2D) -> void:
	container = p_container
	target = p_target
	_current_wave = 0
	_started = true
	_start_wave()


func _start_wave() -> void:
	if not _started:
		return
	var rect: Rect2
	var count: int
	if mode == "fixed":
		if _current_wave >= phases.size():
			all_waves_cleared.emit()
			return
		var p: Dictionary = phases[_current_wave]
		if p.has("groups"):
			for g in p["groups"]:
				for i in range(int(g["count"])):
					_spawn_one(g["spawn_rect"], g.get("type", {}))
			return
		rect = p["spawn_rect"]
		count = p["count"]
	else:
		rect = Rect2(680, 90, 220, 380)
		count = int(floor(base_count * pow(count_growth, _current_wave)))
	for i in range(count):
		_spawn_one(rect)


func _spawn_one(rect: Rect2, type: Dictionary = {}) -> void:
	var e := enemy_scene.instantiate()
	# per-type tuning is applied before the enemy enters the tree, so _ready sees it
	for key in type:
		if key == "fill" or key == "outline" or key == "radius":
			var v := e.get_node_or_null("Visual")
			if v:
				v.set({"fill": "fill_color", "outline": "outline_color", "radius": "radius"}[key], type[key])
		else:
			e.set(key, type[key])
	e.position = Vector2(
		randf_range(rect.position.x, rect.position.x + rect.size.x),
		randf_range(rect.position.y, rect.position.y + rect.size.y)
	)
	container.add_child(e)
	e.setup(target)
	e.defeated.connect(_on_enemy_defeated.bind(e))
	_alive.append(e)
	enemy_spawned.emit(e)


func _on_enemy_defeated(e: Node) -> void:
	_alive.erase(e)
	if _alive.is_empty():
		var finished_wave := _current_wave
		_current_wave += 1
		wave_cleared.emit(finished_wave)
		if mode == "fixed" and _current_wave >= phases.size():
			all_waves_cleared.emit()
		else:
			get_tree().create_timer(wave_pause).timeout.connect(_start_wave)


func current_wave_name() -> String:
	if mode == "fixed" and _current_wave < phases.size():
		return phases[_current_wave]["name"]
	return "WAVE %d" % (_current_wave + 1)
