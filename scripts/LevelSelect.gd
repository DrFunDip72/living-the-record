extends Node2D

const GAME_ICON := preload("res://scripts/common/GameIcon.gd")
const DISPLAY_FONT := preload("res://fonts/Cinzel.ttf")

@onready var grid: GridContainer = $UI/ScrollContainer/Grid
@onready var search_box: LineEdit = $UI/Header/SearchBox
@onready var home_button: Button = $UI/Header/HomeButton
@onready var empty_label: Label = $UI/EmptyLabel


func _ready() -> void:
	home_button.pressed.connect(func(): Transition.goto_scene("res://scenes/Title.tscn"))
	search_box.text_changed.connect(_on_search_changed)
	_populate(Game.levels)


func _on_search_changed(text: String) -> void:
	_populate(Game.search(text))


func _populate(list: Array) -> void:
	for child in grid.get_children():
		child.queue_free()
	empty_label.visible = list.is_empty()
	for lvl in list:
		grid.add_child(_build_tile(lvl))


func _build_tile(lvl: Dictionary) -> Control:
	var accent: Color = lvl.get("color", Color(0.5, 0.5, 0.5, 1))

	var btn := Button.new()
	btn.custom_minimum_size = Vector2(212, 206)
	btn.text = ""
	btn.clip_contents = true  # keeps the full-bleed art inside the rounded corners

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.095, 0.088, 0.125, 1)
	style.border_color = accent.darkened(0.3)
	style.set_border_width_all(2)
	style.set_corner_radius_all(13)
	style.shadow_color = Color(0, 0, 0, 0.4)
	style.shadow_size = 6
	style.content_margin_left = 0.0
	style.content_margin_right = 0.0
	style.content_margin_top = 0.0
	style.content_margin_bottom = 0.0
	btn.add_theme_stylebox_override("normal", style)

	var hover := style.duplicate()
	hover.bg_color = Color(0.145, 0.135, 0.185, 1)
	hover.border_color = accent.lightened(0.3)
	hover.set_border_width_all(2)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", hover)
	btn.add_theme_stylebox_override("focus", hover)

	var vbox := VBoxContainer.new()
	vbox.anchor_right = 1.0
	vbox.anchor_bottom = 1.0
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_theme_constant_override("separation", 0)
	btn.add_child(vbox)

	# Full-bleed silhouette scene across the top of the card
	var thumb := Control.new()
	thumb.set_script(GAME_ICON)
	thumb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	thumb.custom_minimum_size = Vector2(0, 96)
	thumb.clip_contents = true
	vbox.add_child(thumb)
	thumb.set_icon(lvl.get("icon", "swords"), accent)

	var pad := MarginContainer.new()
	pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pad.add_theme_constant_override("margin_left", 11)
	pad.add_theme_constant_override("margin_right", 11)
	pad.add_theme_constant_override("margin_top", 8)
	pad.add_theme_constant_override("margin_bottom", 9)
	pad.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(pad)

	var col := VBoxContainer.new()
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_theme_constant_override("separation", 4)
	pad.add_child(col)

	var name_label := Label.new()
	name_label.text = lvl["name"]
	name_label.add_theme_font_override("font", DISPLAY_FONT)
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.add_theme_color_override("font_color", Color(0.99, 0.96, 0.89, 1))
	name_label.add_theme_constant_override("outline_size", 0)
	name_label.add_theme_constant_override("shadow_offset_x", 0)
	name_label.add_theme_constant_override("shadow_offset_y", 0)
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(name_label)

	# Fixed two-line box so every row in the grid lines up
	var tag := Label.new()
	tag.text = lvl["tagline"]
	tag.autowrap_mode = TextServer.AUTOWRAP_WORD
	tag.custom_minimum_size = Vector2(0, 32)
	tag.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	tag.add_theme_font_size_override("font_size", 12)
	tag.add_theme_color_override("font_color", Color(0.72, 0.70, 0.67, 1))
	tag.add_theme_constant_override("outline_size", 0)
	tag.add_theme_constant_override("shadow_offset_x", 0)
	tag.add_theme_constant_override("shadow_offset_y", 0)
	tag.add_theme_constant_override("line_spacing", 1)
	tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(tag)

	var footer := HBoxContainer.new()
	footer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	footer.add_theme_constant_override("separation", 7)
	col.add_child(footer)

	# reference as a bordered pill in the game's own accent
	var pill := PanelContainer.new()
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var pill_style := StyleBoxFlat.new()
	pill_style.bg_color = accent.darkened(0.68)
	pill_style.border_color = accent.lightened(0.1)
	pill_style.set_border_width_all(1)
	pill_style.set_corner_radius_all(9)
	pill_style.content_margin_left = 7.0
	pill_style.content_margin_right = 7.0
	pill_style.content_margin_top = 1.0
	pill_style.content_margin_bottom = 2.0
	pill.add_theme_stylebox_override("panel", pill_style)
	footer.add_child(pill)

	var ref := Label.new()
	ref.text = lvl["reference"]
	ref.add_theme_font_size_override("font_size", 11)
	ref.add_theme_color_override("font_color", accent.lightened(0.62))
	ref.add_theme_constant_override("outline_size", 0)
	ref.add_theme_constant_override("shadow_offset_x", 0)
	ref.add_theme_constant_override("shadow_offset_y", 0)
	ref.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pill.add_child(ref)

	var spacer := Control.new()
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(spacer)

	var score_key: String = lvl.get("score_key", "")
	if score_key != "":
		var best := Label.new()
		best.text = "BEST %d" % HighScores.get_best(score_key)
		best.add_theme_font_size_override("font_size", 11)
		best.add_theme_color_override("font_color", Color(0.88, 0.74, 0.38, 1))
		best.add_theme_constant_override("outline_size", 0)
		best.add_theme_constant_override("shadow_offset_x", 0)
		best.add_theme_constant_override("shadow_offset_y", 0)
		best.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		best.mouse_filter = Control.MOUSE_FILTER_IGNORE
		footer.add_child(best)

	btn.pressed.connect(func():
		_pop(btn)
		Game.start_level(lvl["id"])
	)
	return btn


func _pop(node: Control, target: float = 1.05) -> void:
	node.pivot_offset = node.size / 2.0
	var tw := create_tween()
	tw.tween_property(node, "scale", Vector2(target, target), 0.06)
	tw.tween_property(node, "scale", Vector2(1, 1), 0.12)
