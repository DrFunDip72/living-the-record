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
		_finish(true)


func _on_spotted() -> void:
	if not finished:
		_finish(false)


func _finish(won: bool) -> void:
	finished = true
	var flash := ColorRect.new()
	flash.color = Color(0.3, 1, 0.3, 0.4) if won else Color(1, 0.2, 0.2, 0.4)
	flash.anchor_right = 1.0
	flash.anchor_bottom = 1.0
	add_child(flash)
	get_tree().create_timer(0.35).timeout.connect(func(): game_finished.emit(won))
