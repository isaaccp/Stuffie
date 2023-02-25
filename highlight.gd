extends Node3D

class_name Highlight

var map: MapManager
var width = 1.0
var color = Color(1, 1, 1, 1)
var tiles: Array
var labeled_tiles: Dictionary
var modulate: bool
var clear_on_refresh = true
var highlight3d: Highlight3D
var half_tile: Vector2

var highlight3d_scene = preload("res://highlight.tscn")

func _init(map_manager: MapManager):
	super()
	half_tile = Vector2(map_manager.cell_size.x, map_manager.cell_size.z)/2
	map = map_manager
	highlight3d = highlight3d_scene.instantiate() as Highlight3D
	highlight3d.set_size(map.map_rect.size * map.cell_size.x)
	add_child(highlight3d)

func set_width(w: float):
	width = w
	for line in highlight3d.container.get_children():
		line.width = w

func set_color(c: Color):
	color = c
	for line in highlight3d.container.get_children():
		line.default_color = c

func refresh():
	# Make this a bit cleaner if needed later.
	# For now labeled_tiles is only used in TilesHighlight that doesn't
	# need refresh or similar.
	if labeled_tiles.size() > 0:
		_draw_labeled_tiles()
	else:
		if clear_on_refresh:
			tiles.clear()
		_refresh_tiles()
		_draw_tiles()

func _refresh_tiles():
	# Should never be called.
	assert(false)

func _draw_tiles():
	for tile in highlight3d.container.get_children():
		tile.queue_free()
	for number in highlight3d.get_node('Numbers').get_children():
		number.queue_free()
	for tile in tiles:
		var new_line = _draw_tile(tile)
		highlight3d.container.add_child(new_line)

func _draw_labeled_tiles():
	for tile in highlight3d.container.get_children():
		tile.queue_free()
	for number in highlight3d.get_node('Numbers').get_children():
		number.queue_free()
	var values = labeled_tiles.values()
	# TODO: The modulation right now is pretty ad-hoc, but it works for the
	# current use case, we can refactor if needed later.
	var max_value = 0
	if values.size() > 0 and typeof(values[0]) == TYPE_INT:
		max_value = values.max()
	for tile in labeled_tiles.keys():
		var new_line = _draw_tile(tile)
		highlight3d.container.add_child(new_line)
		if labeled_tiles.has(tile) and labeled_tiles[tile]:
			var label = Label3D.new()
			label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			var label_info = labeled_tiles[tile]
			if typeof(label_info) == TYPE_STRING:
				label.text = labeled_tiles[tile]
			elif typeof(label_info) == TYPE_INT:
				label.text = "%d" % label_info
				var mod_value = float(label_info) / max_value
				label.modulate = Color(mod_value, mod_value, mod_value)
			else:
				assert(false)
			label.pixel_size = 0.025
			label.position = map.get_world_position(tile) + Vector3(0, -1.2, 0)
			highlight3d.get_node('Numbers').add_child(label)

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
