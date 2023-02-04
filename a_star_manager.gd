extends RefCounted

class_name AStarManager

var a_star: AStarGrid2D

func initialize(map: TileMap):
	a_star = AStarGrid2D.new()
	var map_rect = map.get_used_rect()
	a_star.size = map_rect.size
	a_star.cell_size = map.tile_set.tile_size
	a_star.diagonal_mode = a_star.DIAGONAL_MODE_AT_LEAST_ONE_WALKABLE 
	a_star.update()
	
	# Base map.
	for i in map_rect.size[0]:
		for j in map_rect.size[1]:
			var tile_data = map.get_cell_tile_data(0, Vector2i(i, j))
			var solid = tile_data.get_custom_data("Solid") as bool
			if solid:
				a_star.set_point_solid(Vector2i(i, j))

	# Obstacles layer.
	for pos in map.get_used_cells(1):
		a_star.set_point_solid(pos)
		
func add(entities: Array):
	for e in entities:
		var entity = e as WorldEntity
		a_star.set_point_solid(e.get_id_position())
