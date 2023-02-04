extends RefCounted

class_name EnemyTurn

var map_manager: MapManager

func initialize(map: MapManager):
	map_manager = map
	
func prepare_turn():
	pass

func calculate_moves():
	OS.delay_msec(1000)
