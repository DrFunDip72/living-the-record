extends Node2D

signal pressed_spot

var occupied: bool = false
var projectiles_container: Node

@onready var area: Area2D = $Area2D
@onready var marker: Node2D = $Marker
@onready var tower_slot: Node2D = $TowerSlot


func _ready() -> void:
	area.input_pickable = true
	area.input_event.connect(_on_input_event)


func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		pressed_spot.emit()


func build_tower() -> void:
	if occupied:
		return
	occupied = true
	marker.visible = false
	var tower := preload("res://scenes/Tower.tscn").instantiate()
	tower.projectiles_container = projectiles_container
	tower_slot.add_child(tower)
