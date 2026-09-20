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
	{
		"id": "nephis_bow",
		"title": "3 -- 1 Nephi 16: Nephi's Bow",
		"before": "After years in the wilderness, Nephi's family depends on hunting for food. When his fine steel bow breaks, there is nothing to eat -- and his brothers, and even his father, begin to murmur against the Lord.\n\n\"...I, Nephi, did make out of wood a bow, and out of a straight stick, an arrow...\" Nephi doesn't just complain -- he builds a new bow, asks his father where to hunt, and gets to work.\n\nHunt carefully. Some animals are easy targets; others take a steady hand -- and a quick one.",
		"scene": "res://scenes/MiniGameNephiBow.tscn",
		"after": "Nephi's family survived because he didn't wait for someone else to fix the problem -- he acted, then sought the Lord's direction.\n\nWhen something you depend on breaks, is your first instinct to murmur, or to get to work and ask for guidance?",
		"lose_text": "",
		"score_key": "nephis_bow",
		"color": Color(0.62, 0.42, 0.18, 1),
		"monogram": "NB",
	},
	{
		"id": "temple",
		"title": "4 -- 2 Nephi 5: Building the Temple",
		"before": "After escaping his brothers, Nephi leads his people to a new land and becomes their king. Once they are settled, he turns immediately to building a temple.\n\n\"...I, Nephi, did build a temple; and I did construct it after the manner of the temple of Solomon, save it were not built of so many precious things... nevertheless... I did build it...\"\n\nGather timber and stone, then carry them to the build site.",
		"scene": "res://scenes/MiniGameTemple.tscn",
		"after": "Nephi didn't wait until he had everything Solomon had -- he built with what was actually available, because the temple mattered more than the excuse not to build it.\n\nWhat's something you've been waiting for 'ideal resources' to start, that you could actually begin now with what you have?",
		"lose_text": "",
		"score_key": "",
		"color": Color(0.5, 0.45, 0.3, 1),
		"monogram": "BT",
	},
	{
		"id": "ammon_sling",
		"title": "5 -- Alma 17-18: Ammon's Sling and Sword",
		"before": "Ammon, a Nephite prince, chooses to serve as a servant to a Lamanite king rather than seek glory. When robbers scatter King Lamoni's flocks at the waters of Sebus, the other servants weep, certain the king will have them killed.\n\n\"...Ammon said unto them: ...I will show forth my power unto you... in this thing, that ye may hereafter believe... that I may win the hearts of these my fellow-servants...\" He drives off the attackers with his sling and his sword.\n\nDefend the flock. Sling from range, swing up close.",
		"scene": "res://scenes/MiniGameAmmon.tscn",
		"after": "Ammon didn't fight for glory -- he fought because he had already chosen to serve, and the flock's safety was now his responsibility. His courage is what opened Lamoni's heart to hear him at all.\n\nWhere have you earned someone's trust through quiet service before you ever said a word about what you believe?",
		"lose_text": "The attackers finally broke through. Even Ammon couldn't defend the flock alone forever -- but he held far longer than anyone expected.\n\nTry again and see how long you can hold the waters of Sebus.",
		"score_key": "ammon_sling",
		"color": Color(0.3, 0.55, 0.4, 1),
		"monogram": "AS",
	},
	{
		"id": "city_fortifications",
		"title": "6 -- Alma 48-50: City Fortifications",
		"before": "Captain Moroni doesn't wait for the Lamanites to attack. He fortifies the Nephite cities in advance -- walls, towers, and places of resort -- because he believes preparation is an act of faith, not fear.\n\n\"...Moroni had been strengthening the armies of the Nephites... and erecting small forts... and throwing up banks of earth round about... and also building walls of stone...\"\n\nBuild your defenses before each wave arrives.",
		"scene": "res://scenes/MiniGameFortify.tscn",
		"after": "Moroni's preparation wasn't about fear of the Lamanites -- it was about taking his people's safety as seriously as he took his faith. He built what obedience required, before it was urgent.\n\nWhat's something you know you should prepare for, but keep putting off because nothing bad has happened yet?",
		"lose_text": "The city fell. Without enough preparation, even courage in the moment wasn't enough.\n\nTry again -- build first, defend second.",
		"score_key": "city_fortifications",
		"color": Color(0.45, 0.45, 0.5, 1),
		"monogram": "CF",
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
