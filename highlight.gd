extends Node

class_name Highlight

enum HighlightType {
	# Highlight of all tiles within a distance.
	AREA_DISTANCE,
}

var map: MapManager
var camera: Camera3D
var id_position: Vector2i
var highlight_type: HighlightType
var width = 1.0
var color = Color(1, 1, 1, 1)
var area_distance: int
var tiles: Array[Vector2i]

func initialize_area_distance_cursor(map_manager: MapManager, camera3d: Camera3D, pos: Vector2i, distance: int):
	map = map_manager
	camera = camera3d
	id_position = pos
	highlight_type = HighlightType.AREA_DISTANCE
	area_distance = distance
	refresh()
	
func set_width(width: float):
	width = width
	
func set_color(color: Color):
	color = color

func set_id_position(pos: Vector2i):
	id_position = pos
	refresh()
	
func refresh():
	tiles.clear()
	if highlight_type == HighlightType.AREA_DISTANCE:
		refresh_area_distance_tiles()
	draw_tiles()

func refresh_area_distance_tiles():
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
		
func draw_tiles():
	for tile in get_children():
		tile.queue_free()
	for tile in tiles:
		var new_line = draw_tile(tile)
		add_child(new_line)

func add_unprojected_point(line: Line2D, world_pos: Vector3):
	var unprojected = camera.unproject_position(world_pos)
	line.add_point(unprojected)
	
func draw_tile(pos: Vector2i) -> Line2D:
	var line = Line2D.new()
	line.default_color = color
	line.width = width
	var start = map.get_world_position_corner(pos)
	add_unprojected_point(line, start)
	add_unprojected_point(line, start + Vector3(map.cell_size.x, 0, 0))
	add_unprojected_point(line, start + Vector3(map.cell_size.x, 0, map.cell_size.z))
	add_unprojected_point(line, start + Vector3(0, 0, map.cell_size.z))
	add_unprojected_point(line, start)
	return line
