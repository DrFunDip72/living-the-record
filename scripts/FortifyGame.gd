extends Node2D

signal game_finished(won: bool, score: int)

const MAX_CITY_HP := 10
const TOWER_COST := 15
const MELEE_RANGE := 50.0
const MELEE_COOLDOWN := 0.4

var city_hp: int = MAX_CITY_HP
var currency: int = 20
var wave_index: int = 0
var finished: bool = false
var melee_timer: float = 0.0

@onready var player: CharacterBody2D = $Player
@onready var camera: Camera2D = $Player/Camera2D
@onready var city_center: Node2D = $CityCenter
@onready var enemies_container: Node2D = $EnemiesContainer
@onready var wave_spawner: Node = $WaveSpawner
@onready var build_spots: Node2D = $BuildSpots
@onready var city_hp_bar: ProgressBar = $UI/CityHPBar
@onready var city_hp_number: Label = $UI/CityHPBar/CityHPNumber
@onready var currency_label: Label = $UI/CurrencyLabel
@onready var wave_label: Label = $UI/WaveLabel
@onready var hint_label: Label = $UI/HintLabel


func _ready() -> void:
	hint_label.text = "WASD to move, SPACE to swing your sword. Click a gold post to build a tower."
	city_hp_bar.max_value = MAX_CITY_HP
	_update_labels()

	for spot in build_spots.get_children():
		spot.projectiles_container = self
		spot.pressed_spot.connect(_on_spot_pressed.bind(spot))

	wave_spawner.enemy_scene = preload("res://scenes/Enemy.tscn")
	wave_spawner.mode = "endless"
	wave_spawner.base_count = 2
	wave_spawner.count_growth = 1.18
	wave_spawner.wave_pause = 3.0
	wave_spawner.wave_cleared.connect(_on_wave_cleared)
	wave_spawner.enemy_spawned.connect(_on_enemy_spawned)
	wave_spawner.start(enemies_container, city_center)


func _on_enemy_spawned(enemy: Node) -> void:
	enemy.hit_target.connect(_on_city_hit)
	enemy.defeated.connect(func():
		if not finished:
			currency += 4
			_update_labels()
	)


func _on_wave_cleared(index: int) -> void:
	if finished:
		return
	wave_index = index + 1
	currency += 10
	_update_labels()


func _on_spot_pressed(spot: Node) -> void:
	if finished or spot.occupied:
		return
	if currency >= TOWER_COST:
		currency -= TOWER_COST
		spot.build_tower()
		_update_labels()


func _physics_process(delta: float) -> void:
	if finished:
		return
	melee_timer = max(0.0, melee_timer - delta)
	if (Input.is_action_just_pressed("ui_accept") or Input.is_key_pressed(KEY_SPACE)) and melee_timer <= 0.0:
		_melee_attack()


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


func _on_city_hit(amount: int, _from_pos: Vector2) -> void:
	if finished:
		return
	city_hp -= amount
	camera.shake(0.6)
	_update_labels()
	if city_hp <= 0:
		_finish()


func _update_labels() -> void:
	city_hp_bar.value = max(city_hp, 0)
	city_hp_number.text = "%d / %d" % [max(city_hp, 0), MAX_CITY_HP]
	currency_label.text = "Gold: %d" % currency
	wave_label.text = "Wave %d" % (wave_index + 1)


func _finish() -> void:
	finished = true
	var flash := ColorRect.new()
	flash.color = Color(1, 0.2, 0.2, 0.4)
	flash.anchor_right = 1.0
	flash.anchor_bottom = 1.0
	add_child(flash)
	get_tree().create_timer(0.35).timeout.connect(func(): game_finished.emit(false, wave_index))
