extends Node2D

@export var fill_color: Color = Color(1, 1, 1, 1)
@export var outline_color: Color = Color(0, 0, 0, 1)
@export var radius: float = 12.0

@onready var shadow: Polygon2D = $Shadow
@onready var outline: Polygon2D = $Outline
@onready var fill: Polygon2D = $Fill


func _ready() -> void:
	_rebuild()


func _rebuild() -> void:
	fill.polygon = _diamond(radius)
	outline.polygon = _diamond(radius * 1.45)
	shadow.polygon = _diamond(radius * 0.9)
	fill.color = fill_color
	outline.color = outline_color
	shadow.position = Vector2(0, radius * 0.4)
	shadow.color = Color(0, 0, 0, 0.28)


func _diamond(r: float) -> PackedVector2Array:
	return PackedVector2Array([Vector2(0, -r), Vector2(r * 0.72, 0), Vector2(0, r), Vector2(-r * 0.72, 0)])


func set_colors(p_fill: Color, p_outline: Color) -> void:
	fill_color = p_fill
	outline_color = p_outline
	if is_inside_tree():
		_rebuild()


func flash_white(duration: float = 0.1) -> void:
	if not is_instance_valid(fill):
		return
	var original: Color = fill_color
	fill.color = Color(1, 1, 1, 1)
	get_tree().create_timer(duration).timeout.connect(func():
		if is_instance_valid(fill):
			fill.color = original
	)
	pop()


func pop(strength: float = 1.35) -> void:
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2(strength, strength) * 0.85, 0.05)
	tw.tween_property(self, "scale", Vector2(1, 1), 0.12).set_trans(Tween.TRANS_BACK)
