extends Node2D

signal defeated

@export var speed: float = 70.0
@export var max_hp: int = 3
@export var attack_range: float = 40.0
@export var base_attack_cooldown: float = 1.5
@export var buffed_attack_cooldown: float = 0.7
@export var damage: int = 1

var hp: int
var attack_timer: float = 0.0
var buffed: bool = false
var home_position: Vector2
var base_fill: Color
var base_outline: Color

@onready var visual: Node2D = $Visual
@onready var weapon: Node2D = get_node_or_null("Weapon")


func _ready() -> void:
	hp = max_hp
	home_position = position
	base_fill = visual.fill_color
	base_outline = visual.outline_color


func _process(delta: float) -> void:
	attack_timer = max(0.0, attack_timer - delta)
	var target := _find_nearest_enemy()
	if target:
		var to_target: Vector2 = target.global_position - global_position
		if weapon:
			weapon.set_aim(to_target.angle())
		if to_target.length() > attack_range:
			position += to_target.normalized() * speed * delta
		elif attack_timer <= 0.0:
			attack_timer = buffed_attack_cooldown if buffed else base_attack_cooldown
			target.take_damage(damage, global_position)
			visual.pop(1.15)
			if weapon:
				weapon.swing()
	else:
		var to_home: Vector2 = home_position - position
		if to_home.length() > 4.0:
			position += to_home.normalized() * speed * 0.5 * delta


func _find_nearest_enemy() -> Node:
	var enemies := get_tree().get_nodes_in_group("enemy")
	var nearest: Node = null
	var nearest_dist := INF
	for e in enemies:
		if not is_instance_valid(e):
			continue
		var d: float = global_position.distance_to(e.global_position)
		if d < nearest_dist:
			nearest_dist = d
			nearest = e
	return nearest


func set_buffed(value: bool) -> void:
	if buffed == value:
		return
	buffed = value
	visual.set_colors(Color(0.5, 0.75, 1.0, 1) if value else base_fill, base_outline)


func take_damage(amount: int, from_pos: Vector2) -> void:
	hp -= amount
	visual.flash_white()
	if hp <= 0:
		defeated.emit()
		queue_free()
