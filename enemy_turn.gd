extends RefCounted

class_name EnemyTurn

var map_manager: MapManager
var enemy_moves: Array

func initialize(map: MapManager):
	map_manager = map

func get_enemy_walkable_cells(enemy: Enemy) -> Array:
	return map_manager.get_walkable_cells(enemy.get_id_position(), enemy.move_points)
	
func calculate_moves():
	enemy_moves.clear()
	for enemy in map_manager.enemy_locs.values():
		var move_options = get_enemy_walkable_cells(enemy)
		var top_move = top_move_option(enemy, move_options)
		enemy_moves.append([enemy, top_move])
		# Need to this now so we calculate moves correctly.
		# I guess it would be neat if this was an "overlay" over the real state
		# and then we would update all the "real" stuff at the same time, but
		# as long as we update the nodes right after this it should be fine.
		map_manager.move_enemy(enemy.get_id_position(), top_move)

func top_move_option(enemy: Enemy, move_options: Array):
	# For now, let's just say the closer to a character the better.
	var character_locs = map_manager.character_locs.keys()
	var best_move = null
	var min_distance = 100000
	for move in move_options:
		for loc in character_locs:
			var distance = map_manager.distance(move, loc)
			if distance < min_distance:
				min_distance = distance
				best_move = move
	return best_move
