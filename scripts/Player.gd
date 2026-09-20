extends CharacterBody2D

@export var speed: float = 220.0
@export var bounds: Rect2 = Rect2(20, 20, 920, 500)
@export var mouse_controlled: bool = false
var last_direction: Vector2 = Vector2.DOWN
var knockback: Vector2 = Vector2.ZERO


func _ready() -> void:
	add_to_group("player")


func _physics_process(delta: float) -> void:
	var dir := Vector2.ZERO

	if mouse_controlled:
		var to_mouse: Vector2 = get_global_mouse_position() - global_position
		if to_mouse.length() > 6.0:
			dir = to_mouse.normalized()
		if to_mouse.length() > 0.1:
			last_direction = to_mouse.normalized()
	else:
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
		dir = Vector2(x, y)
		if dir.length() > 1.0:
			dir = dir.normalized()
		if dir.length() > 0.1:
			last_direction = dir.normalized()

	velocity = dir * speed + knockback
	knockback = knockback.move_toward(Vector2.ZERO, 500.0 * delta)
	move_and_slide()
	position.x = clamp(position.x, bounds.position.x, bounds.position.x + bounds.size.x)
	position.y = clamp(position.y, bounds.position.y, bounds.position.y + bounds.size.y)


func apply_knockback(dir: Vector2, strength: float) -> void:
	knockback = dir * strength


func get_aim_direction() -> Vector2:
	var to_mouse: Vector2 = get_global_mouse_position() - global_position
	if to_mouse.length() < 0.1:
		return last_direction
	return to_mouse.normalized()
