extends TweenAnimation

class_name ArcaneAnimation

@export var particles: GPUParticles3D

func _ready():
	global_position = origin
	particles.scale = Vector3(0.5, 0.5, 0.5)
	tw = create_tween()
	tw.tween_property(self, "global_position", target, 0.8)
	tw.tween_property(particles.process_material, "initial_velocity_max", 5, 0.3)
	tw.tween_property(particles.process_material, "initial_velocity_max", 1, 0.6)
	#tw.tween_property(particles, "scale", Vector3(2.0, 2.0, 2.0), 0.2)
	#tw.tween_property(particles, "scale", Vector3(0.0, 0.0, 0.0), 0.3)

func apply_effect_time():
	return 0.9
