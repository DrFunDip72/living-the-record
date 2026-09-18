extends CharacterBody2D

@export var speed: float = 220.0


func _ready() -> void:
	add_to_group("player")


func _physics_process(_delta: float) -> void:
	var x := Input.get_axis("ui_left", "ui_right")
	var y := Input.get_axis("ui_up", "ui_down")
	if Input.is_key_pressed(KEY_A):
		x -= 1.0
	if Input.is_key_pressed(KEY_D):
		x += 1.0
	if Input.is_key_pressed(KEY_W):
		y -= 1.0
	if Input.is_key_pressed(KEY_S):
		y += 1.0
	var dir := Vector2(x, y)
	if dir.length() > 1.0:
		dir = dir.normalized()
	velocity = dir * speed
	move_and_slide()
	position.x = clamp(position.x, 20.0, 940.0)
	position.y = clamp(position.y, 20.0, 520.0)
