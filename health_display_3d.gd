extends Sprite3D

class_name HealthDisplay3D

@onready var health_display = $SubViewport/HealthDisplay
@onready var viewport = $SubViewport

func _ready():
	texture = viewport.get_texture()

func update_health(value, full):
	health_display.update_health(value, full)
