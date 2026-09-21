extends Node2D

signal game_finished(won: bool, score: int)

const MELEE_RANGE := 62.0
const MELEE_COOLDOWN := 0.34
const COMBO_WINDOW := 0.75
const RELOAD_TIME := 0.7
const STONES_PER_WAVE := 6
const MAX_HP := 6
const RETARGET_EVERY := 0.4

var score: int = 0
var wave: int = 0
var stones: int = STONES_PER_WAVE
var reload_timer: float = 0.0
var melee_timer: float = 0.0
var combo: int = 0
var combo_timer: float = 0.0
var finished: bool = false
var hp: int = MAX_HP
var retarget_timer: float = 0.0
var carriers: Dictionary = {}   # robber -> {sheep, marker}
var sheep_home: Dictionary = {}
var _mouse_was_pressed: bool = false

@onready var player: CharacterBody2D = $Player
@onready var camera: Camera2D = $Player/Camera2D
@onready var weapon: Node2D = $Player/Weapon
@onready var aim_indicator: Node2D = $Player/AimIndicator
@onready var hp_bar: ProgressBar = $UI/HPBar
@onready var hp_number: Label = $UI/HPBar/HPNumber
@onready var enemies_container: Node2D = $EnemiesContainer
@onready var wave_spawner: Node = $WaveSpawner
@onready var flock_root: Node2D = $Flock
@onready var score_label: Label = $UI/ScoreLabel
@onready var ammo_label: Label = $UI/AmmoLabel
@onready var flock_label: Label = $UI/FlockLabel
@onready var combo_label: Label = $UI/ComboLabel
@onready var hint_label: Label = $UI/HintLabel


func _ready() -> void:
	hint_label.text = "WASD to move. The arrow shows your throw. Left-click slings, SPACE swings. Stones reset each wave."
	for s in flock_root.get_children():
		s.add_to_group("sheep")
		sheep_home[s] = s.position
	hp_bar.max_value = MAX_HP
	weapon.start_spin()
	Touch.configure({"joystick": true, "aim": true, "buttons": ["Sword"]})
	if Touch.active:
		hint_label.text = "Left thumb: move.  Tap right side: sling a stone there.  SWORD button: swing."
		Touch.aim_pressed.connect(_on_touch_aim)
		Touch.button_pressed.connect(_on_touch_button)

	wave_spawner.enemy_scene = preload("res://scenes/Enemy.tscn")
	wave_spawner.mode = "endless"
	wave_spawner.base_count = 2
	wave_spawner.count_growth = 1.2
	wave_spawner.wave_pause = 2.0
	wave_spawner.wave_cleared.connect(_on_wave_cleared)
	wave_spawner.enemy_spawned.connect(_on_enemy_spawned)
	wave_spawner.start(enemies_container, _nearest_sheep_or_player())
	_update_hp()
	_update_hud()


func _nearest_sheep_or_player() -> Node2D:
	var sheep := get_tree().get_nodes_in_group("sheep")
	if sheep.is_empty():
		return player
	return sheep[randi() % sheep.size()]


func _nearest_target_for(from: Vector2) -> Node2D:
	var best: Node2D = player
	var best_d: float = from.distance_to(player.global_position)
	for s in get_tree().get_nodes_in_group("sheep"):
		if not is_instance_valid(s):
			continue
		var d: float = from.distance_to(s.global_position)
		if d < best_d:
			best_d = d
			best = s
	return best


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
	if finished or not is_instance_valid(enemy):
		return
	if carriers.has(enemy):
		# made it to the edge with a sheep -- the flock is broken
		ammo_label.text = "A SHEEP WAS CARRIED OFF!"
		_finish()
		return
	var target = enemy.target
	if target == player:
		hp -= 1
		_update_hp()
		camera.shake(0.7)
		Fx.hit_stop(0.05)
		player.apply_knockback((player.global_position - _from_pos_safe(enemy)).normalized(), 190.0)
		_flash_damage()
		if hp <= 0:
			_finish()
		return
	if target != null and is_instance_valid(target) and target.is_in_group("sheep"):
		_grab(enemy, target)


func _grab(enemy: Node, sheep: Node2D) -> void:
	sheep.remove_from_group("sheep")
	var marker := Node2D.new()
	marker.position = _escape_point(enemy.global_position)
	add_child(marker)
	carriers[enemy] = {"sheep": sheep, "marker": marker}
	enemy.setup(marker)
	enemy.speed *= 0.72
	enemy.defeated.connect(_on_carrier_defeated.bind(enemy))
	camera.shake(0.4)
	combo_label.text = "A robber grabbed a sheep -- stop him!"
	_update_hud()


func _escape_point(from: Vector2) -> Vector2:
	var opts := [Vector2(1000, from.y), Vector2(from.x, -40), Vector2(from.x, 580)]
	var best: Vector2 = opts[0]
	for o in opts:
		if from.distance_to(o) < from.distance_to(best):
			best = o
	return best


