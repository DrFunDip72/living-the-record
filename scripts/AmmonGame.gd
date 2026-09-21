extends Node2D

signal game_finished(won: bool, score: int)

const MELEE_RANGE := 62.0
const MELEE_COOLDOWN := 0.34
const COMBO_WINDOW := 0.75
const RELOAD_TIME := 0.7
const STONES_PER_WAVE := 6

var score: int = 0
var wave: int = 0
var stones: int = STONES_PER_WAVE
var reload_timer: float = 0.0
var melee_timer: float = 0.0
var combo: int = 0
var combo_timer: float = 0.0
var finished: bool = false
var _mouse_was_pressed: bool = false

@onready var player: CharacterBody2D = $Player
@onready var camera: Camera2D = $Player/Camera2D
@onready var enemies_container: Node2D = $EnemiesContainer
@onready var wave_spawner: Node = $WaveSpawner
@onready var flock_root: Node2D = $Flock
@onready var score_label: Label = $UI/ScoreLabel
@onready var ammo_label: Label = $UI/AmmoLabel
@onready var flock_label: Label = $UI/FlockLabel
@onready var combo_label: Label = $UI/ComboLabel
@onready var hint_label: Label = $UI/HintLabel


func _ready() -> void:
	hint_label.text = "WASD to move. Left-click slings a stone. SPACE swings your sword. Stones reset each wave."
	for s in flock_root.get_children():
		s.add_to_group("sheep")

	wave_spawner.enemy_scene = preload("res://scenes/Enemy.tscn")
	wave_spawner.mode = "endless"
	wave_spawner.base_count = 2
	wave_spawner.count_growth = 1.2
	wave_spawner.wave_pause = 2.0
	wave_spawner.wave_cleared.connect(_on_wave_cleared)
	wave_spawner.enemy_spawned.connect(_on_enemy_spawned)
	wave_spawner.start(enemies_container, _nearest_sheep_or_player())
	_update_hud()


func _nearest_sheep_or_player() -> Node2D:
	var sheep := get_tree().get_nodes_in_group("sheep")
	if sheep.is_empty():
		return player
	return sheep[randi() % sheep.size()]


func _on_enemy_spawned(enemy: Node) -> void:
	# robbers go for the flock, not for you -- you have to intercept
	enemy.setup(_nearest_sheep_or_player())
	enemy.hit_target.connect(_on_sheep_reached.bind(enemy))
	enemy.defeated.connect(func():
		if not finished:
			score += 10
			_update_hud()
	)


func _on_sheep_reached(_amount: int, _from_pos: Vector2, enemy: Node) -> void:
	if finished:
		return
	var target = enemy.target if is_instance_valid(enemy) else null
	if target != null and is_instance_valid(target) and target.is_in_group("sheep"):
		Fx.spawn_hit_burst(self, target.global_position, Color(0.95, 0.9, 0.8, 1), 14)
		target.queue_free()
		camera.shake(0.6)
		if is_instance_valid(enemy):
			enemy.setup(_nearest_sheep_or_player())
		_update_hud()
		if get_tree().get_nodes_in_group("sheep").is_empty():
			_finish()
	else:
		camera.shake(0.4)


func _on_wave_cleared(index: int) -> void:
	if finished:
		return
	wave = index + 1
	score += (index + 1) * 5
	stones = STONES_PER_WAVE
	_update_hud()


func _physics_process(delta: float) -> void:
	if finished:
		return
	melee_timer = maxf(0.0, melee_timer - delta)
	reload_timer = maxf(0.0, reload_timer - delta)
	if combo_timer > 0.0:
		combo_timer -= delta
		if combo_timer <= 0.0:
			combo = 0
			_update_hud()

	var pressed := Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	if pressed and not _mouse_was_pressed:
		_try_sling()
	_mouse_was_pressed = pressed

	if (Input.is_action_just_pressed("ui_accept") or Input.is_key_pressed(KEY_SPACE)) and melee_timer <= 0.0:
		_melee_attack()

	# retarget enemies whose sheep died
	for e in enemies_container.get_children():
		if is_instance_valid(e) and (e.target == null or not is_instance_valid(e.target)):
			e.setup(_nearest_sheep_or_player())


func _try_sling() -> void:
	if reload_timer > 0.0:
		return
	if stones <= 0:
		_say_out_of_stones()
		return
	stones -= 1
	reload_timer = RELOAD_TIME
	var dir: Vector2 = player.get_aim_direction()
	var stone := preload("res://scenes/SlingStone.tscn").instantiate()
	stone.position = player.global_position + dir * 22.0
	stone.direction = dir
	add_child(stone)
	_update_hud()


func _say_out_of_stones() -> void:
	ammo_label.text = "OUT OF STONES -- use your sword!"
	ammo_label.add_theme_color_override("font_color", Color(1, 0.4, 0.3, 1))


func _melee_attack() -> void:
	melee_timer = MELEE_COOLDOWN
	combo = mini(combo + 1, 3)
	combo_timer = COMBO_WINDOW
	var facing: Vector2 = player.get_aim_direction()
	player.apply_knockback(facing, 120.0)  # slight lunge
	var dmg: int = 1 if combo < 3 else 2
	var hit_any := false
	for e in enemies_container.get_children():
		if not is_instance_valid(e):
			continue
		var to_e: Vector2 = e.global_position - player.global_position
		if to_e.length() <= MELEE_RANGE and facing.dot(to_e.normalized()) > 0.1:
			e.take_damage(dmg, player.global_position)
			hit_any = true
	_swing_fx(facing, combo)
	if hit_any:
		camera.shake(0.25 + 0.12 * combo)
		Fx.hit_stop(0.04)
	_update_hud()


func _swing_fx(facing: Vector2, level: int) -> void:
	var fx := Polygon2D.new()
	var angle: float = facing.angle()
	var spread: float = 0.2 + level * 0.06
	var pts := PackedVector2Array()
	pts.append(Vector2.ZERO)
	for a in range(-4, 5):
		var ang: float = angle + a * spread * 0.5
		pts.append(Vector2(cos(ang), sin(ang)) * MELEE_RANGE)
	fx.polygon = pts
	fx.color = Color(1, 1, 0.85, 0.45 + 0.12 * level)
	fx.position = player.position
	add_child(fx)
	get_tree().create_timer(0.12).timeout.connect(fx.queue_free)


func _update_hud() -> void:
	score_label.text = "Score: %d    Wave %d" % [score, wave + 1]
	var sheep_left := get_tree().get_nodes_in_group("sheep").size()
	flock_label.text = "Flock: %d" % sheep_left
	if stones > 0:
		ammo_label.text = "Stones: %s" % "o".repeat(stones)
		ammo_label.add_theme_color_override("font_color", Color(0.95, 0.9, 0.7, 1))
	else:
		_say_out_of_stones()
	combo_label.text = "" if combo <= 1 else "Combo x%d" % combo


func _finish() -> void:
	finished = true
	var flash := ColorRect.new()
	flash.color = Color(1, 0.2, 0.2, 0.42)
	flash.anchor_right = 1.0
	flash.anchor_bottom = 1.0
	add_child(flash)
	get_tree().create_timer(0.4).timeout.connect(func(): game_finished.emit(false, score))
