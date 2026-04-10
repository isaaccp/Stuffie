extends RefCounted

class_name EnemyInfoOverlay

var map_manager: MapManager
var enemies_node: Node
var enemy_move_area: TilesHighlight
var enemy_attack_area: TilesHighlight
var enemy_portrait: CharacterPortrait

var enemy_walkable_cache: Dictionary
var enemy_attackable_cache: Dictionary

func _init(map_manager: MapManager, enemies_node: Node, enemy_move_area: TilesHighlight, enemy_attack_area: TilesHighlight, enemy_portrait: CharacterPortrait):
	self.map_manager = map_manager
	self.enemies_node = enemies_node
	self.enemy_move_area = enemy_move_area
	self.enemy_attack_area = enemy_attack_area
	self.enemy_portrait = enemy_portrait

func offsets_within_distance(distance: int) -> Array[Vector2i]:
	var tiles: Array[Vector2i] = []
	var zero = Vector2i(0, 0)
	var i = -distance
	while i <= distance:
		var j = -distance
		while j <= distance:
			var tile = Vector2i(i, j)
			if map_manager.distance(zero, tile) <= distance:
				tiles.push_back(tile)
			j += 1
		i += 1
	return tiles

func get_attack_cells(enemy: Enemy, positions: Array) -> Array:
	var attack_positions = {}
	var offsets = offsets_within_distance(enemy.max_attack_distance())
	for pos in positions:
		var visible_tiles = map_manager.fov.get_fov(pos)
		for offset in offsets:
			var tile = pos + offset
			if map_manager.in_bounds(tile) and not map_manager.is_solid(tile, false, false, false) and tile in visible_tiles:
				attack_positions[tile] = true
	return attack_positions.keys()

func update_move_area(move_positions: Array, attack_positions: Array):
	enemy_move_area.set_tiles(move_positions)
	enemy_move_area.visible = true
	enemy_attack_area.set_tiles(attack_positions)
	enemy_attack_area.visible = true

func show_enemy_moves():
	var final_walkable_cells = Dictionary()
	var final_attackable_cells = Dictionary()
	for enemy in enemies_node.get_children():
		var walkable_cells = get_enemy_walkable_cells(enemy)
		for cell in walkable_cells:
			if cell not in final_attackable_cells:
				final_walkable_cells[cell] = true
		var attackable_cells = get_enemy_attackable_cells(enemy)
		for cell in attackable_cells:
			if not cell in final_attackable_cells:
				final_attackable_cells[cell] = 0
			final_attackable_cells[cell] += 1
			if final_walkable_cells.has(cell):
				final_walkable_cells.erase(cell)
	enemy_move_area.set_tiles(final_walkable_cells.keys())
	enemy_move_area.visible = true
	enemy_attack_area.set_labeled_tiles(final_attackable_cells)
	enemy_attack_area.visible = true

func get_enemy_walkable_cells(enemy: Enemy):
	if enemy_walkable_cache.has(enemy):
		return enemy_walkable_cache[enemy]
	var walkable_cells = map_manager.get_walkable_cells(enemy.get_id_position(), enemy.move_points)
	enemy_walkable_cache[enemy] = walkable_cells
	return walkable_cells

func get_enemy_attackable_cells(enemy: Enemy):
	if enemy_attackable_cache.has(enemy):
		return enemy_attackable_cache[enemy]
	var walkable_cells = get_enemy_walkable_cells(enemy)
	var attackable_cells = get_attack_cells(enemy, walkable_cells)
	enemy_attackable_cache[enemy] = attackable_cells
	return attackable_cells

func get_enemy_attackable_not_walkable_cells(enemy: Enemy):
	var walkable_cells = get_enemy_walkable_cells(enemy)
	var walkable = {}
	for cell in walkable_cells:
		walkable[cell] = true
	var attackable_cells = get_attack_cells(enemy, walkable_cells)
	var attackable_not_walkable = []
	for cell in attackable_cells:
		if not walkable.has(cell):
			attackable_not_walkable.push_back(cell)
	return attackable_not_walkable

func clear_cache():
	enemy_walkable_cache.clear()
	enemy_attackable_cache.clear()

func update_enemy_info(enemy: Enemy):
	if Input.is_action_pressed("ui_showenemymove"):
		return
	enemy_portrait.set_character(enemy)
	enemy_portrait.set_mode(CharacterPortrait.PortraitMode.COMBAT)
	enemy_portrait.show()
	var walkable_cells = get_enemy_walkable_cells(enemy)
	var attackable_cells = get_enemy_attackable_not_walkable_cells(enemy)
	update_move_area(walkable_cells, attackable_cells)

func clear_enemy_info():
	if Input.is_action_pressed("ui_showenemymove"):
		return
	enemy_move_area.visible = false
	enemy_attack_area.visible = false
