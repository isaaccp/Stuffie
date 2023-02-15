extends Node

class_name Highlight

var map: MapManager
var camera: Camera3D
var width = 1.0
var color = Color(1, 1, 1, 1)
var tiles: Array[Vector2i]
var clear_on_refresh = true

func _init(map_manager: MapManager, camera3d: Camera3D):
	super()
	map = map_manager
	camera = camera3d

func set_width(w: float):
	width = w
	refresh()
	
func set_color(c: Color, should_refresh=true):
	color = c
	if should_refresh:
		refresh()
	
func refresh():
	if clear_on_refresh:
		tiles.clear()
	_refresh_tiles()
	_draw_tiles()

func _refresh_tiles():
	# Should never be called.
	assert(false)
	
func _draw_tiles():
	for tile in get_children():
		tile.queue_free()
	for tile in tiles:
		var new_line = _draw_tile(tile)
		add_child(new_line)

func _add_unprojected_point(line: Line2D, world_pos: Vector3):
	var unprojected = camera.unproject_position(world_pos)
	line.add_point(unprojected)
	
func _draw_tile(pos: Vector2i) -> Line2D:
	var line = Line2D.new()
	line.default_color = color
	line.width = width
	var start = map.get_world_position_corner(pos)
	_add_unprojected_point(line, start)
	_add_unprojected_point(line, start + Vector3(map.cell_size.x, 0, 0))
	_add_unprojected_point(line, start + Vector3(map.cell_size.x, 0, map.cell_size.z))
	_add_unprojected_point(line, start + Vector3(0, 0, map.cell_size.z))
	_add_unprojected_point(line, start)
	return line
