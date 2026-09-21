extends CharacterBody2D

signal defeated
signal hit_target(amount: int, from_pos: Vector2)

@export var speed: float = 60.0
@export var max_hp: int = 2
@export var contact_damage: int = 1
@export var attack_cooldown: float = 1.3
@export var windup_time: float = 0.35
@export var stop_distance: float = 34.0

var hp: int
var attack_timer: float = 0.0
var winding_up: bool = false
var wind_timer: float = 0.0
var knockback: Vector2 = Vector2.ZERO
var target: Node2D = null
var _base_fill: Color
var _base_outline: Color

@onready var visual: Node2D = $Visual
@onready var weapon: Node2D = $Weapon


func _ready() -> void:
	hp = max_hp
	add_to_group("enemy")
	_base_fill = visual.fill_color
	_base_outline = visual.outline_color


func setup(p_target: Node2D) -> void:
	target = p_target


func _physics_process(delta: float) -> void:
	if target == null or not is_instance_valid(target):
		return
	var to_target: Vector2 = target.global_position - global_position
	var dist := to_target.length()
	var move := Vector2.ZERO

	weapon.set_aim(to_target.angle())

	if winding_up:
		wind_timer -= delta
		weapon.set_windup(1.0 - maxf(wind_timer, 0.0) / maxf(windup_time, 0.001))
		if wind_timer <= 0.0:
			winding_up = false
			attack_timer = attack_cooldown
			visual.set_colors(_base_fill, _base_outline)
			weapon.set_windup(0.0)
			weapon.swing()
			if dist <= stop_distance * 1.4:
				hit_target.emit(contact_damage, global_position)
	else:
		attack_timer = max(0.0, attack_timer - delta)
		if dist > stop_distance:
			move = to_target.normalized() * speed
		elif attack_timer <= 0.0:
			_start_windup()

	velocity = move + knockback
	knockback = knockback.move_toward(Vector2.ZERO, 400.0 * delta)
	move_and_slide()


func _start_windup() -> void:
	winding_up = true
	wind_timer = windup_time
	visual.set_colors(Color(1, 0.9, 0.2, 1), Color(0.5, 0.4, 0.05, 1))
	visual.pop(1.5)


func take_damage(amount: int, from_pos: Vector2) -> void:
	hp -= amount
	knockback = (global_position - from_pos).normalized() * 220.0
	visual.flash_white()
	Fx.spawn_hit_burst(get_parent(), global_position, Color(0.85, 0.2, 0.2, 1), 10)
	if winding_up:
		winding_up = false
		visual.set_colors(_base_fill, _base_outline)
		weapon.set_windup(0.0)
	if hp <= 0:
		defeated.emit()
		queue_free()
