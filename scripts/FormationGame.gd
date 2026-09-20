extends Node2D

signal game_finished(won: bool, score: int)

const MAX_HP := 5
const ATTACK_COOLDOWN := 0.35
const ATTACK_RANGE := 50.0

var hp: int = MAX_HP
var attack_cooldown_timer: float = 0.0
var finished: bool = false

@onready var player: CharacterBody2D = $Player
@onready var camera: Camera2D = $Player/Camera2D
@onready var order_label: Label = $UI/OrderBubble
@onready var hp_label: Label = $UI/HPLabel
@onready var hint_label: Label = $UI/HintLabel
@onready var enemies_container: Node2D = $EnemiesContainer
@onready var wave_spawner: Node = $WaveSpawner


func _ready() -> void:
	hint_label.text = "WASD / Arrows to move. SPACE to swing your sword."
	_update_hp_label()

	wave_spawner.enemy_scene = preload("res://scenes/Enemy.tscn")
	wave_spawner.mode = "fixed"
	wave_spawner.phases = [
		{"name": "HOLD THE LINE!", "count": 3, "spawn_rect": Rect2(680, 120, 220, 320)},
		{"name": "ADVANCE!", "count": 4, "spawn_rect": Rect2(760, 90, 220, 380)},
	]
	wave_spawner.wave_cleared.connect(_on_wave_cleared)
	wave_spawner.all_waves_cleared.connect(func(): _finish(true))
	wave_spawner.enemy_spawned.connect(_on_enemy_spawned)
	wave_spawner.start(enemies_container, player)
	order_label.text = wave_spawner.current_wave_name()


func _on_enemy_spawned(enemy: Node) -> void:
	enemy.hit_target.connect(_on_player_hit)


func _on_wave_cleared(_wave_index: int) -> void:
	if not finished:
		order_label.text = wave_spawner.current_wave_name()


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
	var hit_any := false
	for e in enemies_container.get_children():
		if not is_instance_valid(e):
			continue
		var to_e: Vector2 = e.global_position - player.global_position
		if to_e.length() <= ATTACK_RANGE and facing.dot(to_e.normalized()) > 0.3:
			e.take_damage(1, player.global_position)
			hit_any = true
	if hit_any:
		camera.shake(0.3)
		Fx.hit_stop(0.04)
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
	camera.shake(0.6)
	if hp <= 0:
		_finish(false)


func _update_hp_label() -> void:
	hp_label.text = "HP: " + "#".repeat(max(hp, 0)) + "-".repeat(max(MAX_HP - hp, 0))


func _finish(won: bool) -> void:
	finished = true
	var flash := ColorRect.new()
	flash.color = Color(0.3, 1, 0.3, 0.4) if won else Color(1, 0.2, 0.2, 0.4)
	flash.anchor_right = 1.0
	flash.anchor_bottom = 1.0
	add_child(flash)
	get_tree().create_timer(0.35).timeout.connect(func(): game_finished.emit(won, -1))
