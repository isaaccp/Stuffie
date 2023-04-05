extends RefCounted

class_name CardPlayer

var map: MapManager
# Can be null for no effects (for simulation).
var effects_node: Node
var animation_manager: AnimationManager

# Fired if the played card is an attack card.
signal attacked
# Fired once for each enemy killed by this card.
signal enemy_killed(unit: Unit)

func _init(map_manager: MapManager, effects_node: Node):
	self.map = map_manager
	self.effects_node = effects_node
	if effects_node:
		animation_manager = AnimationManager.new()

func get_ally_map(unit: Unit):
	if unit is Character:
		return map.character_locs
	else:
		return map.enemy_locs

func get_enemy_map(unit: Unit):
	if unit is Character:
		return map.enemy_locs
	else:
		return map.character_locs

func play_card(unit_card: UnitCard, target_tile: Vector2i, direction: Vector2):
	if unit_card.card.target_mode == Enum.TargetMode.SELF:
		target_tile = unit_card.unit.get_id_position()

	await unit_card.apply_self_effects()

	var affected_tiles = unit_card.card.effect_area(direction)
	# Start effects.
	if effects_node != null:
		var effect_time = 0
		for tile_offset in affected_tiles:
			var tile = target_tile + tile_offset
			var effect = animation_manager.get_effect(unit_card.card.target_animation)
			if effect != null:
				effect.origin = unit_card.unit.global_position
				effect.target = map.get_world_position(tile)
				effects_node.add_child(effect)
				effect_time = effect.apply_effect_time()
		if effects_node.get_child_count() != 0:
			await effects_node.get_tree().create_timer(effect_time, false).timeout
	if unit_card.card.target_mode == Enum.TargetMode.SELF:
		await unit_card.apply_self()
	# As of now, area effects only work with enemies, should support
	# friendly area effects too.
	elif unit_card.card.target_mode in [Enum.TargetMode.ENEMY, Enum.TargetMode.AREA]:
		var enemies = []
		for tile_offset in affected_tiles:
			var tile = target_tile + tile_offset
			var enemy_map = get_enemy_map(unit_card.unit)
			if enemy_map.has(tile):
				var enemy = enemy_map[tile]
				enemies.push_back(enemy)
		if effects_node:
			for enemy in enemies:
				var effect = animation_manager.get_effect(unit_card.card.on_damage_animation)
				if effect != null:
					effect.origin = enemy.global_position
					effect.target = enemy.global_position
					effects_node.add_child(effect)
		for enemy in enemies:
			await unit_card.apply_to_enemy(enemy)
			if enemy.is_destroyed:
				enemy_killed.emit(enemy)
	elif unit_card.card.target_mode in [Enum.TargetMode.ALLY, Enum.TargetMode.SELF_ALLY]:
		var ally_map = get_ally_map(unit_card.unit)
		var target_unit = ally_map[target_tile]
		await unit_card.apply_to_ally(target_unit)
	await unit_card.apply_after_effects()
	# Clean up effects.
	if effects_node != null:
		for effect in effects_node.get_children():
			await effect.finished()
		for effect in effects_node.get_children():
			effect.queue_free()

	if unit_card.card.on_next_turn_effects != null:
		unit_card.unit.add_next_turn_card(unit_card.card)

func play_card_next_turn_effects(unit_card: UnitCard):
	await unit_card.apply_next_turn_effects()
