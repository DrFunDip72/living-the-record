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


func hit_stop(duration: float = 0.06) -> void:
	Engine.time_scale = 0.05
	var t := get_tree().create_timer(duration, true, false, true)
	t.timeout.connect(func(): Engine.time_scale = 1.0)
