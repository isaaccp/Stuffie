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
