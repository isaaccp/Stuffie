extends RefCounted

class_name AnimationManager

var fire_effect = preload("res://animations/fire_animation.tscn")
var slash_effect = preload("res://animations/slash_animation.tscn")
var arcane_effect = preload("res://animations/arcane_animation.tscn")
var projectile_effect = preload("res://animations/projectile_animation.tscn")
var buff_effect = preload("res://animations/buff_animation.tscn")
var debuff_effect = preload("res://animations/debuff_animation.tscn")

var effects = {
	Enum.TargetAnimationType.FIRE: fire_effect,
	Enum.TargetAnimationType.SLASH: slash_effect,
	Enum.TargetAnimationType.ARCANE: arcane_effect,
	Enum.TargetAnimationType.PROJECTILE: projectile_effect,
	Enum.TargetAnimationType.BUFF: buff_effect,
	Enum.TargetAnimationType.DEBUFF: debuff_effect,
}

func get_effect(effect: Enum.TargetAnimationType):
	if effect in effects:
		return effects[effect].instantiate()
	return null
