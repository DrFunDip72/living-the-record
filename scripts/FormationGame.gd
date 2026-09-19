extends Node2D

signal game_finished(won: bool)

const COMMANDS := [
	{"name": "HOLD THE LINE!", "pos": Vector2(520, 270), "size": Vector2(90, 90)},
	{"name": "ADVANCE!", "pos": Vector2(650, 270), "size": Vector2(90, 90)},
	{"name": "FALL BACK!", "pos": Vector2(190, 270), "size": Vector2(100, 100)},
	{"name": "FLANK LEFT!", "pos": Vector2(460, 110), "size": Vector2(100, 100)},
	{"name": "FLANK RIGHT!", "pos": Vector2(460, 440), "size": Vector2(100, 100)},
]

const TOTAL_COMMANDS := 7
const MAX_MISTAKES := 2
const TIME_WINDOW := 2.2

var sequence: Array = []
var current_step: int = 0
var mistakes: int = 0
var time_left: float = 0.0
var awaiting: bool = false
var finished: bool = false

@onready var player: CharacterBody2D = $Player
@onready var order_label: Label = $Commander/OrderBubble
@onready var status_label: Label = $StatusLabel
@onready var timer_bar: ProgressBar = $TimerBar
@onready var zone: ColorRect = $Zone
@onready var spark_timer: Timer = $SparkTimer


func _ready() -> void:
	randomize()
	for i in range(TOTAL_COMMANDS):
		sequence.append(COMMANDS[randi() % COMMANDS.size()])
	status_label.text = "Mistakes: 0 / %d allowed" % MAX_MISTAKES
	spark_timer.timeout.connect(_spawn_spark)
	_next_command()


func _next_command() -> void:
	if current_step >= sequence.size():
		_finish(true)
		return
	var cmd: Dictionary = sequence[current_step]
	order_label.text = cmd["name"]
	zone.position = cmd["pos"] - cmd["size"] / 2.0
	zone.size = cmd["size"]
	zone.color = Color(1, 1, 1, 0.28)
	time_left = TIME_WINDOW
	timer_bar.max_value = TIME_WINDOW
	timer_bar.value = TIME_WINDOW
	awaiting = true


func _physics_process(delta: float) -> void:
	if finished or not awaiting:
		return
	time_left -= delta
	timer_bar.value = max(time_left, 0.0)

	var cmd: Dictionary = sequence[current_step]
	var rect := Rect2(cmd["pos"] - cmd["size"] / 2.0, cmd["size"])
	var in_zone := rect.has_point(player.position)

	if in_zone:
		zone.color = Color(0.3, 1.0, 0.3, 0.5)
		awaiting = false
		current_step += 1
		get_tree().create_timer(0.2).timeout.connect(_next_command)
	elif time_left <= 0.0:
		zone.color = Color(1.0, 0.3, 0.3, 0.5)
		awaiting = false
		mistakes += 1
		status_label.text = "Mistakes: %d / %d allowed" % [mistakes, MAX_MISTAKES]
		if mistakes > MAX_MISTAKES:
			get_tree().create_timer(0.35).timeout.connect(func(): _finish(false))
		else:
			current_step += 1
			get_tree().create_timer(0.35).timeout.connect(_next_command)


func _spawn_spark() -> void:
	if finished:
		return
	var spark := ColorRect.new()
	spark.size = Vector2(10, 10)
	spark.color = Color(1, 1, 0.6, 0.9)
	spark.position = Vector2(randf_range(500, 620), randf_range(120, 420))
	add_child(spark)
	get_tree().create_timer(0.15).timeout.connect(spark.queue_free)


func _finish(won: bool) -> void:
	finished = true
	var flash := ColorRect.new()
	flash.color = Color(0.3, 1, 0.3, 0.4) if won else Color(1, 0.2, 0.2, 0.4)
	flash.anchor_right = 1.0
	flash.anchor_bottom = 1.0
	add_child(flash)
	get_tree().create_timer(0.35).timeout.connect(func(): game_finished.emit(won))
