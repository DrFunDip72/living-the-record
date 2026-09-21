extends Node2D

signal game_finished(won: bool, score: int)

const MAX_HP := 5
const ATTACK_COOLDOWN := 0.35
const ATTACK_RANGE := 50.0
const FORMATION_RADIUS := 170.0

var hp: int = MAX_HP
var attack_cooldown_timer: float = 0.0
var finished: bool = false
var _mouse_was_pressed: bool = false

@onready var player: CharacterBody2D = $Player
@onready var camera: Camera2D = $Player/Camera2D
@onready var weapon: Node2D = $Player/Weapon
@onready var commander: Node2D = $Commander
@onready var allies_container: Node2D = $AlliesContainer
@onready var order_label: Label = $UI/OrderBubble
@onready var hp_bar: ProgressBar = $UI/HPBar
@onready var hp_number: Label = $UI/HPBar/HPNumber
@onready var formation_label: Label = $UI/FormationLabel
@onready var hint_label: Label = $UI/HintLabel
@onready var enemies_container: Node2D = $EnemiesContainer
@onready var wave_spawner: Node = $WaveSpawner


func _ready() -> void:
	hint_label.text = "WASD to move. The mouse aims your sword. Click to swing."
	hp_bar.max_value = MAX_HP
	_update_hp_display()

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
	var mouse_pressed := Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	var mouse_just_pressed := mouse_pressed and not _mouse_was_pressed
	_mouse_was_pressed = mouse_pressed
	if Input.is_action_just_pressed("ui_accept") or Input.is_key_pressed(KEY_SPACE) or mouse_just_pressed:
		_try_attack()

	weapon.set_aim(player.last_direction.angle())

	var in_formation: bool = player.global_position.distance_to(commander.global_position) <= FORMATION_RADIUS
	for ally in allies_container.get_children():
		if ally.has_method("set_buffed"):
			ally.set_buffed(in_formation)
	if in_formation:
		formation_label.text = "Holding Formation -- your line fights harder"
		formation_label.add_theme_color_override("font_color", Color(0.55, 1.0, 0.55, 1))
	else:
		formation_label.text = "Out of Formation -- your line is weaker without you"
		formation_label.add_theme_color_override("font_color", Color(1.0, 0.7, 0.3, 1))


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
	weapon.swing()
	if hit_any:
		camera.shake(0.3)
		Fx.hit_stop(0.04)


func _on_player_hit(amount: int, from_pos: Vector2) -> void:
	if finished:
		return
	hp -= amount
	_update_hp_display()
	camera.shake(0.8)
	Fx.hit_stop(0.05)
	player.apply_knockback((player.global_position - from_pos).normalized(), 200.0)
	_flash_damage()
	if hp <= 0:
		_finish(false)


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


func _update_hp_display() -> void:
	hp_bar.value = max(hp, 0)
	hp_number.text = "%d / %d" % [max(hp, 0), MAX_HP]


func _finish(won: bool) -> void:
	finished = true
	var flash := ColorRect.new()
	flash.color = Color(0.3, 1, 0.3, 0.4) if won else Color(1, 0.2, 0.2, 0.4)
	flash.anchor_right = 1.0
	flash.anchor_bottom = 1.0
	add_child(flash)
	get_tree().create_timer(0.35).timeout.connect(func(): game_finished.emit(won, -1))
