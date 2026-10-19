extends Node2D

enum State { BEFORE, PLAYING, WON, LOST }

var state: State = State.BEFORE
var level: Dictionary = {}
var current_instance: Node = null

@onready var gameplay_root: Node2D = $GameplayRoot
@onready var ui: CanvasLayer = $UI
@onready var status_label: Label = $UI/StatusLabel
@onready var title_label: Label = $UI/TitleLabel
@onready var ref_label: Label = $UI/RefLabel
@onready var body_label: RichTextLabel = $UI/BodyLabel
@onready var score_label: Label = $UI/ScoreLabel
@onready var play_button: Button = $UI/PlayButton
@onready var end_buttons: HBoxContainer = $UI/EndButtons
@onready var play_again_button: Button = $UI/EndButtons/PlayAgainButton
@onready var menu_button: Button = $UI/EndButtons/MenuButton
@onready var pause_overlay: CanvasLayer = $PauseOverlay
@onready var resume_button: Button = $PauseOverlay/ResumeButton
@onready var quit_button: Button = $PauseOverlay/QuitButton
@onready var pause_button: Button = $PauseLayer/PauseButton


func _ready() -> void:
	level = Game.get_level(Game.current_level_id)
	if level.is_empty():
		Transition.goto_scene("res://scenes/LevelSelect.tscn")
		return
	play_button.pressed.connect(_on_play_pressed)
	play_again_button.pressed.connect(_on_play_pressed)
	menu_button.pressed.connect(_on_menu_pressed)
	resume_button.pressed.connect(func(): _toggle_pause(false))
	quit_button.pressed.connect(_on_menu_pressed)
	pause_button.pressed.connect(func(): _toggle_pause(true))
	pause_button.visible = false
	pause_overlay.visible = false
	pause_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	_show_before()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and state == State.PLAYING:
		_toggle_pause(not get_tree().paused)


func _toggle_pause(paused: bool) -> void:
	get_tree().paused = paused
	pause_overlay.visible = paused
	Touch.visible = Touch.active and not paused


func _show_before() -> void:
	state = State.BEFORE
	gameplay_root.visible = false
	ui.visible = true
	end_buttons.visible = false
	score_label.visible = false
	play_button.visible = true
	status_label.visible = false
	title_label.text = level["name"]
	ref_label.text = level["reference"] + "  |  " + level["tagline"]
	body_label.text = level["before"]


func _start_gameplay() -> void:
	state = State.PLAYING
	pause_button.visible = true
	ui.visible = false
	gameplay_root.visible = true
	var scene: PackedScene = load(level["scene"])
	current_instance = scene.instantiate()
	gameplay_root.add_child(current_instance)
	current_instance.game_finished.connect(_on_game_finished)


func _on_game_finished(won: bool, score: int = -1) -> void:
	_toggle_pause(false)
	pause_button.visible = false
	if current_instance:
		current_instance.queue_free()
		current_instance = null
	gameplay_root.visible = false
	ui.visible = true
	end_buttons.visible = true
	play_button.visible = false

	var score_key: String = level.get("score_key", "")
	if score >= 0 and score_key != "":
		var is_new_best: bool = HighScores.submit_score(score_key, score)
		score_label.visible = true
		score_label.text = "Score: %d    Best: %d%s" % [score, HighScores.get_best(score_key), "    NEW BEST!" if is_new_best else ""]
	else:
		score_label.visible = false

	ref_label.text = level["reference"]
	# The state goes in the eyebrow above the title so the heading stays the
	# level's own name, and win and loss differ without two layouts.
	status_label.visible = true
	title_label.text = level["name"]
	if won:
		state = State.WON
		status_label.text = "COMPLETE"
		status_label.add_theme_color_override("font_color", Color(0.72, 0.6, 0.36, 1))
		body_label.text = level["after"]
	else:
		state = State.LOST
		status_label.text = "ROUND OVER" if score_key != "" else "YOU DID NOT MAKE IT"
		status_label.add_theme_color_override("font_color", Color(0.74, 0.44, 0.38, 1))
		# every level has real loss text now, but never show an empty panel
		var lose_text: String = str(level.get("lose_text", "")).strip_edges()
		body_label.text = lose_text if lose_text != "" else level["after"]


func _on_play_pressed() -> void:
	_start_gameplay()


func _on_menu_pressed() -> void:
	get_tree().paused = false
	Touch.clear()
	Transition.goto_scene("res://scenes/LevelSelect.tscn")
