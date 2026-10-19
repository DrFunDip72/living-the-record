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
@onready var body_scroll: ScrollContainer = $UI/BodyScroll
@onready var content: VBoxContainer = $UI/BodyScroll/Content
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


# --- interstitial text ------------------------------------------------------
# The before/after copy is one string of blank-line separated paragraphs with
# scripture quoted inline. Splitting it lets the quotation and the reflection
# question be set apart instead of running together as one grey block.

func _accent() -> Color:
	return level.get("color", Color(0.82, 0.68, 0.32, 1))


func _quiet_label(text: String, font_size: int, col: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", col)
	l.add_theme_constant_override("outline_size", 0)
	l.add_theme_constant_override("shadow_offset_x", 0)
	l.add_theme_constant_override("shadow_offset_y", 0)
	l.add_theme_constant_override("line_spacing", 5)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return l


func _eyebrow(text: String, col: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 10)
	l.add_theme_color_override("font_color", col)
	l.add_theme_constant_override("outline_size", 0)
	l.add_theme_constant_override("shadow_offset_x", 0)
	l.add_theme_constant_override("shadow_offset_y", 0)
	return l


# Scripture: a gold hairline down the left, the words held off it.
func _quote_block(text: String) -> Control:
	var box := PanelContainer.new()
	var st := StyleBoxFlat.new()
	st.bg_color = Color(1, 0.93, 0.76, 0.045)
	st.border_color = _accent().lightened(0.35)
	st.border_width_left = 3
	st.content_margin_left = 18.0
	st.content_margin_right = 14.0
	st.content_margin_top = 11.0
	st.content_margin_bottom = 12.0
	st.corner_radius_top_right = 4
	st.corner_radius_bottom_right = 4
	box.add_theme_stylebox_override("panel", st)
	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 6)
	box.add_child(inner)
	inner.add_child(_eyebrow("SCRIPTURE", _accent().lightened(0.5)))
	inner.add_child(_quiet_label(text, 16, Color(0.97, 0.93, 0.83, 1)))
	return box


# The reflection question is the whole point of the after screen, so it gets
# to be the loudest thing on it.
func _reflect_block(text: String) -> Control:
	var box := PanelContainer.new()
	var st := StyleBoxFlat.new()
	st.bg_color = _accent().darkened(0.72)
	st.bg_color.a = 0.75
	st.border_color = _accent().lightened(0.2)
	st.set_border_width_all(1)
	st.set_corner_radius_all(8)
	st.content_margin_left = 17.0
	st.content_margin_right = 16.0
	st.content_margin_top = 12.0
	st.content_margin_bottom = 13.0
	box.add_theme_stylebox_override("panel", st)
	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 7)
	box.add_child(inner)
	inner.add_child(_eyebrow("SIT WITH THIS", _accent().lightened(0.55)))
	inner.add_child(_quiet_label(text, 18, Color(1, 0.97, 0.9, 1)))
	return box


func _set_body(text: String, allow_reflect: bool) -> void:
	for c in content.get_children():
		c.queue_free()
	var paras: PackedStringArray = text.split("\n\n")
	for i in range(paras.size()):
		var para: String = paras[i].strip_edges()
		if para == "":
			continue
		var is_last: bool = i == paras.size() - 1
		if para.begins_with("\""):
			content.add_child(_quote_block(para))
		elif allow_reflect and is_last and para.ends_with("?"):
			content.add_child(_reflect_block(para))
		else:
			content.add_child(_quiet_label(para, 15, Color(0.84, 0.81, 0.74, 1)))
	body_scroll.scroll_vertical = 0


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
	status_label.visible = true
	status_label.text = "BEFORE YOU PLAY"
	status_label.add_theme_color_override("font_color", _accent().lightened(0.45))
	title_label.text = level["name"]
	ref_label.text = level["reference"] + "   ·   " + level["tagline"]
	_set_body(level["before"], false)


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
		status_label.add_theme_color_override("font_color", _accent().lightened(0.5))
		_set_body(level["after"], true)
	else:
		state = State.LOST
		status_label.text = "ROUND OVER" if score_key != "" else "YOU DID NOT MAKE IT"
		status_label.add_theme_color_override("font_color", Color(0.78, 0.46, 0.4, 1))
		# every level has real loss text now, but never show an empty panel
		var lose_text: String = str(level.get("lose_text", "")).strip_edges()
		if lose_text != "":
			_set_body(lose_text, false)
		else:
			_set_body(level["after"], true)


func _on_play_pressed() -> void:
	_start_gameplay()


func _on_menu_pressed() -> void:
	get_tree().paused = false
	Touch.clear()
	Transition.goto_scene("res://scenes/LevelSelect.tscn")
