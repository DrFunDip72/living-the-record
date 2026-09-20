extends Node2D

@onready var grid: GridContainer = $UI/ScrollContainer/Grid
@onready var back_button: Button = $UI/BackButton


func _ready() -> void:
	back_button.pressed.connect(func(): Transition.goto_scene("res://scenes/Title.tscn"))
	_populate()


func _populate() -> void:
	for child in grid.get_children():
		child.queue_free()
	for lvl in Game.levels:
		grid.add_child(_build_card(lvl))


func _build_card(lvl: Dictionary) -> Control:
	var accent: Color = lvl.get("color", Color(0.5, 0.5, 0.5, 1))

	var btn := Button.new()
	btn.custom_minimum_size = Vector2(300, 170)
	btn.text = ""
	btn.clip_text = false

	var style := StyleBoxFlat.new()
	style.bg_color = accent.darkened(0.55)
	style.border_color = accent
	style.set_border_width_all(3)
	style.set_corner_radius_all(16)
	btn.add_theme_stylebox_override("normal", style)

	var style_hover := style.duplicate()
	style_hover.bg_color = accent.darkened(0.35)
	style_hover.border_color = accent.lightened(0.2)
	btn.add_theme_stylebox_override("hover", style_hover)
	btn.add_theme_stylebox_override("pressed", style_hover)
	btn.add_theme_stylebox_override("focus", style_hover)

	var vbox := VBoxContainer.new()
	vbox.anchor_right = 1.0
	vbox.anchor_bottom = 1.0
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_theme_constant_override("separation", 8)
	btn.add_child(vbox)

	var badge_wrap := CenterContainer.new()
	badge_wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(badge_wrap)

	var badge := PanelContainer.new()
	badge.custom_minimum_size = Vector2(56, 56)
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var badge_style := StyleBoxFlat.new()
	badge_style.bg_color = accent
	badge_style.set_corner_radius_all(28)
	badge_style.border_color = Color(0, 0, 0, 0.45)
	badge_style.set_border_width_all(2)
	badge.add_theme_stylebox_override("panel", badge_style)
	badge_wrap.add_child(badge)

	var mono := Label.new()
	mono.text = lvl.get("monogram", "?")
	mono.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mono.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	mono.custom_minimum_size = Vector2(56, 56)
	mono.add_theme_font_size_override("font_size", 24)
	mono.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.add_child(mono)

	var title := Label.new()
	title.text = lvl["title"]
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD
	title.custom_minimum_size = Vector2(260, 0)
	title.add_theme_font_size_override("font_size", 15)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(title)

	var score_key: String = lvl.get("score_key", "")
	if score_key != "":
		var score_lbl := Label.new()
		score_lbl.text = "Best: %d" % HighScores.get_best(score_key)
		score_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		score_lbl.add_theme_font_size_override("font_size", 14)
		score_lbl.add_theme_color_override("font_color", Color(1, 0.85, 0.4, 1))
		score_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(score_lbl)

	btn.pressed.connect(func():
		_pop(btn)
		Game.start_level(lvl["id"])
	)
	return btn


func _pop(node: Control, target: float = 1.06) -> void:
	node.pivot_offset = node.size / 2.0
	var tw := create_tween()
	tw.tween_property(node, "scale", Vector2(target, target), 0.06)
	tw.tween_property(node, "scale", Vector2(1, 1), 0.12)
