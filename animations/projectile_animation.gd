extends TweenAnimation

class_name ProjectileAnimation

@export var speed = 10.0
var travel_time: float

func _ready():
	global_position = origin
	look_at(target, Vector3.UP)
	var distance = origin.distance_to(target)
	travel_time = distance / speed
	tw = create_tween()
	tw.tween_property(self, "global_position", target, travel_time)

func apply_effect_time():
	return travel_time
