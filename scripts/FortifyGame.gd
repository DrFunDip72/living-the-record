extends Node2D

signal game_finished(won: bool, score: int)

const UNIT_SCENE := preload("res://scenes/LaneUnit.tscn")
const GROUND_Y := 430.0

const UNIT_TYPES := {
	"sword":   {"name": "Swordman", "cost": 25,  "hp": 44.0, "dmg": 7.0,  "range": 36.0,  "atk": 0.8, "spd": 54.0},
	"spear":   {"name": "Spearman", "cost": 40,  "hp": 36.0, "dmg": 10.0, "range": 68.0,  "atk": 1.0, "spd": 46.0},
	"shield":  {"name": "Shieldman","cost": 55,  "hp": 110.0,"dmg": 4.0,  "range": 32.0,  "atk": 1.1, "spd": 34.0},
	"archer":  {"name": "Archer",   "cost": 60,  "hp": 26.0, "dmg": 7.0,  "range": 210.0, "atk": 1.3, "spd": 44.0, "ranged": true},
	"captain": {"name": "Captain",  "cost": 120, "hp": 96.0, "dmg": 13.0, "range": 44.0,  "atk": 0.9, "spd": 48.0},
}

const UNIT_ORDER := ["sword", "spear", "shield", "archer", "captain"]

var gold: float = 70.0
var income: float = 7.0
var income_level: int = 1
var armor_level: int = 1
var kills: int = 0
var finished: bool = false
var enemy_timer: float = 3.0
var elapsed: float = 0.0

@onready var units_root: Node2D = $Units
@onready var arrows_root: Node2D = $Arrows
@onready var player_fort: Node2D = $PlayerFort
@onready var enemy_fort: Node2D = $EnemyFort
@onready var gold_label: Label = $UI/TopBar/GoldLabel
@onready var stat_label: Label = $UI/TopBar/StatLabel
@onready var player_hp_bar: ProgressBar = $UI/PlayerHP
@onready var enemy_hp_bar: ProgressBar = $UI/EnemyHP
@onready var unit_bar: HBoxContainer = $UI/UnitBar
@onready var upgrade_bar: HBoxContainer = $UI/UpgradeBar

var unit_buttons: Dictionary = {}
var upgrade_buttons: Dictionary = {}


func _ready() -> void:
	randomize()
	player_fort.team = 0
	player_fort.arrows_root = arrows_root
	player_fort.destroyed.connect(_on_fort_destroyed)
	enemy_fort.team = 1
	enemy_fort.arrows_root = arrows_root
	enemy_fort.destroyed.connect(_on_fort_destroyed)
	player_hp_bar.max_value = player_fort.max_hp
	enemy_hp_bar.max_value = enemy_fort.max_hp

	for key in UNIT_ORDER:
		var info: Dictionary = UNIT_TYPES[key]
		var b := Button.new()
		b.custom_minimum_size = Vector2(132, 52)
		b.text = "%s\n%d g" % [info["name"], info["cost"]]
		b.add_theme_font_size_override("font_size", 14)
		b.pressed.connect(_on_train.bind(key))
		unit_bar.add_child(b)
		unit_buttons[key] = b

	_add_upgrade("crossbow", "Crossbow", 80)
	_add_upgrade("income", "Income", 70)
	_add_upgrade("armor", "Fort Walls", 90)
	_update_hud()


func _add_upgrade(key: String, label: String, cost: int) -> void:
	var b := Button.new()
	b.custom_minimum_size = Vector2(150, 40)
	b.add_theme_font_size_override("font_size", 13)
	b.set_meta("cost", cost)
	b.set_meta("label", label)
	b.pressed.connect(_on_upgrade.bind(key))
	upgrade_bar.add_child(b)
	upgrade_buttons[key] = b


func _upgrade_cost(key: String) -> int:
	var lvl := 1
	match key:
		"crossbow":
			lvl = player_fort.crossbow_level
		"income":
			lvl = income_level
		"armor":
			lvl = armor_level
	return int(upgrade_buttons[key].get_meta("cost")) * lvl


func _process(delta: float) -> void:
	if finished:
		return
	elapsed += delta
	gold += income * delta

	# captains buff nearby friendly units
	for u in units_root.get_children():
		if is_instance_valid(u) and u.kind == "captain":
			for other in units_root.get_children():
				if is_instance_valid(other) and other.team == u.team and absf(other.position.x - u.position.x) < 90.0:
					other.apply_buff(1.3)

	enemy_timer -= delta
	if enemy_timer <= 0.0:
		_enemy_spawn()
		enemy_timer = maxf(1.1, 3.4 - elapsed * 0.02)

	_update_hud()


func _on_train(key: String) -> void:
	if finished:
		return
	var info: Dictionary = UNIT_TYPES[key]
	if gold < float(info["cost"]):
		return
	gold -= float(info["cost"])
	_spawn_unit(0, key, player_fort.position.x + 46.0)
	_update_hud()


func _on_upgrade(key: String) -> void:
	if finished:
		return
	var cost := _upgrade_cost(key)
	if gold < float(cost):
		return
	gold -= float(cost)
	match key:
		"crossbow":
			player_fort.crossbow_level += 1
		"income":
			income_level += 1
			income += 4.0
		"armor":
			armor_level += 1
			player_fort.max_hp += 45.0
			player_fort.hp += 45.0
			player_hp_bar.max_value = player_fort.max_hp
	_update_hud()


func _enemy_spawn() -> void:
	var pool := ["sword", "sword", "spear"]
	if elapsed > 25.0:
		pool.append("archer")
		pool.append("shield")
	if elapsed > 55.0:
		pool.append("captain")
		pool.append("spear")
	var key: String = pool[randi() % pool.size()]
	_spawn_unit(1, key, enemy_fort.position.x - 46.0)


func _spawn_unit(team: int, key: String, x: float) -> void:
	var info: Dictionary = UNIT_TYPES[key]
	var u := UNIT_SCENE.instantiate()
	u.position = Vector2(x, GROUND_Y)
	units_root.add_child(u)
	u.configure(team, key, info)
	u.arrows_root = arrows_root
	u.died.connect(_on_unit_died)


func _on_unit_died(unit: Node) -> void:
	if finished:
		return
	if unit.team == 1:
		kills += 1
		gold += 9.0
	_update_hud()


func _on_fort_destroyed(team: int) -> void:
	if finished:
		return
	_finish(team == 1)


func _update_hud() -> void:
	gold_label.text = "Gold: %d" % int(gold)
	stat_label.text = "Income %d/s    Crossbow Lv%d    Walls Lv%d    Kills %d" % [
		int(income), player_fort.crossbow_level, armor_level, kills
	]
	player_hp_bar.value = player_fort.hp
	enemy_hp_bar.value = enemy_fort.hp

	for key in unit_buttons:
		var b: Button = unit_buttons[key]
		b.disabled = gold < float(UNIT_TYPES[key]["cost"])
	for key in upgrade_buttons:
		var ub: Button = upgrade_buttons[key]
		var cost := _upgrade_cost(key)
		ub.text = "%s  %d g" % [ub.get_meta("label"), cost]
		ub.disabled = gold < float(cost)


func _finish(won: bool) -> void:
	finished = true
	var score: int = kills * 10 + (500 if won else 0)
	var flash := ColorRect.new()
	flash.color = Color(0.3, 1, 0.3, 0.4) if won else Color(1, 0.2, 0.2, 0.42)
	flash.anchor_right = 1.0
	flash.anchor_bottom = 1.0
	add_child(flash)
	get_tree().create_timer(0.5).timeout.connect(func(): game_finished.emit(won, score))
