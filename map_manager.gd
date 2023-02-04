extends RefCounted

class_name MapManager

var a_star = AStarGrid2D.new()
var base_solid_locations: Dictionary
var map_rect: Rect2i
var tile_size: Vector2i
var character_locs: Dictionary
var enemy_locs: Dictionary

func initialize(map: TileMap):
	# Base map.
	map_rect = map.get_used_rect()
	tile_size = map.tile_set.tile_size
	for i in map_rect.size[0]:
		for j in map_rect.size[1]:
			var tile_data = map.get_cell_tile_data(0, Vector2i(i, j))
			var solid = tile_data.get_custom_data("Solid") as bool
			if solid:
				base_solid_locations[Vector2(i, j)] = true

	# Obstacles layer.
	for pos in map.get_used_cells(1):
		base_solid_locations[pos] = true

# Needs to be called after set_characters and set_enemies.
# Think about something better once it's clear how we'll use it.
func initialize_a_star():
	a_star.clear()
	a_star.size = map_rect.size
	a_star.cell_size = tile_size
	a_star.diagonal_mode = a_star.DIAGONAL_MODE_AT_LEAST_ONE_WALKABLE 
	a_star.update()
	for loc in base_solid_locations.keys():
		a_star.set_point_solid(loc)
	for loc in character_locs.keys():
		a_star.set_point_solid(loc)
	for loc in enemy_locs.keys():
		a_star.set_point_solid(loc)
	
func set_party(characters: Array):
	for c in characters:
		character_locs[c.get_id_position()] = c
	
func set_enemies(enemies: Array):
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

func get_path(from: Vector2i, to: Vector2i):
	return a_star.get_id_path(from, to)
	
func is_solid(pos: Vector2i, party: bool, enemies: bool):
	if base_solid_locations.has(pos):
		return true
	if party and character_locs.has(pos):
		return true
	if enemies and enemy_locs.has(pos):
		return true
	return false
	
func get_surrounding_cells(pos: Vector2i):
	var neighbors = []
	for i in [-1, 0, 1]:
		for j in [-1, 0, 1]:
			if i != 0 or j != 0:
				neighbors.push_back(Vector2i(pos[0]+i, pos[1]+j))
	return neighbors
