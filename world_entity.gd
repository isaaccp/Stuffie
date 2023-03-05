extends Node3D

class_name WorldEntity

var id_position: Vector2i
var tile_size = 2

func set_id_position(id_pos: Vector2i):
	id_position = id_pos
	position = Vector3(
		id_position[0] * tile_size + tile_size/2,
		1.5,
		id_position[1] * tile_size + tile_size/2)

func get_id_position() -> Vector2i:
	return id_position

func move(map_manager: MapManager, to: Vector2i):
	var path = get_map_path(map_manager, to)
	var curve = map_manager.curve_from_path(path)
	# Moving 1 "baked point" per 0.01 seconds, each point being
	# at a distance of 0.2 from each other.
	for point in curve.get_baked_points():
		look_at(point)
		position = point
		await get_tree().create_timer(0.01).timeout
	set_id_position(to)

func get_map_path(map_manager: MapManager, to: Vector2i):
	assert(false)
