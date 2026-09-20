extends Camera2D

var trauma: float = 0.0
const TRAUMA_DECAY := 2.2
const MAX_SHAKE_OFFSET := 14.0


func _process(delta: float) -> void:
	if trauma > 0.0:
		trauma = max(trauma - TRAUMA_DECAY * delta, 0.0)
		var amount: float = trauma * trauma
		offset = Vector2(
			randf_range(-1.0, 1.0) * MAX_SHAKE_OFFSET * amount,
			randf_range(-1.0, 1.0) * MAX_SHAKE_OFFSET * amount
		)
	elif offset != Vector2.ZERO:
		offset = Vector2.ZERO


func shake(amount: float = 0.5) -> void:
	trauma = clamp(trauma + amount, 0.0, 1.0)
