extends Node3D

class_name HealthDisplay3D

@export var sprite: Sprite3D
@export var health_display: HealthDisplay
@export var viewport: SubViewport

func _ready():
	sprite.texture = viewport.get_texture()

func update_health(value, full):
	health_display.update_health(value, full)
