extends RefCounted

class_name MapManager

var a_star = AStarGrid2D.new()
var base_solid_locations: Dictionary
var map_rect: Rect2i
var cell_size: Vector3
var character_locs: Dictionary
var enemy_locs: Dictionary

func initialize(map: GridMap):
	cell_size = map.cell_size
	
	var block_items = Dictionary()
	for item in [
		["wall", [[-1, 0], [0, 0], [1, 0]]],
		["wallCorner", [[1, 0], [0, 0], [0, -1]]],
		["wallSplit", [[1, 0], [0, 0], [-1, 0], [0, -1]]],
		["wall_door", [[1, 0], [-1, 0]]],
	]:
		var item_name = item[0]
		var item_cells = item[1]
		var item_id = map.mesh_library.find_item_by_name(item_name)
		block_items[item_id] = item_cells
		
	# Base map.
	var min_x = 10000000
	var min_z = 10000000
	var max_x = -10000000
	var max_z = -10000000
	
	for cell in map.get_used_cells():
		if cell.x < min_x:
			min_x = cell.x
		if cell.z < min_z:
			min_z = cell.z
		if cell.x > max_x:
			max_x = cell.x
		if cell.z > max_z:
			max_z = cell.z
		var item = map.get_cell_item(cell) 
		if item in block_items:
			var basis = map.get_cell_item_basis(cell)
			var item_cells = block_items[item]
			for item_cell in item_cells:
				var cell3 = Vector3(item_cell[0], 0, item_cell[1])
				var xform_cell = cell3 * basis
				var map_tile = Vector2i(cell.x + xform_cell.x, cell.z + xform_cell.z)
				base_solid_locations[map_tile] = true
				
	assert(min_x == 0)
	assert(min_z == 0)
	
	map_rect = Rect2i(Vector2i(0, 0), Vector2(max_x, max_z))

# Unused, but keeping just in case.
func _mesh_size_from_aabb(aabb: AABB) -> Vector2i:
	var mesh_size: Vector2i
	mesh_size.x = int((aabb.size.x-0.1) / cell_size.x) + 1
	mesh_size.y = int((aabb.size.z-0.1) / cell_size.z) + 1
	return mesh_size
	
# Needs to be called after set_characters and set_enemies.
# Think about something better once it's clear how we'll use it.
func initialize_a_star():
	a_star.clear()
	a_star.size = map_rect.size
	a_star.cell_size = Vector2(cell_size.x, cell_size.z)
	a_star.diagonal_mode = a_star.DIAGONAL_MODE_AT_LEAST_ONE_WALKABLE 
	a_star.update()
	for loc in base_solid_locations.keys():
		a_star.set_point_solid(loc)
	for loc in character_locs.keys():
		a_star.set_point_solid(loc)
	for loc in enemy_locs.keys():
		a_star.set_point_solid(loc)
	
func set_party(characters: Array):
	character_locs.clear()
	for c in characters:
		character_locs[c.get_id_position()] = c
	
func set_enemies(enemies: Array):
	enemy_locs.clear()
	for e in enemies:
		enemy_locs[e.get_id_position()] = e
	
func move_character(from: Vector2i, to: Vector2i):
	var character = character_locs[from]
	character_locs.erase(from)
	character_locs[to] = character
	a_star.set_point_solid(from, false)
	a_star.set_point_solid(to)
	
func move_enemy(from: Vector2i, to: Vector2i):
	var enemy = enemy_locs[from]
	enemy_locs.erase(from)
	enemy_locs[to] = enemy
	a_star.set_point_solid(from, false)
	a_star.set_point_solid(to)

func remove_enemy(from: Vector2i):
	enemy_locs.erase(from)
	a_star.set_point_solid(from, false)

func remove_character(from: Vector2i):
	character_locs.erase(from)
	a_star.set_point_solid(from, false)
	
func get_path(from: Vector2i, to: Vector2i):
	if a_star.is_in_boundsv(to):
		return a_star.get_id_path(from, to)
	return []

func set_enemies_solid(solid=true):
	for loc in enemy_locs.keys():
		a_star.set_point_solid(loc, solid)
	
func get_enemy_path(from: Vector2i, to: Vector2i):
	# TODO: This could cause issues if there are concurrent calls 
	# to get_enemy_path() or to get_path(), the main options are either
	# adding a mutex or creating new copies of base map with/without enemies,
	# etc.
	set_enemies_solid(false)
	var path = a_star.get_id_path(from, to)
	set_enemies_solid(true)
	return path
	
func is_solid(pos: Vector2i, party: bool=true, enemies: bool=true):
	if base_solid_locations.has(pos):
		return true
	if party and character_locs.has(pos):
		return true
	if enemies and enemy_locs.has(pos):
		return true
	return false
	
func distance(from: Vector2i, to: Vector2i) -> float:
	var h_dist = abs(from[0] - to[0])
	var v_dist = abs(from[1] - to[1])
	var min_dist = min(h_dist, v_dist)
	var max_dist = max(h_dist, v_dist)
	return min_dist * 1.5 + (max_dist - min_dist)
	
func get_surrounding_cells(pos: Vector2i):
	var neighbors = []
	for i in [-1, 0, 1]:
		for j in [-1, 0, 1]:
			if i != 0 or j != 0:
				neighbors.push_back(Vector2i(pos[0]+i, pos[1]+j))
	return neighbors

func get_walkable_cells(from: Vector2i, move_points: int) -> Array:
	return _flood_fill(from, move_points)
	
func _flood_fill(cell: Vector2i, move_points: int) -> Array:
	# This is a dictionary of reachable tiles with their current cost.
	var reachable_cost: Dictionary
	# The way we implemented the flood fill here is by using a stack. In that stack, we store every
	# cell we want to apply the flood fill algorithm to.
	var stack := [[cell, 0]]
	# We loop over cells in the stack, popping one cell on every loop iteration.
	while not stack.is_empty():
		var current = stack.pop_back()
		var pos = current[0]
		var cost = current[1]
		# For each cell, we ensure that we can fill further.
		#
		# The conditions are:
		# 1. We didn't go past the grid's limits.
		# 2. We are within the `move_points`.
		# 3. We haven't already visited and filled this cell more effectively.
		if not map_rect.has_point(pos):
			continue
		if cost > move_points:
			continue
		if reachable_cost.has(pos):
			# We found a cheaper way to get here, so we update cost and we'll re-add to stack.
			if cost < reachable_cost[pos]:
				reachable_cost[pos] = cost
		else:
			reachable_cost[pos] = cost
		# We then look at the `current` cell's neighbors and, if they're not occupied and we haven't
		# visited them already, we add them to the stack for the next iteration.
		# This mechanism keeps the loop running until we found all cells the unit can walk.
		for neighbor in get_surrounding_cells(pos):
			if is_solid(neighbor):
				continue
			if neighbor in reachable_cost and reachable_cost[neighbor] <= cost:
				continue
			# This is where we extend the stack.
			stack.append([neighbor, cost + distance(pos, neighbor)])
	return reachable_cost.keys()

func get_world_position(pos: Vector2i) -> Vector3:
	return Vector3(
		pos[0] * cell_size.x + cell_size.x/2,
		1.5,
		pos[1] * cell_size.z + cell_size.z/2)

func get_world_position_corner(pos: Vector2i) -> Vector3:
	return Vector3(pos[0] * cell_size.x, 1.5, pos[1] * cell_size.z)

func in_bounds(pos: Vector2i):
	return map_rect.has_point(pos)
