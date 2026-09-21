extends Node2D

signal game_finished(won: bool, score: int)

const ARROW_SCENE := preload("res://scenes/HuntArrow.tscn")
const ANIMAL_SCENE := preload("res://scenes/HuntAnimal.tscn")

const MAX_HUNGER := 100.0
const HUNGER_DRAIN := 3.4
const HUNGER_PER_KILL := 32.0
const DRAW_TIME := 0.85
const MIN_POWER := 0.3
const BOW_ANCHOR := Vector2(150, 470)

var hunger: float = MAX_HUNGER
var score: int = 0
var taken: int = 0
var missed: int = 0
var drawing: bool = false
var draw_power: float = 0.0
var hold_time: float = 0.0
var aim_pos: Vector2 = Vector2(620, 330)
var finished: bool = false
var spawn_delay: float = 0.8
var animal: Node2D = null
var msg_timer: float = 0.0
var _mouse_was_pressed: bool = false
var _t: float = 0.0

@onready var bow: Node2D = $BowView
@onready var reticle: Node2D = $Reticle
@onready var hunger_bar: ProgressBar = $UI/HungerBar
@onready var hunger_label: Label = $UI/HungerBar/HungerLabel
@onready var score_label: Label = $UI/ScoreLabel
@onready var msg_label: Label = $UI/MessageLabel
@onready var power_bar: ProgressBar = $UI/PowerBar
@onready var arrows_root: Node2D = $Arrows
@onready var animals_root: Node2D = $Animals


func _ready() -> void:
	randomize()
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	bow.position = BOW_ANCHOR
	hunger_bar.max_value = MAX_HUNGER
	msg_label.text = ""
	_update_hud()


func _exit_tree() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _process(delta: float) -> void:
	if finished:
		return
	_t += delta

	# --- hunger pressure ---
	hunger -= HUNGER_DRAIN * delta
	if hunger <= 0.0:
		hunger = 0.0
		_finish()
		return

	# --- imperfect aim: lag toward mouse + sway that grows as you hold ---
	var mouse: Vector2 = get_viewport().get_mouse_position()
	aim_pos = aim_pos.lerp(mouse, 1.0 - exp(-7.0 * delta))
	var sway_amp: float = 2.0 + hold_time * 9.0
	var sway := Vector2(sin(_t * 1.9) * sway_amp, cos(_t * 2.7) * sway_amp * 0.7)
	var final_aim: Vector2 = aim_pos + sway
	reticle.position = final_aim

	# --- draw / release ---
	var pressed := Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	if pressed and not _mouse_was_pressed:
		drawing = true
		hold_time = 0.0
		draw_power = 0.0
	elif pressed and drawing:
		hold_time += delta
		draw_power = minf(hold_time / DRAW_TIME, 1.0)
	elif not pressed and _mouse_was_pressed and drawing:
		_release(final_aim)
	_mouse_was_pressed = pressed

	var aim_dir: Vector2 = (final_aim - BOW_ANCHOR).normalized()
	bow.rotation = aim_dir.angle()
	bow.set_state(draw_power, true)
	power_bar.value = draw_power * 100.0
	power_bar.visible = drawing

	# --- animal lifecycle ---
	if animal == null or not is_instance_valid(animal):
		spawn_delay -= delta
		if spawn_delay <= 0.0:
			_spawn_animal()

	if msg_timer > 0.0:
		msg_timer -= delta
		if msg_timer <= 0.0:
			msg_label.text = ""

	_update_hud()


func _release(target: Vector2) -> void:
	drawing = false
	var power: float = maxf(draw_power, MIN_POWER)
	draw_power = 0.0
	hold_time = 0.0
	var dir: Vector2 = (target - BOW_ANCHOR).normalized()
	var arrow := ARROW_SCENE.instantiate()
	arrow.position = BOW_ANCHOR + dir * 46.0
	arrow.velocity = dir * (300.0 + power * 620.0)
	arrow.resolved.connect(_on_arrow_resolved)
	arrows_root.add_child(arrow)


func _on_arrow_resolved(kind: String, pos: Vector2, points: int) -> void:
	if finished:
		return
	match kind:
		"vital":
			taken += 1
			score += points
			hunger = minf(hunger + HUNGER_PER_KILL, MAX_HUNGER)
			Fx.spawn_hit_burst(self, pos, Color(0.9, 0.3, 0.25, 1), 16)
			_say("Clean shot! The camp eats tonight.  +%d" % points)
			spawn_delay = 1.2
		"body":
			missed += 1
			Fx.spawn_hit_burst(self, pos, Color(0.8, 0.5, 0.3, 1), 10)
			_say("Only a graze -- it bolted.")
			spawn_delay = 1.4
		_:
			missed += 1
			Fx.spawn_hit_burst(self, pos, Color(0.6, 0.55, 0.45, 0.8), 8)
			if animal != null and is_instance_valid(animal):
				if absf(animal.global_position.x - pos.x) < 150.0:
					animal.spook(pos.x)
					_say("Missed -- the noise spooked it.")
				else:
					_say("Missed.")


func _spawn_animal() -> void:
	var a := ANIMAL_SCENE.instantiate()
	animals_root.add_child(a)
	a.setup(randf())
	a.killed.connect(func(_p): spawn_delay = 1.2)
	a.escaped.connect(func():
		spawn_delay = 1.0
		_say("It got away.")
	)
	animal = a


func _say(text: String) -> void:
	msg_label.text = text
	msg_timer = 1.9


func _update_hud() -> void:
	hunger_bar.value = hunger
	hunger_label.text = "Camp Provisions: %d%%" % int(round(hunger))
	score_label.text = "Taken: %d    Score: %d" % [taken, score]


func _finish() -> void:
	finished = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var flash := ColorRect.new()
	flash.color = Color(0.4, 0.1, 0.1, 0.45)
	flash.anchor_right = 1.0
	flash.anchor_bottom = 1.0
	add_child(flash)
	get_tree().create_timer(0.45).timeout.connect(func(): game_finished.emit(false, score))
