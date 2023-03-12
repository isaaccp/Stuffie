extends RefCounted

class_name TreasureLoader

const treasure_scene = preload("res://treasure.tscn")

static func create():
	return treasure_scene.instantiate() as Treasure

static func restore(state: TreasureSaveState) -> Treasure:
	var treasure = TreasureLoader.create()
	treasure.def = state.def
	treasure.turns_left = state.turns_left
	treasure.set_id_position(state.position)
	return treasure
