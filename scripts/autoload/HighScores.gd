extends Node

const SAVE_PATH := "user://highscores.cfg"

var _scores: Dictionary = {}


func _ready() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) == OK:
		for key in cfg.get_section_keys("scores"):
			_scores[key] = cfg.get_value("scores", key, 0)


func get_best(key: String) -> int:
	return _scores.get(key, 0)


func submit_score(key: String, score: int) -> bool:
	if score > get_best(key):
		_scores[key] = score
		_save()
		return true
	return false


func _save() -> void:
	var cfg := ConfigFile.new()
	for key in _scores:
		cfg.set_value("scores", key, _scores[key])
	cfg.save(SAVE_PATH)
