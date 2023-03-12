extends RefCounted

class_name TreasureLoader

const treasure_scene = preload("res://treasure.tscn")

static func create():
	return treasure_scene.instantiate() as Treasure

static func restore(save_state: TreasureSaveState) -> Treasure:
	var treasure = TreasureLoader.create()
	treasure.load_save_state(save_state)
	return treasure
