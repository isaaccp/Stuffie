extends Node3D

class_name TweenAnimation

var tw: Tween

# A hint on how much to wait since starting the animation to
# apply damage, etc.
func apply_effect_time():
	return 0.5

func finished():
	if not tw.is_valid():
		return
	await tw.finished
