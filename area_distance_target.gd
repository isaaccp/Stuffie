extends Highlight

class_name AreaDistanceHighlight

var id_position: Vector2i
var area_distance: int

func _init(map_manager: MapManager, pos: Vector2i, distance: int):
	super(map_manager)
	id_position = pos
	area_distance = distance

func _refresh_tiles():
	var i = -area_distance
	while i <= area_distance:
		var j = -area_distance
		while j <= area_distance:
			var offset = Vector2i(i, j)
			var new_pos = id_position + offset
			if map.in_bounds(new_pos) and not map.is_solid(new_pos, false, false):
				if map.distance(id_position, new_pos) <= area_distance:
					tiles.push_back(new_pos)
			j += 1
		i += 1
