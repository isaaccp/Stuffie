extends Highlight

class_name AreaDistanceHighlight

var id_position: Vector2i
var area_distance: int
var los: bool

func _init(map_manager: MapManager, pos: Vector2i, distance: int, line_of_sight: bool):
	super(map_manager)
	id_position = pos
	area_distance = distance
	los = line_of_sight

func _refresh_tiles():
	var visible_tiles = {}
	if los:
		visible_tiles = map.fov.get_fov(id_position)
		print_debug("fov: %s, pos: %s, visible tiles: %s" % [map.fov, id_position, len(visible_tiles)])
	for i in range(-area_distance, area_distance+1):
		for j in range(-area_distance, area_distance+1):
			var offset = Vector2i(i, j)
			var new_pos = id_position + offset
			if not map.in_bounds(new_pos):
				continue
			if map.is_solid(new_pos, false, false, false):
				continue
			if map.distance(id_position, new_pos) > area_distance:
				continue
			if los and not new_pos in visible_tiles:
				continue
			tiles.push_back(new_pos)
