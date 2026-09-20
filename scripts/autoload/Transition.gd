extends CanvasLayer

var _rect: ColorRect


func _ready() -> void:
	layer = 100
	_rect = ColorRect.new()
	_rect.color = Color(0.02, 0.02, 0.03, 1)
	_rect.anchor_right = 1.0
	_rect.anchor_bottom = 1.0
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.modulate.a = 0.0
	add_child(_rect)


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
