extends Node2D

signal game_finished(won: bool, score: int)

const MAX_HP := 5
const MELEE_RANGE := 50.0
const MELEE_COOLDOWN := 0.4
const SLING_COOLDOWN := 0.45

var hp: int = MAX_HP
var score: int = 0
var melee_timer: float = 0.0
var sling_timer: float = 0.0
var finished: bool = false
var _mouse_was_pressed: bool = false

@onready var player: CharacterBody2D = $Player
@onready var camera: Camera2D = $Player/Camera2D
@onready var enemies_container: Node2D = $EnemiesContainer
@onready var wave_spawner: Node = $WaveSpawner
@onready var hp_bar: ProgressBar = $UI/HPBar
@onready var hp_number: Label = $UI/HPBar/HPNumber
@onready var score_label: Label = $UI/ScoreLabel
@onready var hint_label: Label = $UI/HintLabel


func _ready() -> void:
	hint_label.text = "WASD to move. Left-click to sling at range. SPACE to swing your sword up close."
	hp_bar.max_value = MAX_HP
	_update_hp()
	_update_score()

	wave_spawner.enemy_scene = preload("res://scenes/Enemy.tscn")
	wave_spawner.mode = "endless"
	wave_spawner.base_count = 2
	wave_spawner.count_growth = 1.2
	wave_spawner.wave_pause = 1.6
	wave_spawner.wave_cleared.connect(_on_wave_cleared)
	wave_spawner.enemy_spawned.connect(_on_enemy_spawned)
	wave_spawner.start(enemies_container, player)


func _on_enemy_spawned(enemy: Node) -> void:
	enemy.hit_target.connect(_on_player_hit)
	enemy.defeated.connect(func():
		if not finished:
			score += 10
			_update_score()
	)


func _on_wave_cleared(wave_index: int) -> void:
	if finished:
		return
	score += (wave_index + 1) * 5
	_update_score()


func _physics_process(delta: float) -> void:
	if finished:
		return
	melee_timer = max(0.0, melee_timer - delta)
	sling_timer = max(0.0, sling_timer - delta)

	var mouse_pressed := Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	if mouse_pressed and not _mouse_was_pressed and sling_timer <= 0.0:
		_throw_sling()
	_mouse_was_pressed = mouse_pressed

	if (Input.is_action_just_pressed("ui_accept") or Input.is_key_pressed(KEY_SPACE)) and melee_timer <= 0.0:
		_melee_attack()


func _throw_sling() -> void:
	sling_timer = SLING_COOLDOWN
	var dir: Vector2 = player.get_aim_direction()
	var stone := preload("res://scenes/SlingStone.tscn").instantiate()
	stone.position = player.global_position + dir * 20.0
	stone.direction = dir
	add_child(stone)


func _melee_attack() -> void:
	melee_timer = MELEE_COOLDOWN
	var facing: Vector2 = player.last_direction
	var hit_any := false
	for e in enemies_container.get_children():
		if not is_instance_valid(e):
			continue
		var to_e: Vector2 = e.global_position - player.global_position
		if to_e.length() <= MELEE_RANGE and facing.dot(to_e.normalized()) > 0.3:
			e.take_damage(1, player.global_position)
			hit_any = true
	if hit_any:
		camera.shake(0.3)


func _on_player_hit(amount: int, from_pos: Vector2) -> void:
	if finished:
		return
	hp -= amount
	_update_hp()
	camera.shake(0.8)
	Fx.hit_stop(0.05)
	player.apply_knockback((player.global_position - from_pos).normalized(), 200.0)
	_flash_damage()
	if hp <= 0:
		_finish()


func _flash_damage() -> void:
	var flash := ColorRect.new()
	flash.color = Color(1.0, 0.15, 0.1, 0.55)
	flash.anchor_right = 1.0
	flash.anchor_bottom = 1.0
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$UI.add_child(flash)
	var tw := create_tween()
	tw.tween_property(flash, "modulate:a", 0.0, 0.25)
	tw.tween_callback(flash.queue_free)


func _update_hp() -> void:
	hp_bar.value = max(hp, 0)
	hp_number.text = "%d / %d" % [max(hp, 0), MAX_HP]


func _update_score() -> void:
	score_label.text = "Score: %d" % score


func _finish() -> void:
	finished = true
	var flash := ColorRect.new()
	flash.color = Color(1, 0.2, 0.2, 0.4)
	flash.anchor_right = 1.0
	flash.anchor_bottom = 1.0
	add_child(flash)
	get_tree().create_timer(0.35).timeout.connect(func(): game_finished.emit(false, score))
