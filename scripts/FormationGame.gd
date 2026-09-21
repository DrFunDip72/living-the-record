extends Node2D

signal game_finished(won: bool, score: int)

const MAX_HP := 5
const ATTACK_COOLDOWN := 0.35
const ATTACK_RANGE := 50.0
const FORMATION_RADIUS := 150.0
const COMMANDER_SPEED := 42.0
const RALLY := [Vector2(250, 270), Vector2(520, 270)]
const SLOTS := [Vector2(34, -80), Vector2(34, 80), Vector2(78, -38), Vector2(78, 38)]
const VOLLEY_EVERY := 1.3
const ARROW_SPEED := 500.0

var hp: int = MAX_HP
var attack_cooldown_timer: float = 0.0
var finished: bool = false
var _mouse_was_pressed: bool = false
var rally_idx: int = 0
var out_time: float = 0.0
var volley_t: float = 0.0
var arrows: Array = []   # {p, v}
var arrow_layer: Node2D
var hurt_cd: float = 0.0

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
	Touch.configure({"joystick": true, "aim": true})
	if Touch.active:
		hint_label.text = "Left thumb: move.  Right thumb: tap or hold where you want to strike."
	hp_bar.max_value = MAX_HP
	_update_hp_display()

	var i := 0
	for ally in allies_container.get_children():
		ally.commander = commander
		ally.slot_offset = SLOTS[i % SLOTS.size()]
		i += 1
	arrow_layer = Node2D.new()
	arrow_layer.z_index = 20
	arrow_layer.draw.connect(_draw_arrows)
	add_child(arrow_layer)

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
		rally_idx = mini(rally_idx + 1, RALLY.size() - 1)


func _physics_process(delta: float) -> void:
	if finished:
		return

	attack_cooldown_timer = max(0.0, attack_cooldown_timer - delta)
	hurt_cd = maxf(0.0, hurt_cd - delta)
	if Touch.active:
		if Touch.aim_held:
			_try_attack()
	else:
		var mouse_pressed := Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
		var mouse_just_pressed := mouse_pressed and not _mouse_was_pressed
		_mouse_was_pressed = mouse_pressed
		if Input.is_action_just_pressed("ui_accept") or Input.is_key_pressed(KEY_SPACE) or mouse_just_pressed:
			_try_attack()

	weapon.set_aim(player.last_direction.angle())

	# the captain marches the line forward; the formation moves with him
	var rally: Vector2 = RALLY[rally_idx]
	commander.position = commander.position.move_toward(rally, COMMANDER_SPEED * delta)

	var in_formation: bool = player.global_position.distance_to(commander.global_position) <= FORMATION_RADIUS
	for ally in allies_container.get_children():
		if ally.has_method("set_buffed"):
			ally.set_buffed(in_formation)

	# penalty: step out of the line and the enemy archers have a clear shot
	if in_formation:
		out_time = 0.0
		formation_label.text = "In formation -- shields cover you, your line fights harder"
		formation_label.add_theme_color_override("font_color", Color(0.55, 1.0, 0.55, 1))
	else:
		out_time += delta
		formation_label.text = "OUT OF FORMATION -- archers have a clear shot at you!"
		formation_label.add_theme_color_override("font_color", Color(1.0, 0.45, 0.3, 1))
		if out_time > 0.7:
			volley_t -= delta
			if volley_t <= 0.0:
				volley_t = VOLLEY_EVERY
				_fire_volley()
	_update_arrows(delta, in_formation)


func _try_attack() -> void:
	if attack_cooldown_timer > 0.0:
		return
	attack_cooldown_timer = ATTACK_COOLDOWN
	var facing: Vector2 = player.last_direction
	var hit_any := false
	for e in enemies_container.get_children():
		if not is_instance_valid(e) or not e.is_in_group("enemy"):
			continue
		var to_e: Vector2 = e.global_position - player.global_position
		if to_e.length() <= ATTACK_RANGE and facing.dot(to_e.normalized()) > 0.3:
			e.take_damage(1, player.global_position)
			hit_any = true
	weapon.swing()
	if hit_any:
		camera.shake(0.3)
		Fx.hit_stop(0.04)


func _fire_volley() -> void:
	for k in range(2):
		var src := Vector2(1000.0, player.global_position.y + randf_range(-160, 160))
		var aim: Vector2 = player.global_position + player.velocity * 0.35 + Vector2(randf_range(-40, 40), randf_range(-40, 40))
		arrows.append({"p": src, "v": (aim - src).normalized() * ARROW_SPEED})


func _update_arrows(delta: float, in_formation: bool) -> void:
	var keep: Array = []
	for a in arrows:
		a["p"] += a["v"] * delta
		if a["p"].distance_to(player.global_position) < 16.0:
			if in_formation:
				Fx.spawn_hit_burst(self, a["p"], Color(0.8, 0.8, 0.85, 1), 6)  # caught on a shield
			else:
				_on_player_hit(1, a["p"])
			continue
		if a["p"].x < -40.0 or a["p"].y < -40.0 or a["p"].y > 580.0:
			continue
		keep.append(a)
	arrows = keep
	arrow_layer.queue_redraw()


func _draw_arrows() -> void:
	for a in arrows:
		var d: Vector2 = (a["v"] as Vector2).normalized()
		var tip: Vector2 = a["p"]
		arrow_layer.draw_line(tip - d * 22.0, tip, Color(0.45, 0.3, 0.15, 1), 2.5)
		arrow_layer.draw_colored_polygon(PackedVector2Array([tip + d * 6.0, tip - d * 2.0 + Vector2(-d.y, d.x) * 4.0, tip - d * 2.0 - Vector2(-d.y, d.x) * 4.0]), Color(0.9, 0.9, 0.95, 1))


func _on_player_hit(amount: int, from_pos: Vector2) -> void:
	if finished or hurt_cd > 0.0:
		return
	hurt_cd = 0.5
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


func _exit_tree() -> void:
	Touch.clear()
