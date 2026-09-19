extends Node2D

enum State { INTRO, BEFORE, PLAYING, WON, LOST, OUTRO }

var state: State = State.INTRO
var beat_index: int = 0
var current_instance: Node = null
var beats: Array = []

@onready var gameplay_root: Node2D = $GameplayRoot
@onready var ui: CanvasLayer = $UI
@onready var title_label: Label = $UI/TitleLabel
@onready var body_label: RichTextLabel = $UI/BodyLabel
@onready var continue_button: Button = $UI/ContinueButton


func _ready() -> void:
	beats = [
		{
			"title": "1 -- Alma 56-57: The Stripling Warriors",
			"before": "Two thousand young men join Helaman's army during the wars with the Lamanites.\n\n\"...they were exceedingly valiant for courage, and also for strength and activity; but behold, this was not all -- they were men who were true at all times in whatsoever thing they were entrusted... they did not doubt.\"\n\nTheir strength was not skill in battle -- it was that they obeyed exactly, without hesitation, even when they could not see the whole plan.\n\nYou are one warrior in the line. Your commander will call out orders -- watch the field, and move to where you're needed before time runs out. Freeze, wander, or arrive late, and the formation breaks.",
			"scene": load("res://scenes/MiniGameFormation.tscn"),
			"after": "The stripling warriors survived because they trusted their leaders completely and obeyed exactly -- even without seeing the whole battlefield.\n\nWhere in your own life do you follow counsel exactly, even when you don't see the full picture? Where do you \"almost\" obey?",
			"lose_text": "A moment's hesitation broke the line. In the real battle, this was the difference between life and death.\n\nTry again -- exactness has no partial credit."
		},
		{
			"title": "2 -- Mosiah 18: Alma Flees the Guards of King Noah",
			"before": "Alma, once a priest of wicked King Noah, repented after hearing Abinadi's words. He taught the people in secret at the Waters of Mormon and organized a church there -- until Noah discovered them and sent soldiers to destroy them.\n\n\"...as many as did believe... went forth... and were baptized... and they were called the church of God...\" Then Noah's guards came, \"and Alma and the people of the Lord were apprised of their coming... therefore they took their tents and their families and departed into the wilderness.\"\n\nStay out of the guards' sight and reach the Waters of Mormon.",
			"scene": load("res://scenes/MiniGameFleeHide.tscn"),
			"after": "Alma's people didn't just believe quietly -- they made a public covenant, then paid a real price for it: exile, fear, running for their lives.\n\nWhat has a real commitment ever cost you? Was it worth it?",
			"lose_text": "The guards found you. For Alma's people, discovery meant death.\n\nTry again -- slip past unseen."
		}
	]
	continue_button.pressed.connect(_on_continue_button_pressed)
	_show_intro()


func _show_intro() -> void:
	state = State.INTRO
	gameplay_root.visible = false
	ui.visible = true
	title_label.text = "Living the Record"
	body_label.text = "You are helping compile the record -- stepping into a few moments from the Book of Mormon so you can feel, not just read, what happened.\n\nEach story begins with the scripture text, then drops you into the moment itself."
	continue_button.text = "Begin"


func _show_before(index: int) -> void:
	state = State.BEFORE
	var beat = beats[index]
	title_label.text = beat["title"]
	body_label.text = beat["before"]
	continue_button.text = "Play"
	ui.visible = true
	gameplay_root.visible = false


func _start_gameplay(index: int) -> void:
	state = State.PLAYING
	ui.visible = false
	gameplay_root.visible = true
	var beat = beats[index]
	current_instance = beat["scene"].instantiate()
	gameplay_root.add_child(current_instance)
	current_instance.game_finished.connect(_on_game_finished)


func _on_game_finished(won: bool) -> void:
	if current_instance:
		current_instance.queue_free()
		current_instance = null
	gameplay_root.visible = false
	ui.visible = true
	var beat = beats[beat_index]
	if won:
		state = State.WON
		title_label.text = beat["title"] + " -- Complete"
		body_label.text = beat["after"]
		continue_button.text = "Continue"
	else:
		state = State.LOST
		title_label.text = beat["title"] + " -- You Did Not Make It"
		body_label.text = beat["lose_text"]
		continue_button.text = "Try Again"


func _show_outro() -> void:
	state = State.OUTRO
	ui.visible = true
	gameplay_root.visible = false
	title_label.text = "The Record Continues"
	body_label.text = "These stories were preserved so that we could believe -- not just know about them, but let them change us.\n\n\"...these things are written that we may believe...\"\n\nThank you for playing.\nMade for REL A 275 -- Book of Mormon Project."
	continue_button.text = "Restart"


func _on_continue_button_pressed() -> void:
	match state:
		State.INTRO:
			_show_before(beat_index)
		State.BEFORE:
			_start_gameplay(beat_index)
		State.WON:
			beat_index += 1
			if beat_index >= beats.size():
				_show_outro()
			else:
				_show_before(beat_index)
		State.LOST:
			_start_gameplay(beat_index)
		State.OUTRO:
			beat_index = 0
			_show_intro()
