extends Node2D

const GAME_ICON := preload("res://scripts/common/GameIcon.gd")

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
	btn.custom_minimum_size = Vector2(212, 200)
	btn.text = ""

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.11, 0.10, 0.14, 1)
	style.border_color = accent.darkened(0.15)
	style.set_border_width_all(3)
	style.set_corner_radius_all(14)
	style.shadow_color = Color(0, 0, 0, 0.35)
	style.shadow_size = 6
	btn.add_theme_stylebox_override("normal", style)

	var hover := style.duplicate()
	hover.bg_color = Color(0.17, 0.16, 0.21, 1)
	hover.border_color = accent.lightened(0.25)
	hover.set_border_width_all(4)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", hover)
	btn.add_theme_stylebox_override("focus", hover)

	var vbox := VBoxContainer.new()
	vbox.anchor_right = 1.0
	vbox.anchor_bottom = 1.0
	vbox.offset_left = 10.0
	vbox.offset_top = 10.0
	vbox.offset_right = -10.0
	vbox.offset_bottom = -10.0
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_theme_constant_override("separation", 3)
	btn.add_child(vbox)

	# Thumbnail panel with drawn art
	var thumb := PanelContainer.new()
	thumb.custom_minimum_size = Vector2(0, 82)
	thumb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var thumb_style := StyleBoxFlat.new()
	thumb_style.bg_color = accent.darkened(0.62)
	thumb_style.set_corner_radius_all(10)
	thumb_style.border_color = accent.darkened(0.3)
	thumb_style.set_border_width_all(2)
	thumb.add_theme_stylebox_override("panel", thumb_style)
	vbox.add_child(thumb)

	var icon := Control.new()
	icon.set_script(GAME_ICON)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.custom_minimum_size = Vector2(0, 78)
	thumb.add_child(icon)
	icon.set_icon(lvl.get("icon", "swords"), accent)

	var name_label := Label.new()
	name_label.text = lvl["name"]
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 19)
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(name_label)

	var tag := Label.new()
	tag.text = lvl["tagline"]
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tag.autowrap_mode = TextServer.AUTOWRAP_WORD
	tag.add_theme_font_size_override("font_size", 12)
	tag.add_theme_color_override("font_color", Color(0.78, 0.76, 0.72, 1))
	tag.add_theme_constant_override("outline_size", 0)
	tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(tag)

	var footer := HBoxContainer.new()
	footer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	footer.alignment = BoxContainer.ALIGNMENT_CENTER
	footer.add_theme_constant_override("separation", 10)
	vbox.add_child(footer)

	var ref := Label.new()
	ref.text = lvl["reference"]
	ref.add_theme_font_size_override("font_size", 12)
	ref.add_theme_color_override("font_color", accent.lightened(0.35))
	ref.add_theme_constant_override("outline_size", 0)
	ref.mouse_filter = Control.MOUSE_FILTER_IGNORE
	footer.add_child(ref)

	var score_key: String = lvl.get("score_key", "")
	if score_key != "":
		var best := Label.new()
		best.text = "Best: %d" % HighScores.get_best(score_key)
		best.add_theme_font_size_override("font_size", 12)
		best.add_theme_color_override("font_color", Color(1, 0.85, 0.4, 1))
		best.add_theme_constant_override("outline_size", 0)
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
