extends Node

class_name Highlight

enum HighlightType {
	# Highlight of all tiles within a distance.
	AREA_DISTANCE,
	CARD_TARGET,
}

var map: MapManager
var camera: Camera3D
var id_position: Vector2i
var direction: Vector2
var highlight_type: HighlightType
var width = 1.0
var color = Color(1, 1, 1, 1)
var area_distance: int
var card_target: Card
var tiles: Array[Vector2i]

func _init(map_manager: MapManager, camera3d: Camera3D):
	super()
	map = map_manager
	camera = camera3d

func create_area_distance_cursor(pos: Vector2i, distance: int):
	id_position = pos
	highlight_type = HighlightType.AREA_DISTANCE
	area_distance = distance
	refresh()
	
func create_card_target_cursor(pos: Vector2i, dir: Vector2, card: Card):
	id_position = pos
	highlight_type = HighlightType.CARD_TARGET
	direction = dir
	card_target = card
	refresh()
	
func update_card_target_cursor(pos: Vector2i, dir: Vector2):
	id_position = pos
	direction = dir
	refresh()
	
func set_width(w: float):
	width = w
	refresh()
	
func set_color(c: Color):
	color = c
	refresh()

func set_id_position(pos: Vector2i):
	id_position = pos
	refresh()
	
func refresh():
	tiles.clear()
	if highlight_type == HighlightType.AREA_DISTANCE:
		_refresh_area_distance_tiles()
	elif highlight_type == HighlightType.CARD_TARGET:
		_refresh_card_target_tiles()
	_draw_tiles()

func _refresh_area_distance_tiles():
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
		
func _refresh_card_target_tiles():
	var target_mode = card_target.target_mode
	if target_mode == Card.TargetMode.SELF:
		tiles.push_back(id_position)
	elif target_mode == Card.TargetMode.ENEMY:
		for effect_pos in card_target.effect_area(direction):
			tiles.push_back(id_position + effect_pos)
	elif target_mode == Card.TargetMode.AREA:
		pass

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
