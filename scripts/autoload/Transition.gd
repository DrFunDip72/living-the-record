extends CanvasLayer

var _rect: ColorRect
var _rotate: ColorRect


func _ready() -> void:
	layer = 100
	_rect = ColorRect.new()
	_rect.color = Color(0.02, 0.02, 0.03, 1)
	_rect.anchor_right = 1.0
	_rect.anchor_bottom = 1.0
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.modulate.a = 0.0
	add_child(_rect)

	_rotate = ColorRect.new()
	_rotate.color = Color(0.06, 0.05, 0.08, 1)
	_rotate.anchor_right = 1.0
	_rotate.anchor_bottom = 1.0
	_rotate.offset_right = 960.0
	_rotate.offset_bottom = 540.0
	_rotate.visible = false
	var msg := Label.new()
	msg.text = "Turn your phone sideways to play"
	msg.anchor_right = 1.0
	msg.anchor_bottom = 1.0
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	msg.add_theme_font_size_override("font_size", 44)
	_rotate.add_child(msg)
	add_child(_rotate)
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(_delta: float) -> void:
	var win: Vector2i = DisplayServer.window_get_size()
	_rotate.visible = win.y > win.x and win.x > 0


func goto_scene(path: String, duration: float = 0.16) -> void:
	_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	var tw := create_tween()
	tw.tween_property(_rect, "modulate:a", 1.0, duration)
	await tw.finished
	get_tree().change_scene_to_file(path)
	await get_tree().process_frame
	var tw2 := create_tween()
	tw2.tween_property(_rect, "modulate:a", 0.0, duration)
	await tw2.finished
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
