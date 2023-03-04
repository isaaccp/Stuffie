extends TweenAnimation

class_name FireAnimation

@export var particles: GPUParticles3D

func _ready():
	global_position = origin
	particles.scale = Vector3(0.2, 0.2, 0.2)
	tw = create_tween()
	tw.tween_property(self, "global_position", target, 0.5)
	tw.tween_property(particles, "scale", Vector3(1.5, 1.5, 1.5), 1.2)
	tw.tween_property(particles, "scale", Vector3(0.1, 0.1, 0.1), 0.3)

func apply_effect_time():
	return 1.1
