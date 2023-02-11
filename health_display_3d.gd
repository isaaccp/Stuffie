extends Sprite3D

class_name HealthDisplay3D

@onready var health_display = $SubViewport/HealthDisplay

func _ready():
	texture = $SubViewport.get_texture()

func update_health(value, full):
	health_display.update_health(value, full)
