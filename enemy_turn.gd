extends RefCounted

class_name EnemyTurn

var calculation_map: MapManager
var execution_map: MapManager
var aborted: bool
var enemy_moves: Array
var damage_taken: Array
var animation_manager = AnimationManager.new()

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
	var characters = []
	# Save characters in case they die.
	for character in execution_map.character_locs.values():
		characters.push_back(character)
	play_attacks()
	if aborted:
		return false
	# Play mock characters begin_turn to account for e.g. bleed effects.
	for character in characters:
		character.begin_turn()
	if aborted:
		return false
	for character in characters:
		record_damage(character)
	return true

func calculate_moves():
	enemy_moves.clear()
	for enemy in calculation_map.enemy_locs.values():
		if aborted:
			return
		# Need to call begin_turn in case it affects movement, etc.
		enemy.begin_turn()
		if enemy.status_manager.get_status(StatusDef.Status.PARALYSIS) > 0:
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
	var card_player = CardPlayer.new(map, effects_node)
	for move in enemy_moves:
		if aborted:
			return
		# Move enemy.
		var enemy = map.enemy_locs[move[0]]
		# This may cause the death of an enemy due to bleed or other effects,
		# so check for that.
		enemy.begin_turn()
		if enemy.is_destroyed:
			continue
		for card in enemy.next_turn_cards:
			var unit_card = UnitCard.new(enemy, card)
			card_player.play_card_next_turn_effects(unit_card)
		enemy.clear_next_turn_cards()
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
			enemy.look_at(target_character.global_position)
			var chosen_card = null
			for unit_card in enemy.unit_cards:
				if unit_card.card.cost > enemy.action_points:
					continue
				if not unit_card.card.target_mode == Enum.TargetMode.ENEMY:
					continue
				if chosen_target[1] <= unit_card.card.target_distance:
					chosen_card = unit_card
					break
			if chosen_card:
				if not simulation:
					assert(effects_node)
				# TODO: Figure out direction for effects.
				await card_player.play_card(chosen_card, chosen_target[0], Vector2.UP)
				enemy.action_points -= chosen_card.card.cost
				if target_character.is_destroyed:
					if simulation:
						map.remove_character(target_character.get_id_position())
				continue
		# If we didn't find a target or didn't find a card that could be used,
		# try to play a self-card.
		var chosen_card = null
		for unit_card in enemy.unit_cards:
			if unit_card.card.cost > enemy.action_points:
					continue
			if unit_card.card.target_mode == Enum.TargetMode.SELF:
				chosen_card = unit_card
				break
		if chosen_card:
			await card_player.play_card(chosen_card, enemy.get_id_position(), Vector2.UP)
			enemy.action_points -= chosen_card.card.cost

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
