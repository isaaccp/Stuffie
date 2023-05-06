extends Node3D

class_name HealthDisplay3D

@export var sprite: Sprite3D
@export var health_display: CurrentNextHealthBar
@export var skull: Control

func _ready():
	# This causes a lot of error spam if done through exported variables.
	# I thought those errors were making it not work on the project export,
	# but even without the errors it doesn't seem to work.
	sprite.texture = $SubViewport.get_texture()

func set_health(current_hp: int, max_hp: int, next_hp: int):
	health_display.set_health(current_hp, max_hp, next_hp)
	skull.visible = next_hp <= 0