func _on_carrier_defeated(enemy: Node) -> void:
	if not carriers.has(enemy):
		return
	var c: Dictionary = carriers[enemy]
	carriers.erase(enemy)
	if is_instance_valid(c["marker"]):
		c["marker"].queue_free()
	if is_instance_valid(c["sheep"]):
		c["sheep"].add_to_group("sheep")
		Fx.spawn_hit_burst(self, c["sheep"].global_position, Color(1, 1, 0.8, 1), 12)
		combo_label.text = "Sheep rescued!"
	_update_hud()


func _from_pos_safe(enemy: Node) -> Vector2:
	return enemy.global_position if is_instance_valid(enemy) else player.global_position


func _flash_damage() -> void:
	var flash := ColorRect.new()
	flash.color = Color(1.0, 0.15, 0.1, 0.5)
	flash.anchor_right = 1.0
	flash.anchor_bottom = 1.0
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$UI.add_child(flash)
	var tw := create_tween()
	tw.tween_property(flash, "modulate:a", 0.0, 0.25)
	tw.tween_callback(flash.queue_free)


func _update_hp() -> void:
	hp_bar.value = maxi(hp, 0)
	hp_number.text = "Ammon %d / %d" % [maxi(hp, 0), MAX_HP]


func _on_wave_cleared(index: int) -> void:
	if finished:
		return
	wave = index + 1
	score += (index + 1) * 5
	stones = STONES_PER_WAVE
	weapon.kind = "sling"
	weapon.start_spin()
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

	if not Touch.active:
		var pressed := Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
		if pressed and not _mouse_was_pressed:
			_try_sling()
		_mouse_was_pressed = pressed

		if (Input.is_action_just_pressed("ui_accept") or Input.is_key_pressed(KEY_SPACE)) and melee_timer <= 0.0:
			_melee_attack()

	var aim_dir: Vector2 = player.get_aim_direction()
	weapon.set_aim(aim_dir.angle())
	aim_indicator.set_state(aim_dir.angle(), stones > 0 and reload_timer <= 0.0)

	for e in carriers.keys():
		if is_instance_valid(e) and is_instance_valid(carriers[e]["sheep"]):
			carriers[e]["sheep"].global_position = e.global_position + Vector2(0, 16)
	for sh in get_tree().get_nodes_in_group("sheep"):
		var home: Vector2 = sheep_home.get(sh, sh.position)
		sh.position = sh.position.move_toward(home, 45.0 * delta)

	retarget_timer -= delta
	if retarget_timer <= 0.0:
		retarget_timer = RETARGET_EVERY
		for e in enemies_container.get_children():
			if is_instance_valid(e) and e.is_in_group("enemy") and not carriers.has(e):
				e.setup(_nearest_target_for(e.global_position))


func _try_sling() -> void:
	if finished or reload_timer > 0.0:
		return
	if stones <= 0:
		_say_out_of_stones()
		return
	stones -= 1
	reload_timer = RELOAD_TIME
	weapon.kind = "sling"
	weapon.start_spin()
	var dir: Vector2 = player.get_aim_direction()
	var stone := preload("res://scenes/SlingStone.tscn").instantiate()
	stone.position = player.global_position + dir * 22.0
	stone.direction = dir
	add_child(stone)
	_update_hud()


func _say_out_of_stones() -> void:
	if weapon.kind != "sword":
		weapon.stop_spin()
		weapon.kind = "sword"
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
		if not is_instance_valid(e) or not e.is_in_group("enemy"):
			continue
		var to_e: Vector2 = e.global_position - player.global_position
		if to_e.length() <= MELEE_RANGE and facing.dot(to_e.normalized()) > 0.1:
			e.take_damage(dmg, player.global_position)
			hit_any = true
	weapon.stop_spin()
	weapon.kind = "sword"
	weapon.swing()
	get_tree().create_timer(0.45).timeout.connect(func():
		if is_instance_valid(weapon) and stones > 0 and melee_timer <= 0.0:
			weapon.kind = "sling"
			weapon.start_spin()
	)
	if hit_any:
		camera.shake(0.25 + 0.12 * combo)
		Fx.hit_stop(0.04)
	_update_hud()


func _update_hud() -> void:
	score_label.text = "Score: %d    Wave %d" % [score, wave + 1]
	var sheep_left := get_tree().get_nodes_in_group("sheep").size()
	flock_label.text = "Flock: %d" % sheep_left if carriers.is_empty() else "Flock: %d  (%d STOLEN!)" % [sheep_left, carriers.size()]
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


func _on_touch_aim(_p: Vector2) -> void:
	_try_sling()


func _on_touch_button(n: String) -> void:
	if n == "Sword" and melee_timer <= 0.0 and not finished:
		_melee_attack()


func _exit_tree() -> void:
	if Touch.aim_pressed.is_connected(_on_touch_aim):
		Touch.aim_pressed.disconnect(_on_touch_aim)
	if Touch.button_pressed.is_connected(_on_touch_button):
		Touch.button_pressed.disconnect(_on_touch_button)
	Touch.clear()
