extends Node2D

@onready var list: VBoxContainer = $UI/ScrollContainer/List
@onready var back_button: Button = $UI/BackButton


func _ready() -> void:
	back_button.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/Title.tscn"))
	_populate()


func _populate() -> void:
	for child in list.get_children():
		child.queue_free()
	for lvl in Game.levels:
		var btn := Button.new()
		var label_text: String = lvl["title"]
		var score_key: String = lvl.get("score_key", "")
		if score_key != "":
			label_text += "   (Best: %d)" % HighScores.get_best(score_key)
		btn.text = label_text
		btn.custom_minimum_size = Vector2(0, 50)
		btn.pressed.connect(func(): Game.start_level(lvl["id"]))
		list.add_child(btn)
