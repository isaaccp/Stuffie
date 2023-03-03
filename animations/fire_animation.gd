extends TweenAnimation

class_name FireAnimation

@export var particles: GPUParticles3D

func _ready():
	particles.scale = Vector3(0.1, 0.1, 0.1)
	tw = create_tween()
	tw.tween_property(particles, "scale", Vector3(1.5, 1.5, 1.5), 1.2)
	tw.tween_property(particles, "scale", Vector3(0.1, 0.1, 0.1), 0.3)

func apply_effect_time():
	return 0.75
