extends Node2D

@export var fill_color: Color = Color(1, 1, 1, 1)
@export var outline_color: Color = Color(0, 0, 0, 1)
@export var radius: float = 12.0
@export var style: String = "figure"  # figure | sheep | diamond | round

var _flash: float = 0.0
var _phase: float = 0.0


func _ready() -> void:
	_phase = randf() * TAU
	queue_redraw()


func _process(delta: float) -> void:
	_phase += delta
	if _flash > 0.0:
		_flash = maxf(0.0, _flash - delta * 8.0)
		queue_redraw()
	elif style == "sheep" or style == "figure":
		queue_redraw()


func set_colors(p_fill: Color, p_outline: Color) -> void:
	fill_color = p_fill
	outline_color = p_outline
	queue_redraw()


func flash_white(duration: float = 0.12) -> void:
	_flash = 1.0
	pop()
	queue_redraw()


func pop(strength: float = 1.3) -> void:
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2(strength, strength) * 0.86, 0.05)
	tw.tween_property(self, "scale", Vector2(1, 1), 0.12).set_trans(Tween.TRANS_BACK)


func _col() -> Color:
	return fill_color.lerp(Color(1, 1, 1, 1), _flash)


func _draw() -> void:
	var r := radius
	match style:
		"sheep":
			_draw_ground_shadow(r, 1.35)
			_draw_sheep(r)
		"diamond":
			draw_circle(Vector2(0, r * 0.5), r * 0.85, Color(0, 0, 0, 0.22))
			_draw_diamond(r)
		"round":
			draw_circle(Vector2(0, r * 0.5), r * 0.85, Color(0, 0, 0, 0.22))
			draw_circle(Vector2.ZERO, r * 1.25, outline_color)
			draw_circle(Vector2.ZERO, r, _col())
			# lit from the upper left, same as every grounded shape
			draw_circle(Vector2(-r * 0.22, -r * 0.22), r * 0.62, _col().lightened(0.28))
		_:
			_draw_ground_shadow(r, 1.0)
			_draw_figure(r)


# One light direction for the whole game: upper left. The cast shadow leans away
# from it, the contact shadow stays tight under the feet so the unit reads as
# standing on the ground instead of floating above it.
func _draw_ground_shadow(r: float, spread: float) -> void:
	draw_set_transform(Vector2(r * 0.40 * spread, r * 0.66), 0.0, Vector2(1.0, 0.30))
	draw_circle(Vector2.ZERO, r * 1.18 * spread, Color(0, 0, 0, 0.17))
	draw_set_transform(Vector2(0, r * 0.86), 0.0, Vector2(1.0, 0.24))
	draw_circle(Vector2.ZERO, r * 0.60 * spread, Color(0, 0, 0, 0.30))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_diamond(r: float) -> void:
	var o := PackedVector2Array([
		Vector2(0, -r * 1.42), Vector2(r * 1.02, 0), Vector2(0, r * 1.42), Vector2(-r * 1.02, 0)])
	draw_colored_polygon(o, outline_color)
	var f := PackedVector2Array([
		Vector2(0, -r), Vector2(r * 0.72, 0), Vector2(0, r), Vector2(-r * 0.72, 0)])
	draw_colored_polygon(f, _col())


func _draw_sheep(r: float) -> void:
	var bob: float = sin(_phase * 1.6) * r * 0.06
	var wool := _col()
	for off in [Vector2(-r * 0.55, bob), Vector2(r * 0.1, -r * 0.35 + bob), Vector2(r * 0.55, bob), Vector2(0, r * 0.25 + bob)]:
		draw_circle(off, r * 0.72, outline_color)
	for off in [Vector2(-r * 0.55, bob), Vector2(r * 0.1, -r * 0.35 + bob), Vector2(r * 0.55, bob), Vector2(0, r * 0.25 + bob)]:
		draw_circle(off, r * 0.58, wool)
	# head
	draw_circle(Vector2(r * 0.95, r * 0.05 + bob), r * 0.42, outline_color)
	draw_circle(Vector2(r * 0.95, r * 0.05 + bob), r * 0.3, Color(0.22, 0.2, 0.19, 1))
	# legs
	draw_line(Vector2(-r * 0.4, r * 0.7), Vector2(-r * 0.4, r * 1.15), outline_color, 2.5)
	draw_line(Vector2(r * 0.4, r * 0.7), Vector2(r * 0.4, r * 1.15), outline_color, 2.5)


func _draw_figure(r: float) -> void:
	var sway: float = sin(_phase * 2.2) * r * 0.06
	var body := _col()
	# shoulders / cloak
	var sh := PackedVector2Array([
		Vector2(-r * 0.95, r * 0.15 + sway), Vector2(-r * 0.6, -r * 0.55),
		Vector2(r * 0.6, -r * 0.55), Vector2(r * 0.95, r * 0.15 + sway),
		Vector2(r * 0.55, r * 0.95), Vector2(-r * 0.55, r * 0.95),
	])
	draw_colored_polygon(sh, outline_color)
	var sh_in := PackedVector2Array([
		Vector2(-r * 0.72, r * 0.1 + sway), Vector2(-r * 0.45, -r * 0.4),
		Vector2(r * 0.45, -r * 0.4), Vector2(r * 0.72, r * 0.1 + sway),
		Vector2(r * 0.42, r * 0.75), Vector2(-r * 0.42, r * 0.75),
	])
	draw_colored_polygon(sh_in, body)
	# form shadow on the away side
	var shade := body.darkened(0.30)
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, -r * 0.4), Vector2(r * 0.45, -r * 0.4),
		Vector2(r * 0.72, r * 0.1 + sway), Vector2(r * 0.42, r * 0.75), Vector2(0, r * 0.75),
	]), shade)
	# rim light down the lit edge
	draw_colored_polygon(PackedVector2Array([
		Vector2(-r * 0.72, r * 0.1 + sway), Vector2(-r * 0.45, -r * 0.4),
		Vector2(-r * 0.28, -r * 0.4), Vector2(-r * 0.54, r * 0.08 + sway),
		Vector2(-r * 0.26, r * 0.75), Vector2(-r * 0.42, r * 0.75),
	]), body.lightened(0.55))
	# the head casts onto the shoulders
	draw_set_transform(Vector2(r * 0.05, -r * 0.3), 0.0, Vector2(1.0, 0.42))
	draw_circle(Vector2.ZERO, r * 0.4, Color(0, 0, 0, 0.20))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# head
	var head := Vector2(0, -r * 0.62)
	draw_circle(head, r * 0.46, outline_color)
	draw_circle(head, r * 0.34, body.lightened(0.08))
	draw_circle(head + Vector2(-r * 0.07, -r * 0.07), r * 0.26, body.lightened(0.34))
	draw_arc(head + Vector2(-r * 0.05, -r * 0.05), r * 0.23,
		PI * 1.02, PI * 1.62, 8, body.lightened(0.7), maxf(1.0, r * 0.08))
