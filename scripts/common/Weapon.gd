extends Node2D

# Shared drawn weapon that points where the owner aims and animates a swing.
# kind: "sword" | "sling"

const INK := Color(0.08, 0.07, 0.08, 1)

@export var kind: String = "sword"
@export var reach: float = 26.0
@export var blade_color: Color = Color(0.88, 0.9, 0.96, 1)
@export var grip_color: Color = Color(0.35, 0.22, 0.12, 1)

var aim: float = 0.0            # radians, set by owner each frame
var swing_t: float = 0.0        # 1 -> 0 during a swing
var swing_dir: float = 1.0
var windup: float = 0.0         # 0..1, raises the weapon before striking
var spin: float = 0.0           # for sling wind-up


func _process(delta: float) -> void:
	if swing_t > 0.0:
		swing_t = maxf(0.0, swing_t - delta * 5.5)
	if kind == "sling" and spin > 0.0:
		spin += delta * 14.0
	queue_redraw()


func set_aim(angle: float) -> void:
	aim = angle


func swing() -> void:
	swing_t = 1.0
	swing_dir = -swing_dir


func set_windup(v: float) -> void:
	windup = clampf(v, 0.0, 1.0)


func start_spin() -> void:
	spin = 0.01


func stop_spin() -> void:
	spin = 0.0


func _draw() -> void:
	match kind:
		"sling":
			_draw_sling()
		_:
			_draw_sword()


func _draw_sword() -> void:
	# swing sweeps the blade through an arc; windup pulls it back
	var arc: float = (1.0 - swing_t) * 1.5 - 0.75
	var ang: float = aim + swing_dir * arc * (1.0 if swing_t > 0.0 else 0.0) - windup * 0.8 * swing_dir
	var base := Vector2(cos(ang), sin(ang)) * (reach * 0.45)
	var tip := Vector2(cos(ang), sin(ang)) * (reach * (1.35 + swing_t * 0.25))
	var perp := Vector2(-sin(ang), cos(ang))

	# motion trail while swinging
	if swing_t > 0.0:
		var pts := PackedVector2Array()
		pts.append(Vector2.ZERO)
		var steps := 8
		for i in range(steps + 1):
			var t: float = float(i) / float(steps)
			var a: float = ang - swing_dir * t * 1.1
			pts.append(Vector2(cos(a), sin(a)) * reach * 1.3)
		draw_colored_polygon(pts, Color(1, 1, 0.85, 0.28 * swing_t))

	# grip + guard
	draw_line(Vector2.ZERO, base, grip_color, 5.0)
	draw_line(base - perp * 6.0, base + perp * 6.0, INK, 4.0)
	# blade
	draw_line(base, tip, INK, 7.0)
	draw_line(base, tip, blade_color, 4.0)


func _draw_sling() -> void:
	var ang: float = aim
	var perp := Vector2(-sin(ang), cos(ang))
	var hand := Vector2(cos(ang), sin(ang)) * (reach * 0.35)
	if spin > 0.0:
		# whirling pouch around the hand
		var r: float = reach * 0.75
		var p := hand + Vector2(cos(spin), sin(spin)) * r
		draw_line(hand, p, Color(0.72, 0.62, 0.45, 1), 2.5)
		draw_circle(p, 4.5, INK)
		draw_circle(p, 3.0, Color(0.62, 0.58, 0.5, 1))
		var trail := PackedVector2Array()
		for i in range(10):
			var a: float = spin - float(i) * 0.35
			trail.append(hand + Vector2(cos(a), sin(a)) * r)
		for i in range(trail.size() - 1):
			draw_line(trail[i], trail[i + 1], Color(1, 1, 0.9, 0.18), 2.0)
	else:
		var p := hand + Vector2(cos(ang), sin(ang)) * (reach * 0.5) + perp * 4.0
		draw_line(hand, p, Color(0.72, 0.62, 0.45, 1), 2.5)
		draw_circle(p, 3.5, Color(0.5, 0.46, 0.4, 1))
	draw_line(Vector2.ZERO, hand, grip_color, 4.0)
