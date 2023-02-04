extends RefCounted

class_name EnemyTurn

var characters: Array[Character] 
var enemies: Array[Enemy]
var a_star_manager = AStarManager.new()

func initialize():
	pass
	
func prepare_turn(tile_map: TileMap, characters: Array, enemies: Array, map: TileMap):
	a_star_manager.initialize(tile_map)
	a_star_manager.add(characters)
	characters = characters
	enemies = enemies

func calculate_moves():
	for enemy in enemies:
		pass
	OS.delay_msec(1000)
