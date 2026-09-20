extends Node2D

signal game_finished(won: bool, score: int)

const STAGES := [
	{"name": "Clearing the Ground", "timber": 2, "stone": 0},
	{"name": "Laying the Foundation", "timber": 0, "stone": 2},
	{"name": "Raising the Walls", "timber": 3, "stone": 1},
	{"name": "Finishing the Temple", "timber": 1, "stone": 2},
]

var carried_timber: int = 0
var carried_stone: int = 0
var stored_timber: int = 0
var stored_stone: int = 0
var stage: int = 0
var finished: bool = false

@onready var player: CharacterBody2D = $Player
@onready var build_zone: Area2D = $BuildZone
@onready var temple_visual: Node2D = $BuildZone/TempleVisual
@onready var stage_label: Label = $UI/StageLabel
@onready var carry_label: Label = $UI/CarryLabel
@onready var need_label: Label = $UI/NeedLabel
@onready var hint_label: Label = $UI/HintLabel
@onready var nodes_container: Node2D = $ResourceNodes


func _ready() -> void:
	hint_label.text = "WASD / Arrows to move. Stand at a resource until it's gathered, then carry it to the temple site."
	for n in nodes_container.get_children():
		n.harvested.connect(_on_harvested)
	_update_labels()


func _process(_delta: float) -> void:
	if finished:
		return
	if build_zone.overlaps_body(player):
		var deposited := false
		if carried_timber > 0:
			stored_timber += carried_timber
			carried_timber = 0
			deposited = true
		if carried_stone > 0:
			stored_stone += carried_stone
			carried_stone = 0
			deposited = true
		if deposited:
			temple_visual.pop(1.2)
			_check_stage()
	_update_labels()


func _on_harvested(type: String) -> void:
	if type == "timber":
		carried_timber = min(carried_timber + 1, 5)
	else:
		carried_stone = min(carried_stone + 1, 5)


func _check_stage() -> void:
	var need: Dictionary = STAGES[stage]
	if stored_timber >= need["timber"] and stored_stone >= need["stone"]:
		stored_timber -= need["timber"]
		stored_stone -= need["stone"]
		stage += 1
		temple_visual.grow_stage(stage)
		if stage >= STAGES.size():
			_finish()


func _update_labels() -> void:
	if finished:
		return
	if stage < STAGES.size():
		var need: Dictionary = STAGES[stage]
		stage_label.text = "Stage %d/%d -- %s" % [stage + 1, STAGES.size(), need["name"]]
		need_label.text = "Needs: %d Timber, %d Stone (stored: %d / %d)" % [need["timber"], need["stone"], stored_timber, stored_stone]
	carry_label.text = "Carrying: %d Timber, %d Stone" % [carried_timber, carried_stone]


func _finish() -> void:
	finished = true
	stage_label.text = "The Temple Is Complete"
	need_label.text = ""
	var flash := ColorRect.new()
	flash.color = Color(1, 0.9, 0.5, 0.4)
	flash.anchor_right = 1.0
	flash.anchor_bottom = 1.0
	add_child(flash)
	get_tree().create_timer(0.5).timeout.connect(func(): game_finished.emit(true, -1))
