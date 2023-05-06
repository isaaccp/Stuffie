extends RefCounted

class_name MapManager

var a_star = AStarGrid2D.new()
var fov: FieldOfView
var base_solid_locations: Dictionary
var temp_not_solid_locations: Dictionary
var base_view_blocking_locations: Dictionary
var map_rect: Rect2i
var cell_size: Vector3
var character_locs: Dictionary
var enemy_locs: Dictionary
var treasure_locs: Dictionary
var door_locs: Dictionary
var is_overlay = false

var door_scene = preload("res://door.tscn")
var cage_door_scene = preload("res://cage_door.tscn")

func initialize(stage: Stage, doors_node: Node):
	cell_size = stage.gridmap.cell_size
	map_rect = stage.rect

	for loc in stage.solid_tiles:
		base_solid_locations[loc] = true

	for loc in stage.view_blocking_tiles:
		base_view_blocking_locations[loc] = true

	for door_def in stage.doors:
		var door: Door
		if door_def.wall_type == door_def.WallType.NORMAL:
			door = door_scene.instantiate() as Door
		else:
			door = cage_door_scene.instantiate() as Door
		var gridmap_pos = Vector3i(door_def.pos.x, 1, door_def.pos.y)
		# Need to set state before adding child as the door will 'open'
		# on _ready if state is OPEN.
		door.state = door_def.state
		door_locs[door_def.pos] = door
		doors_node.add_child(door)
		door.global_position = get_world_position(door_def.pos)
		door.basis = stage.gridmap.get_cell_item_basis(gridmap_pos)

	initialize_fov()

func initialize_fov():
	fov = FieldOfView.new(map_rect.size, base_view_blocking_locations, door_locs)

func clone(mock_entities=false, clone_fov=false):
	var new = MapManager.new()
	new.is_overlay = true
	# Immutable, okay to have refs.
	new.map_rect = map_rect
	new.cell_size = cell_size
	# Mutable, need a copy.
	new.a_star = duplicate_a_star()
	new.base_solid_locations = base_solid_locations.duplicate()
	new.temp_not_solid_locations = temp_not_solid_locations.duplicate()
	new.base_view_blocking_locations = base_view_blocking_locations.duplicate()
	new.treasure_locs = treasure_locs.duplicate()
	new.door_locs = door_locs.duplicate()
	# This depends on map-rect, base_view_blocking_locations and door_locs.
	if clone_fov:
		new.initialize_fov()

	if mock_entities:
		for loc in character_locs:
			new.character_locs[loc] = character_locs[loc].mock()
		for loc in enemy_locs:
			new.enemy_locs[loc] = enemy_locs[loc].mock()
	else:
		new.character_locs = character_locs.duplicate()
		new.enemy_locs = enemy_locs.duplicate()
	return new

func duplicate_a_star():
	var new = AStarGrid2D.new()
	var old = a_star
	new.size = old.size
	new.cell_size = old.cell_size
	new.diagonal_mode = old.diagonal_mode
	new.update()
	for i in new.size.x:
		for j in new.size.y:
			var loc = Vector2i(i, j)
			if old.is_point_solid(loc):
				new.set_point_solid(loc)
	return new

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
	for loc in door_locs.keys():
		if door_locs[loc].solid():
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
	if from == to:
		return
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

func open_door(pos: Vector2i):
	assert(pos in door_locs)
	door_locs[pos].open()
	fov.set_solid(pos, false)
	a_star.set_point_solid(pos, false)

func close_door(pos: Vector2i):
	assert(pos in door_locs)
	door_locs[pos].close()
	fov.set_solid(pos)
	a_star.set_point_solid(pos)

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

# TODO: Convert the arguments here into a mask.
func is_solid(pos: Vector2i, party: bool=true, enemies: bool=true, treasures: bool=true):
	if temp_not_solid_locations.has(pos):
		return false
	if base_solid_locations.has(pos):
		return true
	if door_locs.has(pos):
		if door_locs[pos].solid():
			return true
	if party and character_locs.has(pos):
		return true
	if enemies and enemy_locs.has(pos):
		return true
	if treasures and treasure_locs.has(pos):
		return true
	return false

func distance(from: Vector2i, to: Vector2i) -> float:
	var h_dist = abs(from[0] - to[0])
	var v_dist = abs(from[1] - to[1])
	var min_dist = min(h_dist, v_dist)
	var max_dist = max(h_dist, v_dist)
	return min_dist * 1.5 + (max_dist - min_dist)

func move_cost(from: Vector2i, to: Vector2i):
	return distance(from, to) * 2

func get_accessible_surrounding_cells(pos: Vector2i):
	var neighbors = []
	for i in [-1, 0, 1]:
		for j in [-1, 0, 1]:
			if i == 0 and j == 0:
				continue
			var new_pos = Vector2i(pos[0]+i, pos[1]+j)
			if is_solid(new_pos):
				continue
			if i != 0 and j != 0:
				# Diagonal, check if either of the sides is accessible.
				var side1 = Vector2i(pos[0]+i, pos[1])
				var side2 = Vector2i(pos[0], pos[1]+j)
				if is_solid(side1) and is_solid(side2):
					continue
			neighbors.push_back(new_pos)
	return neighbors

func get_walkable_cells(from: Vector2i, move_points: int, ignore_tiles=[]) -> Array:
	for tile in ignore_tiles:
		temp_not_solid_locations[tile] = true
	var cells = _flood_fill(from, move_points)
	for tile in ignore_tiles:
		temp_not_solid_locations.erase(tile)
	return cells

func curve_from_path(path: PackedVector2Array) -> Curve3D:
	var curve = Curve3D.new()
	for pos in path:
		var world_pos = get_world_position(pos)
		curve.add_point(world_pos)
	return curve

func _flood_fill(cell: Vector2i, move_points: int) -> Array:
	# This is a dictionary of reachable tiles with their current cost.
	var reachable_cost = {}
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
		for neighbor in get_accessible_surrounding_cells(pos):
			if neighbor in reachable_cost and reachable_cost[neighbor] <= cost:
				continue
			# This is where we extend the stack.
			stack.append([neighbor, cost + move_cost(pos, neighbor)])
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

func get_random_empty_tile():
	var choices = []
	for i in map_rect.size.x:
		for j in map_rect.size.y:
			var pos = Vector2i(i, j)
			if not is_solid(pos):
				choices.push_back(pos)

	return choices[randi() % choices.size()]

func add_treasure(treasure: Treasure):
	assert(not is_solid(treasure.get_id_position()))
	# Do not update A* as we want the character to be able to walk into it.
	treasure_locs[treasure.get_id_position()] = treasure

func remove_treasure(pos: Vector2i):
	var treasure = treasure_locs[pos]
	treasure_locs.erase(pos)
	treasure.queue_free()
