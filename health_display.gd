extends Node2D

class_name HealthDisplay

var bar_red = preload("res://resources/ui/bar_horizontal_red.png")
var bar_green = preload("res://resources/ui/bar_horizontal_green.png")
var bar_yellow = preload("res://resources/ui/bar_horizontal_yellow.png")

@onready var healthbar = $HealthBar

func _ready():
	pass

func _process(delta):
	global_rotation = 0

func update_health(value, max_value):
	healthbar.texture_progress = bar_green
	healthbar.max_value = max_value
	if value < healthbar.max_value * 0.7:
		healthbar.texture_progress = bar_yellow
	if value < healthbar.max_value * 0.35:
		healthbar.texture_progress = bar_red
	healthbar.value = value
	if value < healthbar.max_value:
		show()
