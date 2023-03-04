extends TweenAnimation

class_name ArcaneAnimation

@export var particles: GPUParticles3D

func _ready():
	global_position = origin
	particles.scale = Vector3(0.5, 0.5, 0.5)
	var offset = (target - origin).normalized()
	tw = create_tween()
	tw.tween_property(self, "global_position", target - offset * 0.5, 0.8)
	tw.tween_callback(particles.process_material.set.bind("initial_velocity_max", 20))
	tw.tween_callback(particles.set.bind("amount", 400))
	tw.tween_callback(particles.set.bind("lifetime", 0.4))
	tw.tween_interval(0.3)

func apply_effect_time():
	return 0.85
