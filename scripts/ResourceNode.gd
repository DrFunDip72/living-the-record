extends Node2D

signal harvested(type: String)

@export var resource_type: String = "timber"
@export var max_amount: int = 3
@export var harvest_time: float = 1.0
@export var respawn_time: float = 8.0

var amount: int
var progress: float = 0.0
var respawn_timer: float = 0.0
var player_in_range: bool = false

@onready var area: Area2D = $Area2D
@onready var visual: Node2D = $Visual
@onready var progress_bar: ProgressBar = $ProgressBar


func _ready() -> void:
	amount = max_amount
	area.body_entered.connect(func(b): if b.is_in_group("player"): player_in_range = true)
	area.body_exited.connect(func(b): if b.is_in_group("player"): player_in_range = false)
	progress_bar.visible = false


func _process(delta: float) -> void:
	if amount <= 0:
		respawn_timer -= delta
		if respawn_timer <= 0.0:
			amount = max_amount
			visual.visible = true
		return

	if player_in_range:
		progress += delta
		progress_bar.visible = true
		progress_bar.value = (progress / harvest_time) * 100.0
		if progress >= harvest_time:
			progress = 0.0
			amount -= 1
			harvested.emit(resource_type)
			visual.pop(1.25)
			if amount <= 0:
				visual.visible = false
				progress_bar.visible = false
				respawn_timer = respawn_time
	else:
		progress = 0.0
		progress_bar.visible = false
