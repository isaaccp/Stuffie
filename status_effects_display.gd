extends Control

class_name StatusEffectsDisplay

@export var columns: int

var status_effect_scene = preload("res://status_effect_icon.tscn")
var x = 0
var y = 0

var icon_size = Vector2(48, 48)

func clear():
	for child in get_children():
		remove_child(child)
		child.queue_free()
	x = 0
	y = 0

func add_effect(text: String, icon: Texture, tooltip: String):
	var status_effect = status_effect_scene.instantiate() as StatusEffectIcon
	status_effect.initialize(text, icon, tooltip)
	add_child(status_effect)
	status_effect.position = Vector2(x * icon_size.x, y * icon_size.y)
	x += 1
	if x == columns:
		x = 0
		y += 1

func add_relic(icon: Texture, tooltip: String):
	add_effect("", icon, tooltip)

func add_status_effect(value: int, icon: Texture, tooltip: String):
	add_effect("%d" % value, icon, tooltip)
