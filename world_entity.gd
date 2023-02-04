extends Node2D

class_name WorldEntity

var id_position: Vector2i
var tile_size = 16

func set_id_position(id_pos: Vector2i):
	id_position = id_pos
	position = id_position * tile_size + Vector2i(tile_size/2, tile_size/2)
	
func get_id_position() -> Vector2i:
	return id_position
