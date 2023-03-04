extends RefCounted

class_name AnimationManager

var fire_effect = preload("res://animations/fire_animation.tscn")
var slash_effect = preload("res://animations/slash_animation.tscn")
var arcane_effect = preload("res://animations/arcane_animation.tscn")

var effects = {
	Card.TargetAnimationType.FIRE: fire_effect,
	Card.TargetAnimationType.SLASH: slash_effect,
	Card.TargetAnimationType.ARCANE: arcane_effect,
}

func get_effect(effect: Card.TargetAnimationType):
	if effect in effects:
		return effects[effect].instantiate()
	return null
