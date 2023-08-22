extends Node3D

class_name FloatingDamageLabel

@export var container: Node3D
@export var label: Label3D

func set_damage(damage: int):
	label.text = "%d" % damage

func float_and_disappear():
	var tw = create_tween()
	position.y = position.y + 2
	tw.parallel().tween_property(self, "position:y", position.y + 1, 1)
	tw.parallel().tween_property(label, "modulate", Color(1, 1, 1 ,0), 1)
	tw.parallel().tween_property(label, "outline_modulate", Color(0, 0, 0, 0), 1)
	tw.tween_callback(destroy)

func destroy():
	queue_free.call_deferred()
