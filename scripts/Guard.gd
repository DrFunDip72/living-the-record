extends Node2D

signal spotted_player

@export var speed: float = 80.0
@export var left_x: float = 200.0
@export var right_x: float = 700.0

const ALERT_TIME := 0.35
const OBSTACLE_MASK := 2

var direction: int = 1
var alert_timer: float = 0.0

@onready var vision: Area2D = $Vision
@onready var alert_label: Label = $AlertLabel


func _ready() -> void:
	alert_label.visible = false


func _process(delta: float) -> void:
	position.x += speed * direction * delta
	if position.x >= right_x:
		position.x = right_x
		_set_direction(-1)
	elif position.x <= left_x:
		position.x = left_x
		_set_direction(1)

	if _can_see_player():
		alert_timer += delta
		alert_label.visible = true
		if alert_timer >= ALERT_TIME:
			spotted_player.emit()
	else:
		alert_timer = 0.0
		alert_label.visible = false


func _set_direction(new_dir: int) -> void:
	if new_dir != direction:
		direction = new_dir
		scale.x = -1.0 if direction < 0 else 1.0


func _can_see_player() -> bool:
	for body in vision.get_overlapping_bodies():
		if body.is_in_group("player"):
			var space_state := get_world_2d().direct_space_state
			var query := PhysicsRayQueryParameters2D.create(vision.global_position, body.global_position, OBSTACLE_MASK)
			var result := space_state.intersect_ray(query)
			if result.is_empty():
				return true
	return false
