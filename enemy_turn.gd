extends RefCounted

class_name EnemyTurn

var calculation_map: MapManager
var execution_map: MapManager
var aborted: bool
var enemy_moves: Array
var damage_taken: Array
var animation_manager = AnimationManager.new()

signal character_died(character: Character)

func _init(map: MapManager):
	# Need to clone entities to apply begin_turn() and also fov.
	calculation_map = map.clone(true, true)
	# Mock entities, but no need to clone fov.
	execution_map = map.clone(true)
	aborted = false

func abort():
	aborted = true

func get_enemy_walkable_cells(enemy: Enemy) -> Array:
	return calculation_map.get_walkable_cells(enemy.get_id_position(), enemy.move_points)

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
	for enemy in calculation_map.enemy_locs.values():
		if aborted:
			return
		# Need to call begin_turn in case it affects movement, etc.
		enemy.begin_turn()
		if enemy.paralysis > 0:
			continue
		var move_options = get_enemy_walkable_cells(enemy)
		var result = top_move_option(enemy, move_options)
		var top_move = result[0]
		var targets = result[1]
		enemy_moves.append([enemy.get_id_position(), top_move, targets])
		# This is just an overlay. Need to do the actual move later on the real map.
		calculation_map.move_enemy(enemy.get_id_position(), top_move)

func play_attacks():
	execute_moves(execution_map, null)

func execute_moves(map: MapManager, effects_node: Node):
	var simulation = map.is_overlay
	for move in enemy_moves:
		if aborted:
			return
		# Move enemy.
		var enemy = map.enemy_locs[move[0]]
		enemy.begin_turn()
		var enemy_pos = enemy.get_id_position()
		var loc = move[1]
		var targets = move[2]
		if enemy_pos != loc:
			var curve = map.curve_from_path(map.get_enemy_path(enemy_pos, loc))
			await enemy.move(curve, loc)
			map.move_enemy(enemy_pos, loc)
		# Find first target which is not dead yet.
		var chosen_target = null
		var target_character = null
		for target_distance in targets:
			var target = target_distance[0]
			if map.character_locs.has(target):
				chosen_target = target_distance
				target_character = map.character_locs[target]
				break
		# If there is a target, try to find an attack.
		if chosen_target != null:
			var chosen_card = null
			for unit_card in enemy.unit_cards:
				if not unit_card.card.target_mode == Enum.TargetMode.ENEMY:
					continue
				if chosen_target[1] <= unit_card.card.target_distance:
					chosen_card = unit_card
					break
			if chosen_card:
				if not simulation:
					assert(effects_node)
					var target_tile = chosen_target[0]
					# TODO: This doesn't matter because as of now we don't support AoE,
					# but if/when we do we need to fix it.
					var affected_tiles = chosen_card.card.effect_area(Vector2.UP)
					var effect_time = 0
					for tile_offset in affected_tiles:
						var tile = target_tile + tile_offset
						var effect = animation_manager.get_effect(chosen_card.card.target_animation)
						if effect != null:
							effect.origin = enemy.global_position
							effect.target = map.get_world_position(tile)
							effects_node.add_child(effect)
							effect_time = effect.apply_effect_time()
					if effects_node.get_child_count() != 0:
						await effects_node.get_tree().create_timer(effect_time, false).timeout
				# We found a target within range, attack and destroy character if it died.
				if chosen_card.apply_to_enemy(target_character):
					if simulation:
						record_damage(target_character)
						map.remove_character(target_character.get_id_position())
					else:
						character_died.emit(target_character)
				if not simulation:
					for effect in effects_node.get_children():
						await effect.finished()
					for effect in effects_node.get_children():
						effect.queue_free()
				continue
		# If we didn't find a target or didn't find a card that could be used,
		# try to play a self-card.
		var chosen_card = null
		for unit_card in enemy.unit_cards:
			if unit_card.card.target_mode == Enum.TargetMode.SELF:
				chosen_card = unit_card
				break
		if chosen_card:
			await chosen_card.apply_self()
	if simulation:
		for loc in map.character_locs:
			record_damage(map.character_locs[loc])

func record_damage(character: Character):
	damage_taken.push_back([character.get_id_position(), character.snapshot.hit_points - character.hit_points])

func _characters_with_distance(loc: Vector2i, character_locs: Array) -> Array:
	var ret = []
	for cloc in character_locs:
		ret.append([cloc, calculation_map.distance(loc, cloc)])
	ret.sort_custom(func(a, b): return a[1] < b[1])
	return ret

func top_move_option(enemy: Enemy, move_options: Array):
	var character_locs = calculation_map.character_locs.keys()
	var best_move = null
	var best_targets = null
	var max_distance_sum = 0
	for unit_card in enemy.unit_cards:
		if not unit_card.card.is_attack():
			continue
		for move in move_options:
			var reachable_targets = 0
			var distance_sum = 0
			var targets = []
			for loc in character_locs:
				var distance = calculation_map.distance(move, loc)
				# To support AoE attacks we would need to change this.
				if distance <= unit_card.card.target_distance:
					var visible_tiles = calculation_map.fov.get_fov(move)
					if loc in visible_tiles:
						reachable_targets += 1
						targets.push_back(loc)
				distance_sum += distance
			if reachable_targets:
				if distance_sum > max_distance_sum:
					max_distance_sum = distance_sum
					best_move = move
					best_targets = targets
		# Break as soon as we find a card with reachable targets.
		if best_move:
			break
	if best_move:
		# For selected move, return characters sorted by distance.
		# We'll attack closest, but if they die, continue to next one.
		return [best_move, _characters_with_distance(best_move, best_targets)]
	# TODO: As of now, enemies can get stuck on areas that are close
	# to the player but can't possibly reach them. Should fix that at some point.

	# If there are no tiles in which we can reach the character to attack,
	# just get as close as possible.
	var min_distance = 100000
	for move in move_options:
		for loc in character_locs:
			var distance = calculation_map.distance(move, loc)
			if distance < min_distance:
				min_distance = distance
				best_move = move
	return [best_move, []]
