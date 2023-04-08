extends HBoxContainer

class_name CurrentNextHealthBar

@export var next_hp: Control
@export var current_hp: Control
@export var missing_hp: Control

@export var hide_full = false

var current_health: int
var max_health: int
var next_health: int

var is_ready = false
var tween: Tween

func _ready():
	is_ready = true
	update_health()

func set_health(current: int, max: int, next: int):
	current_health = current
	max_health = max
	next_health = next
	if next_health < 0:
		next_health = 0
	update_health()

func update_health():
	if not is_ready:
		return
	if hide_full and current_health == max_health and current_health == next_health:
		hide()
		return
	show()
	next_hp.size_flags_stretch_ratio = next_health
	current_hp.size_flags_stretch_ratio = (current_health - next_health)
	missing_hp.size_flags_stretch_ratio = (max_health - current_health)
	#if next_health > 0:
	#	if tween:
	#		tween.kill()
	#else:
	if not tween or not tween.is_running():
		tween = create_tween()
		tween.set_loops()
		tween.tween_property(current_hp, "modulate:a", 0.25, 1.0)
		tween.tween_property(current_hp, "modulate:a", 1, 1.0)
