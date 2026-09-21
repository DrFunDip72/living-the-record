extends CanvasLayer

# On-screen controls for phones. Games call configure() in _ready and clear()
# in _exit_tree. Left half = virtual joystick, right half = aim/attack zone.

signal aim_pressed(screen_pos: Vector2)
signal aim_released(screen_pos: Vector2)
signal button_pressed(name: String)

const JOY_RADIUS := 64.0
const JOY_HOME := Vector2(120, 430)

var active: bool = false
var use_joystick: bool = false
var use_aim: bool = false
var move_vector: Vector2 = Vector2.ZERO
var aim_screen: Vector2 = Vector2.ZERO
var aim_held: bool = false
var force_touch: bool = false

var _joy_index: int = -1
var _aim_index: int = -1
var _joy_center: Vector2 = JOY_HOME
var _joy_knob: Vector2 = JOY_HOME
var _pad: Control
var _buttons: Dictionary = {}
var _button_box: VBoxContainer


func _ready() -> void:
	layer = 50
	force_touch = OS.get_cmdline_user_args().has("touch")
	_pad = Control.new()
	_pad.anchor_right = 1.0
	_pad.anchor_bottom = 1.0
	_pad.offset_right = 960.0
	_pad.offset_bottom = 540.0
	_pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pad.draw.connect(_draw_pad)
	add_child(_pad)
	_button_box = VBoxContainer.new()
	_button_box.anchor_left = 1.0
	_button_box.anchor_right = 1.0
	_button_box.anchor_top = 1.0
	_button_box.anchor_bottom = 1.0
	_button_box.offset_left = -150.0
	_button_box.offset_right = -18.0
	_button_box.offset_top = -210.0
	_button_box.offset_bottom = -30.0
	_button_box.alignment = BoxContainer.ALIGNMENT_END
	_button_box.add_theme_constant_override("separation", 12)
	add_child(_button_box)
	visible = false


func is_touch() -> bool:
	return force_touch or DisplayServer.is_touchscreen_available()


func configure(opts: Dictionary) -> void:
	clear()
	if not is_touch():
		return
	active = true
	visible = true
	use_joystick = opts.get("joystick", false)
	use_aim = opts.get("aim", false)
	for bname in opts.get("buttons", []):
		var b := Button.new()
		b.text = bname
		b.custom_minimum_size = Vector2(132, 76)
		b.add_theme_font_size_override("font_size", 22)
		b.modulate = Color(1, 1, 1, 0.85)
		b.pressed.connect(func(): button_pressed.emit(bname))
		_button_box.add_child(b)
		_buttons[bname] = b
	_pad.queue_redraw()


func clear() -> void:
	active = false
	visible = false
	use_joystick = false
	use_aim = false
	move_vector = Vector2.ZERO
	aim_held = false
	_joy_index = -1
	_aim_index = -1
	_joy_center = JOY_HOME
	_joy_knob = JOY_HOME
	for b in _buttons.values():
		b.queue_free()
	_buttons.clear()


func aim_world(canvas_item: CanvasItem) -> Vector2:
	return canvas_item.get_canvas_transform().affine_inverse() * aim_screen


func _over_button(pos: Vector2) -> bool:
	for b in _buttons.values():
		if b.get_global_rect().has_point(pos):
			return true
	return false


func _input(event: InputEvent) -> void:
	if not active:
		return
	if event is InputEventScreenTouch:
		var t := event as InputEventScreenTouch
		if t.pressed:
			if _over_button(t.position):
				return
			if use_joystick and _joy_index == -1 and t.position.x < 480.0:
				_joy_index = t.index
				_joy_center = t.position
				_joy_knob = t.position
				move_vector = Vector2.ZERO
			elif use_aim and _aim_index == -1 and t.position.x >= 480.0:
				_aim_index = t.index
				aim_screen = t.position
				aim_held = true
				aim_pressed.emit(t.position)
		else:
			if t.index == _joy_index:
				_joy_index = -1
				move_vector = Vector2.ZERO
				_joy_center = JOY_HOME
				_joy_knob = JOY_HOME
			elif t.index == _aim_index:
				_aim_index = -1
				aim_held = false
				aim_released.emit(t.position)
		_pad.queue_redraw()
	elif event is InputEventScreenDrag:
		var d := event as InputEventScreenDrag
		if d.index == _joy_index:
			var off: Vector2 = (d.position - _joy_center).limit_length(JOY_RADIUS)
			_joy_knob = _joy_center + off
			move_vector = off / JOY_RADIUS
		elif d.index == _aim_index:
			aim_screen = d.position
		_pad.queue_redraw()


func _draw_pad() -> void:
	if not active:
		return
	if use_joystick:
		_pad.draw_circle(_joy_center, JOY_RADIUS + 8.0, Color(0, 0, 0, 0.28))
		_pad.draw_arc(_joy_center, JOY_RADIUS + 8.0, 0.0, TAU, 32, Color(1, 1, 1, 0.35), 2.0)
		_pad.draw_circle(_joy_knob, 30.0, Color(1, 1, 1, 0.45))
	if use_aim:
		if aim_held:
			_pad.draw_circle(aim_screen, 26.0, Color(1, 0.9, 0.5, 0.25))
			_pad.draw_arc(aim_screen, 26.0, 0.0, TAU, 24, Color(1, 0.9, 0.5, 0.8), 2.0)
		else:
			var font := ThemeDB.fallback_font
			_pad.draw_string(font, Vector2(560, 405), "right side: tap / hold to aim & strike", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(1, 1, 1, 0.35))
