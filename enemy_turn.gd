extends RefCounted

class_name EnemyTurn

var map_manager: MapManager

func initialize(map: MapManager):
	map_manager = map
	
func get_walkable_cells(enemy: Enemy) -> Array:
	return _flood_fill(enemy.get_id_position(), enemy.move_points)

# Duplicated from Gameplay. Figure out what to do with it.
func distance(from: Vector2i, to: Vector2i) -> float:
	var h_dist = abs(from[0] - to[0])
	var v_dist = abs(from[1] - to[1])
	var min_dist = min(h_dist, v_dist)
	var max_dist = max(h_dist, v_dist)
	return min_dist * 1.5 + (max_dist - min_dist)
	
func is_occupied(tile: Vector2i):
	# Process this info to not have to access tile data all the time.
	# Possibly change a_star_manager into some more generic tile_map
	# wrapper that can be used for both a star and this stuff.
	return map_manager.is_solid(tile, true, true)
	
func _flood_fill(cell: Vector2i, max_move: int) -> Array:
	var used_rect = map_manager.map_rect
	# This is the array of walkable cells the algorithm outputs.
	var array := []
	# The way we implemented the flood fill here is by using a stack. In that stack, we store every
	# cell we want to apply the flood fill algorithm to.
	var stack := [cell]
	# We loop over cells in the stack, popping one cell on every loop iteration.
	while not stack.is_empty():
		var current = stack.pop_back()

		# For each cell, we ensure that we can fill further.
		#
		# The conditions are:
		# 1. We didn't go past the grid's limits.
		# 2. We haven't already visited and filled this cell
		# 3. We are within the `max_distance`, a number of cells.
		if not used_rect.has_point(current):
			continue
		if current in array:
			continue

		# This is where we check for the distance between the starting `cell` and the `current` one.
		var distance = distance(current, cell)
		if distance > max_move:
			continue

		# If we meet all the conditions, we "fill" the `current` cell.
		array.append(current)
		# We then look at the `current` cell's neighbors and, if they're not occupied and we haven't
		# visited them already, we add them to the stack for the next iteration.
		# This mechanism keeps the loop running until we found all cells the unit can walk.
		for neighbor in map_manager.get_surrounding_cells(current):
			# This is an "optimization". It does the same thing as our `if current in array:` above
			# but repeating it here with the neighbors skips some instructions.
			if is_occupied(neighbor):
				continue
			if neighbor in array:
				continue

			# This is where we extend the stack.
			stack.append(neighbor)
	return array
	
func prepare_turn():
	pass

func calculate_moves():
	OS.delay_msec(1000)
