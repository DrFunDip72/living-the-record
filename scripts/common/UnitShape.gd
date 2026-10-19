extends Node2D

@export var fill_color: Color = Color(1, 1, 1, 1)
@export var outline_color: Color = Color(0, 0, 0, 1)
@export var radius: float = 12.0
@export var style: String = "figure"  # figure | sheep | diamond | round
# Units further up the field read as further away. Applied to the drawn radius
# rather than to scale, so it never fights the pop() tween.
@export var depth_scale: bool = true
@export var depth_field_height: float = 540.0
@export var depth_range: Vector2 = Vector2(0.86, 1.17)

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


func _depth_mul() -> float:
	if not depth_scale or depth_field_height <= 0.0:
		return 1.0
	if style != "figure" and style != "sheep":
		return 1.0  # projectiles and pickups keep their size
	var t: float = clampf(global_position.y / depth_field_height, 0.0, 1.0)
	return lerpf(depth_range.x, depth_range.y, t)


func _draw() -> void:
	var r := radius * _depth_mul()
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
	_draw_impact_spikes(r)


# Short white spikes thrown out at the instant of a hit. They fade with the
# same _flash value that whitens the body, so the two read as one event.
func _draw_impact_spikes(r: float) -> void:
	if _flash <= 0.4:
		return
	var k: float = (_flash - 0.4) / 0.6
	var col := Color(1, 1, 1, k * 0.9)
	var centre := Vector2(0, -r * 0.25)
	var th: float = maxf(1.2, r * 0.11)
	for i in range(8):
		var a: float = TAU * float(i) / 8.0 + PI * 0.12
		var dir := Vector2(cos(a), sin(a))
		var d0: float = r * (1.15 + (1.0 - k) * 0.55)
		draw_line(centre + dir * d0, centre + dir * (d0 + r * 0.5 * k), col, th)


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


# A rounded pawn: narrow rounded shoulders flaring to a wide base, with a big
# separate head. Reads far better at small sizes than the old cloak polygon.
# grow > 0 inflates it evenly to produce the outline pass.
func _pawn_body(r: float, grow: float, lean: float) -> PackedVector2Array:
	var top: float = -r * 0.52 - grow
	var bot: float = r * 0.95 + grow
	var tw: float = r * 0.34 + grow
	var bw: float = r * 0.62 + grow
	var sh: float = r * 0.18
	return PackedVector2Array([
		Vector2(-bw, bot),
		Vector2(-bw * 0.94, bot - r * 0.26),
		Vector2(-tw - r * 0.05 + lean, top + sh),
		Vector2(-tw * 0.92 + lean, top + sh * 0.3),
		Vector2(-tw * 0.55 + lean, top),
		Vector2(tw * 0.55 + lean, top),
		Vector2(tw * 0.92 + lean, top + sh * 0.3),
		Vector2(tw + r * 0.05 + lean, top + sh),
		Vector2(bw * 0.94, bot - r * 0.26),
		Vector2(bw, bot),
	])


func _draw_figure(r: float) -> void:
	var lean: float = sin(_phase * 2.2) * r * 0.05
	var body := _col()
	var shade := body.darkened(0.32)
	var rim := body.lightened(0.6)
	var top: float = -r * 0.52
	var bot: float = r * 0.95
	var tw: float = r * 0.34
	var bw: float = r * 0.62
	var head_c := Vector2(lean * 0.7, -r * 0.95)
	var head_r: float = r * 0.36

	# silhouette
	draw_colored_polygon(_pawn_body(r, r * 0.13, lean), outline_color)
	draw_circle(head_c, head_r + r * 0.13, outline_color)
	# base fill
	draw_colored_polygon(_pawn_body(r, 0.0, lean), body)
	# form shadow on the away side
	draw_colored_polygon(PackedVector2Array([
		Vector2(lean * 0.3, top),
		Vector2(tw * 0.55 + lean, top),
		Vector2(tw * 0.92 + lean, top + r * 0.054),
		Vector2(tw + r * 0.05 + lean, top + r * 0.18),
		Vector2(bw * 0.94, bot - r * 0.26),
		Vector2(bw, bot),
		Vector2(lean * 0.3, bot),
	]), shade)
	# rim light down the lit edge
	draw_colored_polygon(PackedVector2Array([
		Vector2(-bw, bot),
		Vector2(-bw * 0.94, bot - r * 0.26),
		Vector2(-tw - r * 0.05 + lean, top + r * 0.18),
		Vector2(-tw * 0.74 + lean, top + r * 0.16),
		Vector2(-bw * 0.62, bot - r * 0.26),
		Vector2(-bw * 0.66, bot),
	]), rim)
	# the head casts onto the shoulders
	draw_set_transform(Vector2(lean * 0.5, top + r * 0.06), 0.0, Vector2(1.0, 0.4))
	draw_circle(Vector2.ZERO, head_r * 0.92, Color(0, 0, 0, 0.22))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# head, lit from the upper left
	draw_circle(head_c, head_r, body.lightened(0.06))
	draw_circle(head_c + Vector2(-head_r * 0.2, -head_r * 0.2), head_r * 0.76, body.lightened(0.32))
	draw_arc(head_c + Vector2(-head_r * 0.1, -head_r * 0.1), head_r * 0.64,
		PI * 1.03, PI * 1.6, 10, rim, maxf(1.0, r * 0.09))
