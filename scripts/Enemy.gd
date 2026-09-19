extends CharacterBody2D

signal defeated
signal hit_target(amount: int)

@export var speed: float = 60.0
@export var max_hp: int = 2
@export var contact_damage: int = 1
@export var attack_cooldown: float = 1.0
@export var stop_distance: float = 34.0

var hp: int
var attack_timer: float = 0.0
var knockback: Vector2 = Vector2.ZERO
var target: Node2D = null

@onready var shape: Polygon2D = $Shape


func _ready() -> void:
	hp = max_hp
	add_to_group("enemy")


func setup(p_target: Node2D) -> void:
	target = p_target


func _physics_process(delta: float) -> void:
	if target == null or not is_instance_valid(target):
		return
	attack_timer = max(0.0, attack_timer - delta)
	var to_target: Vector2 = target.global_position - global_position
	var dist := to_target.length()
	var move := Vector2.ZERO
	if dist > stop_distance:
		move = to_target.normalized() * speed
	elif attack_timer <= 0.0:
		attack_timer = attack_cooldown
		hit_target.emit(contact_damage)

	velocity = move + knockback
	knockback = knockback.move_toward(Vector2.ZERO, 400.0 * delta)
	move_and_slide()


func take_damage(amount: int, from_pos: Vector2) -> void:
	hp -= amount
	knockback = (global_position - from_pos).normalized() * 220.0
	shape.color = Color(1, 1, 1, 1)
	get_tree().create_timer(0.1).timeout.connect(func():
		if is_instance_valid(shape):
			shape.color = Color(0.8, 0.25, 0.25, 1)
	)
	if hp <= 0:
		defeated.emit()
		queue_free()
