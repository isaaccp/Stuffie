extends RefCounted

class_name CardPlayer

var map: MapManager
var effects_node: Node
var animation_manager = AnimationManager.new()

# Fired if the played card is an attack card.
signal attacked
# Fired once for each enemy killed by this card.
signal enemy_killed(unit: Unit)

func _init(map_manager: MapManager, effects_node: Node):
	self.map = map_manager
	self.effects_node = effects_node

func play_card(unit_card: UnitCard, target_tile: Vector2i, direction: Vector2):
	await unit_card.apply_self_effects()
	if unit_card.card.target_mode == Enum.TargetMode.SELF:
		# Implement animation for SELF cards.
		await unit_card.apply_self()
	elif unit_card.card.target_mode in [Enum.TargetMode.ENEMY, Enum.TargetMode.AREA]:
		var affected_tiles = unit_card.card.effect_area(direction)
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
		for tile_offset in affected_tiles:
			var tile = target_tile + tile_offset
			if map.enemy_locs.has(tile):
				var enemy = map.enemy_locs[tile]
				await unit_card.apply_to_enemy(enemy)
				if enemy.destroyed:
					enemy_killed.emit(enemy)
	elif unit_card.card.target_mode in [Enum.TargetMode.ALLY, Enum.TargetMode.SELF_ALLY]:
		var effect_time = 0
		var effect = animation_manager.get_effect(unit_card.card.target_animation)
		if effect != null:
			effect.origin = unit_card.unit.global_position
			effect.target = map.get_world_position(target_tile)
			effects_node.add_child(effect)
			effect_time = effect.apply_effect_time()
		if effects_node.get_child_count() != 0:
			await effects_node.get_tree().create_timer(effect_time, false).timeout
		var target_character = map.character_locs[target_tile]
		await unit_card.apply_to_ally(target_character)
	for effect in effects_node.get_children():
		await effect.finished()
	for effect in effects_node.get_children():
		effect.queue_free()
	await unit_card.apply_after_effects()
