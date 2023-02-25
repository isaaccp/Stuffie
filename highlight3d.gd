extends Node3D

class_name Highlight3D

@export var texture: ViewportTexture
@export var viewport: SubViewport
@export var sprite: Sprite3D
@export var node: Node2D

func _ready():
	sprite.texture = texture
