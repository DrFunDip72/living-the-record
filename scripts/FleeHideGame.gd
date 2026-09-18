extends Node2D

signal game_finished(won: bool)

var finished: bool = false

@onready var safe_zone: Area2D = $SafeZone
@onready var guards: Node2D = $Guards
@onready var status_label: Label = $StatusLabel


func _ready() -> void:
	safe_zone.body_entered.connect(_on_safe_zone_entered)
	for guard in guards.get_children():
		guard.spotted_player.connect(_on_spotted)


func _on_safe_zone_entered(body: Node) -> void:
	if not finished and body.is_in_group("player"):
		finished = true
		game_finished.emit(true)


func _on_spotted() -> void:
	if not finished:
		finished = true
		game_finished.emit(false)
