extends TweenAnimation

class_name SlashAnimation

@export var sword: Node3D

func _ready():
	tw = create_tween()
	tw.tween_property(sword, "rotation_degrees", Vector3(0, 90, -90), 0.6)

func apply_effect_time():
	return 0.4
