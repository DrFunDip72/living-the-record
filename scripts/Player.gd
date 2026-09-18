extends CharacterBody2D

@export var speed: float = 220.0


func _ready() -> void:
	add_to_group("player")


func _physics_process(_delta: float) -> void:
	var dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = dir * speed
	move_and_slide()
	position.x = clamp(position.x, 20.0, 940.0)
	position.y = clamp(position.y, 20.0, 520.0)
