extends Node

# "scene" is a plain res:// string path so this file stays loadable even if a
# level's scene is mid-development. score_key == "" means pass/fail only.
var levels: Array = [
	{
		"id": "stripling_warriors",
		"name": "Hold the Line",
		"tagline": "2,000 young warriors. One order at a time.",
		"description": "You are one of Helaman's stripling warriors. Follow your commander's orders and hold your place in the line -- your brothers fight harder when you do.",
		"icon": "swords",
		"reference": "Alma 56-57",
		"scene": "res://scenes/MiniGameFormation.tscn",
		"before": "Two thousand young men join Helaman's army during the wars with the Lamanites.\n\n\"...they were exceedingly valiant for courage, and also for strength and activity; but behold, this was not all -- they were men who were true at all times in whatsoever thing they were entrusted... they did not doubt.\"\n\nTheir strength was not skill in battle -- it was that they obeyed exactly, without hesitation, even when they could not see the whole plan.\n\nYour captain carries the banner and marches the line forward. Stay beside him: inside the formation your brothers' shields cover you and the line fights harder. Step out alone and the enemy archers will find you.",
		"after": "The stripling warriors survived because they trusted their leaders completely and obeyed exactly -- even without seeing the whole battlefield.\n\nWhere in your own life do you follow counsel exactly, even when you don't see the full picture? Where do you \"almost\" obey?",
		"lose_text": "The line broke. In the real battle, this was the difference between life and death.\n\nTry again -- exactness has no partial credit.",
		"score_key": "",
		"color": Color(0.78, 0.6, 0.18, 1),
	},
	{
		"id": "flee_hide",
		"name": "Night Escape",
		"tagline": "Noah's guards are hunting you.",
		"description": "Alma fled King Noah's soldiers to keep a secret church alive. Slip through three camps of searching guards. If they spot you, they will chase -- and they will call for help.",
		"icon": "hood",
		"reference": "Mosiah 18",
		"scene": "res://scenes/MiniGameFleeHide.tscn",
		"before": "Alma, once a priest of wicked King Noah, repented after hearing Abinadi's words. He taught the people in secret at the Waters of Mormon and organized a church there -- until Noah discovered them and sent soldiers to destroy them.\n\n\"...Alma and the people of the Lord were apprised of their coming... therefore they took their tents and their families and departed into the wilderness.\"\n\nGuards patrol, stop, and sweep the dark. If one sees you he shouts -- and every guard nearby comes running. Break their line of sight to lose them. Reach the escape point in each camp.",
		"after": "Alma's people didn't just believe quietly -- they made a public covenant, then paid a real price for it: exile, fear, running for their lives.\n\nWhat has a real commitment ever cost you? Was it worth it?",
		"lose_text": "They caught you. For Alma's people, discovery meant death.\n\nTry again -- move when they look away.",
		"score_key": "night_escape",
		"color": Color(0.22, 0.42, 0.55, 1),
	},
	{
		"id": "nephis_bow",
		"name": "Broken Bow",
		"tagline": "One shot. One animal. A hungry camp.",
		"description": "Draw the bow and loose before your arm shakes. The arrow flies where you aim, but running game moves while it flies -- lead it. Hit the heart or it runs. Your family's strength drains while you hunt.",
		"icon": "bow",
		"reference": "1 Nephi 16",
		"scene": "res://scenes/MiniGameNephiBow.tscn",
		"before": "After years in the wilderness, Nephi's family depends on hunting for food. When his fine steel bow breaks, there is nothing to eat -- and his brothers, and even his father, begin to murmur against the Lord.\n\n\"...I, Nephi, did make out of wood a bow, and out of a straight stick, an arrow...\"\n\nHold the mouse to draw. Your aim drifts -- a wooden bow is not a steel one. Release to loose the arrow, and remember it falls as it flies. A clean hit to the heart brings food home; anything else and the animal bolts.",
		"after": "Nephi's family survived because he didn't wait for someone else to fix the problem -- he made a new bow, asked his father where to hunt, and went to work.\n\nWhen something you depend on breaks, is your first instinct to murmur, or to get to work and ask for guidance?",
		"lose_text": "The camp went hungry. Without food, the family could not go on.\n\nTry again -- steady the bow, and lead your shot.",
		"score_key": "broken_bow",
		"color": Color(0.62, 0.42, 0.18, 1),
	},
	{
		"id": "temple",
		"name": "Build the Temple",
		"tagline": "Build it with what you actually have.",
		"description": "Nephi built a temple in a new land without Solomon's riches. Gather timber and stone, haul it to the site, and raise it stage by stage.",
		"icon": "temple",
		"reference": "2 Nephi 5",
		"scene": "res://scenes/MiniGameTemple.tscn",
		"before": "After escaping his brothers, Nephi leads his people to a new land and becomes their king. Once they are settled, he turns immediately to building a temple.\n\n\"...I, Nephi, did build a temple; and I did construct it after the manner of the temple of Solomon, save it were not built of so many precious things... nevertheless... I did build it...\"\n\nGather timber and stone, then carry them to the build site.",
		"after": "Nephi didn't wait until he had everything Solomon had -- he built with what was actually available, because the temple mattered more than the excuse not to build it.\n\nWhat's something you've been waiting for 'ideal resources' to start, that you could actually begin now with what you have?",
		"lose_text": "",
		"score_key": "",
		"color": Color(0.5, 0.45, 0.3, 1),
	},
	{
		"id": "ammon_sling",
		"name": "Waters of Sebus",
		"tagline": "Count your stones. Then draw your sword.",
		"description": "Robbers are scattering the king's flock. You get a handful of sling stones each wave -- when they run out, it's you and a blade between them and the sheep.",
		"icon": "sling",
		"reference": "Alma 17-18",
		"scene": "res://scenes/MiniGameAmmon.tscn",
		"before": "Ammon, a Nephite prince, chooses to serve as a servant to a Lamanite king rather than seek glory. When robbers scatter King Lamoni's flocks at the waters of Sebus, the other servants weep, certain the king will have them killed.\n\n\"...Ammon... stood forth and began to cast stones at them with his sling... and they began to be astonished...\"\n\nYou carry a limited number of stones per wave. Sling them at range, then hold the line with your sword. Robbers will grab a sheep and drag it away -- strike them down to rescue it. If even one sheep is carried off, you have failed the king.",
		"after": "Ammon didn't fight for glory -- he fought because he had already chosen to serve, and the flock's safety was now his responsibility. His courage is what opened Lamoni's heart to hear him at all.\n\nWhere have you earned someone's trust through quiet service before you ever said a word about what you believe?",
		"lose_text": "A sheep was lost. The king's servants were slain for losing flocks -- Ammon's whole standing rested on losing none.

Try again -- stop every robber before he reaches the edge.",
		"score_key": "waters_of_sebus",
		"color": Color(0.3, 0.55, 0.4, 1),
	},
	{
		"id": "city_fortifications",
		"name": "Moroni's Line",
		"tagline": "Send out your army. Hold your fort.",
		"description": "Captain Moroni prepared before the attack came. Earn gold, train swordmen, spearmen, shieldmen, archers and a captain, upgrade your fort's crossbow -- and break the enemy line.",
		"icon": "tower",
		"reference": "Alma 48-50",
		"scene": "res://scenes/MiniGameFortify.tscn",
		"before": "Captain Moroni doesn't wait for the Lamanites to attack. He fortifies the Nephite cities in advance -- walls, towers, and places of resort -- because he believes preparation is an act of faith, not fear.\n\n\"...Moroni had been strengthening the armies of the Nephites... and erecting small forts... and throwing up banks of earth round about... and also building walls of stone...\"\n\nSpend gold to send out units and to strengthen your fort. Break the enemy fort before they break yours.",
		"after": "Moroni's preparation wasn't about fear of the Lamanites -- it was about taking his people's safety as seriously as he took his faith. He built what obedience required, before it was urgent.\n\nWhat's something you know you should prepare for, but keep putting off because nothing bad has happened yet?",
		"lose_text": "Your fort fell. Without enough preparation, courage in the moment wasn't enough.\n\nTry again -- build your line before it's tested.",
		"score_key": "moronis_line",
		"color": Color(0.45, 0.45, 0.5, 1),
	},
	{
		"id": "war_chapters",
		"name": "The War Chapters",
		"tagline": "Plan the ambush. Command the battle.",
		"description": "Top-down command of whole companies across three real battles: the ambush at Sidon, the walls of Noah, and the decoy at Mulek. Place your men, then order them into the fight.",
		"icon": "war",
		"reference": "Alma 43-52",
		"scene": "res://scenes/MiniGameWarChapters.tscn",
		"before": "The war chapters of Alma are not just stories of courage -- they are stories of preparation and wisdom. Moroni studied the land, hid his armies, fortified his cities, and used decoys, because he believed God expected him to use every means he had.

\"...Moroni... did not know... but... it was not the will of God that they should be destroyed... and he did prepare...\"

BEFORE each battle: pick a unit type below and click the lit ground to place companies. Men placed in trees are hidden and strike at double force.
DURING the battle: drag to select your men, right-click to send them somewhere.",
		"after": "Moroni's victories came from preparation, not luck -- knowing the ground, placing his people wisely, and trusting God while still doing everything in his power.

Where in your life are you waiting for deliverance while leaving your own preparation undone?",
		"lose_text": "The battle was lost. In the war chapters, the difference was almost always what was done before the fighting began.

Try again -- study the ground and place your men with purpose.",
		"score_key": "war_chapters",
		"color": Color(0.62, 0.3, 0.26, 1),
	},
	{
		"id": "great_deep",
		"name": "The Great Deep",
		"tagline": "Cross the ocean. Survive the storm.",
		"description": "Sail Nephi's ship to the promised land. When Laman and Lemuel bind Nephi, the compass dies and the helm barely answers -- until they repent and loose him.",
		"icon": "ship",
		"reference": "1 Nephi 17-18",
		"scene": "res://scenes/MiniGameShip.tscn",
		"before": "Nephi built a ship \"after the manner which the Lord had shown\" him, and his family put forth into the sea.

\"...we did put forth into the sea and were driven forth before the wind towards the promised land.\"

But on the water his brothers began to make merry and forget the Lord. When Nephi spoke to them, \"they did take me and bind me with cords... and the compass... did cease to work.\"

Steer around rocks and wreckage. When Nephi is bound, the Liahona stops, the storm rises, and the helm will barely answer you. Hold on until they loose him.",
		"after": "Bound and afflicted, Nephi wrote: \"I did look unto my God, and I did praise him all the day long; and I did not murmur against the Lord.\" The storm didn't end until the ones who rebelled repented -- and the compass only worked again in righteous hands.

When have other people's choices -- or your own -- made your life hard to steer? What helps you find your compass again?",
		"lose_text": "The ship was swallowed up by the deep.

Try again -- keep the ship afloat until Nephi is loosed and the storm is stilled.",
		"score_key": "great_deep",
		"color": Color(0.2, 0.45, 0.7, 1),
	},
]

var current_level_id: String = ""


func get_level(id: String) -> Dictionary:
	for lvl in levels:
		if lvl["id"] == id:
			return lvl
	return {}


func search(query: String) -> Array:
	var q := query.strip_edges().to_lower()
	if q == "":
		return levels
	var out: Array = []
	for lvl in levels:
		var hay: String = (lvl["name"] + " " + lvl["tagline"] + " " + lvl["description"] + " " + lvl["reference"]).to_lower()
		if hay.find(q) != -1:
			out.append(lvl)
	return out


func start_level(id: String) -> void:
	current_level_id = id
	Transition.goto_scene("res://scenes/GameShell.tscn")
