extends RefCounted

class_name EnemyTurn

var map_manager: MapManager
var enemy_moves: Array
var aborted: bool

signal character_died(character: Character)

func _init(map: MapManager):
	map_manager = map.duplicate()
	aborted = false

func abort():
	aborted = true

func get_enemy_walkable_cells(enemy: Enemy) -> Array:
	return map_manager.get_walkable_cells(enemy.get_id_position(), enemy.move_points)

func calculate() -> bool:
	calculate_moves()
	if aborted:
		return false
	play_attacks()
	if aborted:
		return false
	return true

func calculate_moves():
	enemy_moves.clear()
	for enemy in map_manager.enemy_locs.values():
		if aborted:
			return
		if enemy.paralysis > 0:
			continue
		var move_options = get_enemy_walkable_cells(enemy)
		var result = top_move_option(enemy, move_options)
		var top_move = result[0]
		var targets = result[1]
		enemy_moves.append([enemy, top_move, targets])
		# This is just an overlay. Need to do the actual move later on the real map.
		map_manager.move_enemy(enemy.get_id_position(), top_move)

func play_attacks():
	execute_moves(map_manager)

func execute_moves(map: MapManager):
	var simulation = map.is_overlay
	if simulation:
		return
	for move in enemy_moves:
		# Move enemy.
		var enemy = move[0]
		var loc = move[1]
		var targets = move[2]
		await enemy.move(map, loc)
		# Find first target which is not dead yet.
		var chosen_target = null
		var target_character = null
		for target_distance in targets:
			var target = target_distance[0]
			if map.character_locs.has(target):
				chosen_target = target_distance
				target_character = map.character_locs[target]
				break
		# If no targets, continue.
		if chosen_target == null:
			continue
		if chosen_target[1] > enemy.attack_range():
			continue
		if not simulation:
			await enemy.draw_attack(target_character)
		# We found a target within range, attack and destroy character if it died.
		if target_character.apply_attack(enemy):
			if simulation:
				# TODO: Keep track of death characters
				map.remove_character(target_character.get_id_position())
			else:
				character_died.emit(target_character)

func _characters_with_distance(loc: Vector2i, character_locs: Array) -> Array:
	var ret = []
	for cloc in character_locs:
		ret.append([cloc, map_manager.distance(loc, cloc)])
	ret.sort_custom(func(a, b): return a[1] < b[1])
	return ret

func top_move_option(enemy: Enemy, move_options: Array):
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
