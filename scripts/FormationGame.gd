extends Node2D

signal game_finished(won: bool)

const DIRECTIONS := ["up", "down", "left", "right"]
const ARROWS := {"up": "^", "down": "v", "left": "<", "right": ">"}
const ACTIONS := {"up": "ui_up", "down": "ui_down", "left": "ui_left", "right": "ui_right"}

const TOTAL_COMMANDS := 8
const MAX_MISTAKES := 2
const TIME_WINDOW := 1.3

var sequence: Array = []
var current_step: int = 0
var mistakes: int = 0
var time_left: float = 0.0
var awaiting_input: bool = false
var finished: bool = false

@onready var command_label: Label = $CommandLabel
@onready var status_label: Label = $StatusLabel
@onready var timer_bar: ProgressBar = $TimerBar


func _ready() -> void:
	randomize()
	for i in range(TOTAL_COMMANDS):
		sequence.append(DIRECTIONS[randi() % DIRECTIONS.size()])
	status_label.text = "Mistakes: 0 / %d allowed" % MAX_MISTAKES
	_next_command()


func _next_command() -> void:
	if current_step >= sequence.size():
		_finish(true)
		return
	var dir: String = sequence[current_step]
	command_label.text = ARROWS[dir]
	time_left = TIME_WINDOW
	timer_bar.max_value = TIME_WINDOW
	timer_bar.value = TIME_WINDOW
	awaiting_input = true


func _physics_process(delta: float) -> void:
	if finished or not awaiting_input:
		return
	time_left -= delta
	timer_bar.value = max(time_left, 0.0)

	var dir: String = sequence[current_step]
	var pressed_correct := Input.is_action_just_pressed(ACTIONS[dir])
	var pressed_wrong := false
	for key in ACTIONS.keys():
		if key != dir and Input.is_action_just_pressed(ACTIONS[key]):
			pressed_wrong = true

	if pressed_correct:
		awaiting_input = false
		current_step += 1
		_next_command()
	elif pressed_wrong or time_left <= 0.0:
		awaiting_input = false
		mistakes += 1
		status_label.text = "Mistakes: %d / %d allowed" % [mistakes, MAX_MISTAKES]
		if mistakes > MAX_MISTAKES:
			_finish(false)
		else:
			current_step += 1
			_next_command()


func _finish(won: bool) -> void:
	finished = true
	game_finished.emit(won)
