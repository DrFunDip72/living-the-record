extends CharacterBody2D

@export var speed: float = 220.0
@export var bounds: Rect2 = Rect2(20, 20, 920, 500)
var last_direction: Vector2 = Vector2.DOWN


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
	if dir.length() > 0.1:
		last_direction = dir.normalized()
	velocity = dir * speed
	move_and_slide()
	position.x = clamp(position.x, bounds.position.x, bounds.position.x + bounds.size.x)
	position.y = clamp(position.y, bounds.position.y, bounds.position.y + bounds.size.y)
