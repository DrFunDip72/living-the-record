extends Node


func spawn_hit_burst(parent: Node, pos: Vector2, color: Color, amount: int = 14) -> void:
	var particles := CPUParticles2D.new()
	particles.position = pos
	particles.one_shot = true
	particles.amount = amount
	particles.lifetime = 0.4
	particles.explosiveness = 1.0
	particles.direction = Vector2(0, -1)
	particles.spread = 180.0
	particles.gravity = Vector2(0, 300)
	particles.initial_velocity_min = 60.0
	particles.initial_velocity_max = 160.0
	particles.scale_amount_min = 2.0
	particles.scale_amount_max = 4.0
	particles.color = color
	parent.add_child(particles)
	particles.emitting = true
	particles.finished.connect(particles.queue_free)


# A number that pops off the target and fades. Parent it to the game root, not
# to the unit, so it survives the unit being freed on the same hit.
func damage_number(parent: Node, pos: Vector2, amount: int,
		color: Color = Color(0.95, 0.79, 0.42, 1)) -> void:
	if parent == null or not is_instance_valid(parent) or amount <= 0:
		return
	var label := Label.new()
	label.text = str(amount)
	label.z_index = 200
	label.add_theme_font_size_override("font_size", 17)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0.05, 0.04, 0.07, 1))
	label.add_theme_constant_override("outline_size", 4)
	label.position = pos + Vector2(-10.0, -14.0)
	parent.add_child(label)
	var tw := label.create_tween()
	tw.set_parallel(true)
	tw.tween_property(label, "position",
		label.position + Vector2(randf_range(-7.0, 7.0), -28.0), 0.55) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(label, "modulate:a", 0.0, 0.55).set_trans(Tween.TRANS_QUAD)
	tw.chain().tween_callback(label.queue_free)


func hit_stop(duration: float = 0.06) -> void:
	Engine.time_scale = 0.05
	var t := get_tree().create_timer(duration, true, false, true)
	t.timeout.connect(func(): Engine.time_scale = 1.0)
