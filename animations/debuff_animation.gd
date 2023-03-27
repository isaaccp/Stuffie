extends TweenAnimation

class_name DebuffAnimation

@export var particles: GPUParticles3D

func _ready():
	global_position = target
	tw = create_tween()
	tw.tween_interval(0.5)
	tw.tween_callback(particles.set.bind("emitting", false))
	tw.tween_interval(0.3)

func apply_effect_time():
	return 0.5
