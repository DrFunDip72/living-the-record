extends Node2D

var direction: Vector2 = Vector2.RIGHT
var speed: float = 420.0
var damage: int = 1
var lifetime: float = 1.2
var _age: float = 0.0
var _spent: bool = false


func _process(delta: float) -> void:
	if _spent:
		return
	position += direction * speed * delta
	_age += delta
	if _age > lifetime or position.x < -40 or position.x > 1000 or position.y < -40 or position.y > 580:
		queue_free()
		return
	for e in get_tree().get_nodes_in_group("enemy"):
		if not is_instance_valid(e):
			continue
		if position.distance_to(e.global_position) < 20.0:
			_spent = true
			e.take_damage(damage, position)
			queue_free()
			return
