extends Node2D

signal game_finished(won: bool)

const ENEMY_SCENE_PATH := "res://scenes/Enemy.tscn"
const MAX_HP := 5
const ATTACK_COOLDOWN := 0.35
const ATTACK_RANGE := 50.0

var hp: int = MAX_HP
var attack_cooldown_timer: float = 0.0
var phase: int = 0
var finished: bool = false
var enemy_scene: PackedScene

var phases := [
	{"name": "HOLD THE LINE!", "count": 3, "spawn_rect": Rect2(680, 120, 220, 320)},
	{"name": "ADVANCE!", "count": 4, "spawn_rect": Rect2(760, 90, 220, 380)},
]

@onready var player: CharacterBody2D = $Player
@onready var order_label: Label = $UI/OrderBubble
@onready var hp_label: Label = $UI/HPLabel
@onready var hint_label: Label = $UI/HintLabel
@onready var enemies_container: Node2D = $EnemiesContainer


func _ready() -> void:
	enemy_scene = load(ENEMY_SCENE_PATH)
	hint_label.text = "WASD / Arrows to move. SPACE to swing your sword."
	_update_hp_label()
	_start_phase()


func _start_phase() -> void:
	var p: Dictionary = phases[phase]
	order_label.text = p["name"]
	var rect: Rect2 = p["spawn_rect"]
	for i in range(p["count"]):
		var e := enemy_scene.instantiate()
		e.position = Vector2(
			randf_range(rect.position.x, rect.position.x + rect.size.x),
			randf_range(rect.position.y, rect.position.y + rect.size.y)
		)
		enemies_container.add_child(e)
		e.setup(player)
		e.defeated.connect(_on_enemy_defeated)
		e.hit_target.connect(_on_player_hit)


func _physics_process(delta: float) -> void:
	if finished:
		return
	attack_cooldown_timer = max(0.0, attack_cooldown_timer - delta)
	if Input.is_action_just_pressed("ui_accept") or Input.is_key_pressed(KEY_SPACE):
		_try_attack()


func _try_attack() -> void:
	if attack_cooldown_timer > 0.0:
		return
	attack_cooldown_timer = ATTACK_COOLDOWN
	var facing: Vector2 = player.last_direction
	for e in enemies_container.get_children():
		if not is_instance_valid(e):
			continue
		var to_e: Vector2 = e.global_position - player.global_position
		if to_e.length() <= ATTACK_RANGE and facing.dot(to_e.normalized()) > 0.3:
			e.take_damage(1, player.global_position)
	_spawn_swing_fx(facing)


func _spawn_swing_fx(facing: Vector2) -> void:
	var fx := Polygon2D.new()
	var angle: float = facing.angle()
	var points := PackedVector2Array()
	points.append(Vector2.ZERO)
	for a in range(-3, 4):
		var ang: float = angle + a * 0.15
		points.append(Vector2(cos(ang), sin(ang)) * ATTACK_RANGE)
	fx.polygon = points
	fx.color = Color(1, 1, 0.8, 0.55)
	fx.position = player.position
	add_child(fx)
	get_tree().create_timer(0.12).timeout.connect(fx.queue_free)


func _on_player_hit(amount: int) -> void:
	if finished:
		return
	hp -= amount
	_update_hp_label()
	if hp <= 0:
		_finish(false)


func _update_hp_label() -> void:
	hp_label.text = "HP: " + "#".repeat(max(hp, 0)) + "-".repeat(max(MAX_HP - hp, 0))


func _on_enemy_defeated() -> void:
	await get_tree().process_frame
	if finished:
		return
	if enemies_container.get_child_count() == 0:
		phase += 1
		if phase >= phases.size():
			_finish(true)
		else:
			_start_phase()


func _finish(won: bool) -> void:
	finished = true
	var flash := ColorRect.new()
	flash.color = Color(0.3, 1, 0.3, 0.4) if won else Color(1, 0.2, 0.2, 0.4)
	flash.anchor_right = 1.0
	flash.anchor_bottom = 1.0
	add_child(flash)
	get_tree().create_timer(0.35).timeout.connect(func(): game_finished.emit(won))
