extends Control

class_name StatusEffectIcon

@export var texture_rect: TextureRect
@export var label: Label

func initialize(text: String, texture: Texture, tooltip: String):
	texture_rect.texture = texture
	texture_rect.tooltip_text = tooltip
	label.text = text
