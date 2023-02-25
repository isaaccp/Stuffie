extends Node3D

class_name Highlight3D

@export var container: Node2D
@export var viewport: SubViewport
@export var sprite: Sprite3D

func set_size(size: Vector2):
	viewport.size = size / sprite.pixel_size
