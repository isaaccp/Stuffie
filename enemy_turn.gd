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
		var result = top_move_option(enemy, move_options)
		var top_move = result[0]
		var targets = result[1]
		enemy_moves.append([enemy, top_move, targets])
		# Need to do this now so we calculate moves correctly.
		# I guess it would be neat if this was an "overlay" over the real state
		# and then we would update all the "real" stuff at the same time, but
		# as long as we update the nodes right after this it should be fine.
		map_manager.move_enemy(enemy.get_id_position(), top_move)

func _characters_with_distance(loc: Vector2i, character_locs: Array) -> Array:
	var ret = []
	for cloc in character_locs:
		ret.append([cloc, map_manager.distance(loc, cloc)])
	ret.sort_custom(func(a, b): return a[1] < b[1])
	return ret

func top_move_option(enemy: Enemy, move_options: Array):
	# For now, let's just say the closer to a character the better.
	var character_locs = map_manager.character_locs.keys()
	var best_move = null
	var best_target = null
	var max_distance_sum = 0
	for move in move_options:
		var reachable_targets = 0
		var distance_sum = 0
		for loc in character_locs:
			var distance = map_manager.distance(move, loc)
			if distance <= enemy.attack_range():
				reachable_targets += 1
			distance_sum += distance
		if reachable_targets:
			if distance_sum > max_distance_sum:
				max_distance_sum = distance_sum
				best_move = move
	if best_move:
		return [best_move, _characters_with_distance(best_move, character_locs)]
	# If there are no tiles in which we can reach the character to attack,
	# just get as close as possible.
	var min_distance = 100000
	for move in move_options:
		for loc in character_locs:
			var distance = map_manager.distance(move, loc)
			if distance < min_distance:
				min_distance = distance
				best_move = move
	# For selected move, return characters sorted by distance.
	# We'll attack closest, but if they die, continue to next one.
	return [best_move, _characters_with_distance(best_move, character_locs)]
