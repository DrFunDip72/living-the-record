extends Node2D

@onready var play_button: Button = $UI/PlayButton
@onready var about_button: Button = $UI/AboutButton
@onready var about_panel: Panel = $UI/AboutPanel
@onready var about_label: RichTextLabel = $UI/AboutPanel/AboutLabel
@onready var about_close: Button = $UI/AboutPanel/CloseButton


func _ready() -> void:
	play_button.pressed.connect(func(): Transition.goto_scene("res://scenes/LevelSelect.tscn"))
	about_button.pressed.connect(func(): about_panel.visible = true)
	about_close.pressed.connect(func(): about_panel.visible = false)
	about_panel.visible = false
	about_label.text = "These stories were preserved so that we could believe -- not just know about them, but let them change us.\n\n\"...these things are written that we may believe...\"\n\nMade for REL A 275 -- Book of Mormon Project."
