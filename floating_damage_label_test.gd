extends Node3D

const scene = preload("res://floating_damage_label.tscn")

@export var damage_parent: Node3D

func add_damage():
	var floating_damage = scene.instantiate() as FloatingDamageLabel
	damage_parent.add_child(floating_damage)
	floating_damage.set_damage(10)
	floating_damage.float_and_disappear()

func _unhandled_input(event):
	if event is InputEventMouseButton:
		var mouse_event = event as InputEventMouseButton
		if mouse_event.button_index == 1 and mouse_event.pressed:
			add_damage()
