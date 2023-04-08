extends Node3D

class_name HealthDisplay3D

@export var sprite: Sprite3D
@export var health_display: CurrentNextHealthBar
@export var texture: ViewportTexture

func _ready():
	sprite.texture = texture

func set_health(current: int, max: int, next: int):
	health_display.set_health(current, max, next)
