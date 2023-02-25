extends Node

class_name Highlight

var map: MapManager
var width = 1.0
var color = Color(1, 1, 1, 1)
var tiles: Array[Vector2i]
var clear_on_refresh = true
var highlight3d: Highlight3D
var half_tile: Vector2

var highlight3d_scene = preload("res://highlight.tscn")

func _init(map_manager: MapManager):
	super()
	half_tile = Vector2(map_manager.cell_size.x, map_manager.cell_size.z)/2
	map = map_manager
	highlight3d = highlight3d_scene.instantiate() as Highlight3D
	highlight3d.viewport.size = map.map_rect.size * 200
	add_child(highlight3d)

func set_width(w: float):
	width = w
	for line in highlight3d.viewport.get_children():
		line.width = w

func set_color(c: Color, should_refresh=true):
	color = c
	for line in highlight3d.viewport.get_children():
		line.default_color = c

func refresh():
	if clear_on_refresh:
		tiles.clear()
	_refresh_tiles()
	_draw_tiles()

func _refresh_tiles():
	# Should never be called.
	assert(false)

func _draw_tiles():
	for tile in highlight3d.viewport.get_children():
		tile.queue_free()
	for tile in tiles:
		var new_line = _draw_tile(tile)
		highlight3d.viewport.add_child(new_line)

func _add_point(line: Line2D, pos: Vector2):
	line.add_point((pos - half_tile) * 100)

func _draw_tile(pos: Vector2i) -> Line2D:
	var line = Line2D.new()
	line.default_color = color
	line.width = width * 10
	var start3 = map.get_world_position(pos)
	var start = Vector2(start3.x, start3.z)
	_add_point(line, start)
	_add_point(line, start + Vector2(map.cell_size.x, 0))
	_add_point(line, start + Vector2(map.cell_size.x, map.cell_size.z))
	_add_point(line, start + Vector2(0, map.cell_size.z))
	_add_point(line, start)
	return line
