extends Node2D

@export var jitter_amount: float = 4.0
@export var jitter_speed: float = 3.0

var base_position: Vector2
var time_offset: float


func _ready() -> void:
	base_position = position
	time_offset = randf() * TAU


func _process(_delta: float) -> void:
	var t := Time.get_ticks_msec() / 1000.0 * jitter_speed + time_offset
	position = base_position + Vector2(sin(t) * jitter_amount, cos(t * 1.3) * jitter_amount)
