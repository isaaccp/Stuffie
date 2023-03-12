extends TweenAnimation

class_name FireAnimation

@export var particles: GPUParticles3D
@export var speed = 10.0
var travel_time: float

func _ready():
	global_position = origin
	particles.scale = Vector3(0.2, 0.2, 0.2)
	var distance = origin.distance_to(target)
	travel_time = distance / speed
	tw = create_tween()
	tw.tween_property(self, "global_position", target, travel_time)
	tw.tween_property(particles, "scale", Vector3(1.5, 1.5, 1.5), 1.2)
	tw.tween_property(particles, "scale", Vector3(0.1, 0.1, 0.1), 0.3)

func apply_effect_time():
	return travel_time + 0.5
