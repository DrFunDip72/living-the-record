extends Node2D

@export var attack_range: float = 160.0
@export var cooldown: float = 1.0

var projectiles_container: Node
var timer: float = 0.0


func _process(delta: float) -> void:
	timer = max(0.0, timer - delta)
	if timer <= 0.0:
		var target := _find_target()
		if target:
			timer = cooldown
			_fire(target)


func _find_target() -> Node:
	var best: Node = null
	var best_dist: float = attack_range
	for e in get_tree().get_nodes_in_group("enemy"):
		if not is_instance_valid(e):
			continue
		var d: float = global_position.distance_to(e.global_position)
		if d <= best_dist:
			best_dist = d
			best = e
	return best


func _fire(target: Node) -> void:
	var dir: Vector2 = (target.global_position - global_position).normalized()
	var stone := preload("res://scenes/SlingStone.tscn").instantiate()
	stone.position = global_position
	stone.direction = dir
	stone.speed = 360.0
	if projectiles_container:
		projectiles_container.add_child(stone)
