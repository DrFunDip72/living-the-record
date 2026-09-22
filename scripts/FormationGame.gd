extends Node2D

signal game_finished(won: bool, score: int)

const MAX_HP := 5
const ATTACK_COOLDOWN := 0.35
const ATTACK_RANGE := 50.0
const FORMATION_RADIUS := 150.0
const COMMANDER_SPEED := 60.0
const SLOTS := [Vector2(34, -80), Vector2(34, 80), Vector2(78, -38), Vector2(78, 38)]
const VOLLEY_EVERY := 1.3
const ARROW_SPEED := 500.0
const WORLD_W := 2200.0
const RALLY_START := 250.0
const RALLY_STEP := 235.0

# enemy kinds -- tuned before they enter the tree
const SWORD := {}
const RUNNER := {"speed": 108.0, "max_hp": 1, "windup_time": 0.25, "fill": Color(0.95, 0.55, 0.2, 1), "scale": Vector2(0.85, 0.85)}
const BRUTE := {"speed": 40.0, "max_hp": 4, "windup_time": 0.5, "fill": Color(0.55, 0.12, 0.12, 1), "scale": Vector2(1.35, 1.35)}
const CAPTAIN := {"speed": 48.0, "max_hp": 8, "windup_time": 0.45, "contact_damage": 2, "fill": Color(0.45, 0.1, 0.35, 1), "scale": Vector2(1.6, 1.6)}

# the march of Helaman's two thousand (Alma 56-57), one wave per rally point
const WAVES := [
	{"name": "HOLD THE LINE!", "groups": [["front", SWORD, 3]]},
	{"name": "THEY PRESS AGAIN!", "groups": [["front", SWORD, 4]]},
	{"name": "THE NORTH FLANK!", "groups": [["north", SWORD, 3], ["front", SWORD, 2]]},
	{"name": "TURN BACK -- THEY ARE ON ANTIPUS!", "groups": [["rear", SWORD, 4]]},
	{"name": "THEIR STRONGEST MEN", "groups": [["front", BRUTE, 2], ["front", SWORD, 2]]},
	{"name": "SKIRMISHERS ON BOTH SIDES!", "groups": [["north", RUNNER, 3], ["south", RUNNER, 3]]},
	{"name": "SURROUNDED -- STAND FIRM!", "groups": [["front", SWORD, 4], ["north", BRUTE, 1], ["north", SWORD, 2], ["south", SWORD, 3], ["rear", RUNNER, 3]]},
	{"name": "THE LAST CHARGE", "groups": [["front", CAPTAIN, 1], ["front", BRUTE, 3], ["front", SWORD, 4], ["north", RUNNER, 3], ["south", RUNNER, 3]]},
]

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
var kills: int = 0
var waves_cleared: int = 0

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
	hint_label.text = "WASD to move. The mouse aims your sword. Click to swing. Stay by the banner."
	Touch.configure({"joystick": true, "aim": true})
	if Touch.active:
		hint_label.text = "Left thumb: move.  Right thumb: tap or hold where you want to strike."
	hp_bar.max_value = MAX_HP
	_update_hp_display()

	# a long field: the captain marches the line east, wave by wave
	$Background.size = Vector2(WORLD_W, 540)
	camera.limit_right = int(WORLD_W)
	player.bounds = Rect2(20, 20, WORLD_W - 40, 500)

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
	wave_spawner.wave_pause = 2.5
	var phases: Array = []
	for w in range(WAVES.size()):
		var groups: Array = []
		for g in WAVES[w]["groups"]:
			groups.append({"spawn_rect": _side_rect(g[0], _rally(w).x), "type": g[1], "count": g[2]})
		phases.append({"name": WAVES[w]["name"], "groups": groups})
	wave_spawner.phases = phases
	wave_spawner.wave_cleared.connect(_on_wave_cleared)
	wave_spawner.all_waves_cleared.connect(_on_all_cleared)
	wave_spawner.enemy_spawned.connect(_on_enemy_spawned)
	wave_spawner.start(enemies_container, player)
	_show_wave_name()


func _rally(idx: int) -> Vector2:
	return Vector2(RALLY_START + idx * RALLY_STEP, 270)


func _side_rect(side: String, rx: float) -> Rect2:
	match side:
		"north":
			return Rect2(rx + 40, 16, 260, 24)
		"south":
			return Rect2(rx + 40, 500, 260, 24)
		"rear":
			return Rect2(maxf(rx - 420, 20), 130, 60, 280)
		_:
			return Rect2(minf(rx + 380, WORLD_W - 180), 110, 160, 320)


func _show_wave_name() -> void:
	var w: int = mini(waves_cleared, WAVES.size() - 1)
	order_label.text = "WAVE %d/%d -- %s" % [w + 1, WAVES.size(), WAVES[w]["name"]]


func _on_enemy_spawned(enemy: Node) -> void:
	enemy.hit_target.connect(_on_player_hit)
	enemy.defeated.connect(func(): kills += 1)


func _on_wave_cleared(_wave_index: int) -> void:
	if finished:
		return
	waves_cleared += 1
	if waves_cleared >= WAVES.size():
		return
	rally_idx = mini(rally_idx + 1, WAVES.size() - 1)
	# every other lull, your brothers bind your wounds
	if hp < MAX_HP and waves_cleared % 2 == 0:
		hp += 1
		_update_hp_display()
		formation_label.text = "Wounds bound. +1"
	_show_wave_name()


func _on_all_cleared() -> void:
	if finished:
		return
	order_label.text = "NOT ONE OF THEM FELL"
	_finish(true)


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
	commander.position = commander.position.move_toward(_rally(rally_idx), COMMANDER_SPEED * delta)

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
		var reach: float = ATTACK_RANGE + 10.0 * (e.scale.x - 1.0)
		if to_e.length() <= reach and facing.dot(to_e.normalized()) > 0.3:
			e.take_damage(1, player.global_position)
			hit_any = true
	weapon.swing()
	if hit_any:
		camera.shake(0.3)
		Fx.hit_stop(0.04)


func _fire_volley() -> void:
	for k in range(2):
		var src := Vector2(player.global_position.x + 560.0, player.global_position.y + randf_range(-160, 160))
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
		if a["p"].x < player.global_position.x - 700.0 or a["p"].y < -40.0 or a["p"].y > 580.0:
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
	var score: int = kills * 10 + waves_cleared * 25 + (maxi(hp, 0) * 20 + 200 if won else 0)
	var flash := ColorRect.new()
	flash.color = Color(0.3, 1, 0.3, 0.4) if won else Color(1, 0.2, 0.2, 0.4)
	flash.anchor_right = 1.0
	flash.anchor_bottom = 1.0
	add_child(flash)
	get_tree().create_timer(0.6).timeout.connect(func(): game_finished.emit(won, score))


func _exit_tree() -> void:
	Touch.clear()
