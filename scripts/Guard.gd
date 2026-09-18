extends Node2D

signal spotted_player

@export var speed: float = 80.0
@export var left_x: float = 200.0
@export var right_x: float = 700.0

var direction: int = 1

@onready var vision: Area2D = $Vision


func _ready() -> void:
	vision.body_entered.connect(_on_vision_body_entered)


func _process(delta: float) -> void:
	position.x += speed * direction * delta
	if position.x >= right_x:
		position.x = right_x
		_set_direction(-1)
	elif position.x <= left_x:
		position.x = left_x
		_set_direction(1)


func _set_direction(new_dir: int) -> void:
	if new_dir != direction:
		direction = new_dir
		scale.x = -1.0 if direction < 0 else 1.0


func _on_vision_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		spotted_player.emit()
