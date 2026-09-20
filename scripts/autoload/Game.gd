extends Node

# "scene" is a plain res:// string path (not preload/load) so this file stays
# loadable even for levels whose scene doesn't exist yet during development.
# score_key == "" means pass/fail only; non-empty means arcade/survival scoring.
var levels: Array = [
	{
		"id": "stripling_warriors",
		"title": "1 -- Alma 56-57: The Stripling Warriors",
		"before": "Two thousand young men join Helaman's army during the wars with the Lamanites.\n\n\"...they were exceedingly valiant for courage, and also for strength and activity; but behold, this was not all -- they were men who were true at all times in whatsoever thing they were entrusted... they did not doubt.\"\n\nTheir strength was not skill in battle -- it was that they obeyed exactly, without hesitation, even when they could not see the whole plan.\n\nYou are one warrior in the line. Your commander will call out orders -- watch the field, and move to where you're needed before time runs out. Freeze, wander, or arrive late, and the formation breaks.",
		"scene": "res://scenes/MiniGameFormation.tscn",
		"after": "The stripling warriors survived because they trusted their leaders completely and obeyed exactly -- even without seeing the whole battlefield.\n\nWhere in your own life do you follow counsel exactly, even when you don't see the full picture? Where do you \"almost\" obey?",
		"lose_text": "A moment's hesitation broke the line. In the real battle, this was the difference between life and death.\n\nTry again -- exactness has no partial credit.",
		"score_key": "",
		"color": Color(0.78, 0.6, 0.18, 1),
		"monogram": "SW",
	},
	{
		"id": "flee_hide",
		"title": "2 -- Mosiah 18: Alma Flees the Guards of King Noah",
		"before": "Alma, once a priest of wicked King Noah, repented after hearing Abinadi's words. He taught the people in secret at the Waters of Mormon and organized a church there -- until Noah discovered them and sent soldiers to destroy them.\n\n\"...as many as did believe... went forth... and were baptized... and they were called the church of God...\" Then Noah's guards came, \"and Alma and the people of the Lord were apprised of their coming... therefore they took their tents and their families and departed into the wilderness.\"\n\nStay out of the guards' sight and reach the Waters of Mormon.",
		"scene": "res://scenes/MiniGameFleeHide.tscn",
		"after": "Alma's people didn't just believe quietly -- they made a public covenant, then paid a real price for it: exile, fear, running for their lives.\n\nWhat has a real commitment ever cost you? Was it worth it?",
		"lose_text": "The guards found you. For Alma's people, discovery meant death.\n\nTry again -- slip past unseen.",
		"score_key": "",
		"color": Color(0.22, 0.42, 0.55, 1),
		"monogram": "AF",
	},
]

var current_level_id: String = ""


func get_level(id: String) -> Dictionary:
	for lvl in levels:
		if lvl["id"] == id:
			return lvl
	return {}


func start_level(id: String) -> void:
	current_level_id = id
	Transition.goto_scene("res://scenes/GameShell.tscn")
