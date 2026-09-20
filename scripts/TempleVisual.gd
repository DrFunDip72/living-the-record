extends Node2D

const STAGE_COLORS := [
	Color(0.35, 0.3, 0.22, 1),
	Color(0.5, 0.5, 0.52, 1),
	Color(0.65, 0.6, 0.55, 1),
	Color(0.85, 0.75, 0.35, 1),
]

@onready var body: Polygon2D = $Body


func grow_stage(stage: int) -> void:
	var s: float = 1.0 + stage * 0.25
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2(s, s), 0.3).set_trans(Tween.TRANS_BACK)
	if stage - 1 >= 0 and stage - 1 < STAGE_COLORS.size():
		body.color = STAGE_COLORS[stage - 1]


func pop(strength: float = 1.2) -> void:
	var base: Vector2 = scale
	var tw := create_tween()
	tw.tween_property(self, "scale", base * strength, 0.05)
	tw.tween_property(self, "scale", base, 0.1)
