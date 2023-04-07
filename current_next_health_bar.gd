extends HBoxContainer

class_name CurrentNextHealthBar

@export var next_hp: ColorRect
@export var current_hp: ColorRect
@export var missing_hp: ColorRect

var current_health: int
var max_health: int
var next_health: int

var current_hp_color: Color
var is_ready = false
var tween: Tween

func _ready():
	is_ready = true
	current_hp_color = current_hp.color
	update_health()

func set_health(current, max, next):
	current_health = current
	max_health = max
	next_health = next
	update_health()

func update_health():
	if not is_ready:
		return
	next_hp.size_flags_stretch_ratio = next_health
	current_hp.size_flags_stretch_ratio = (current_health - next_health)
	missing_hp.size_flags_stretch_ratio = (max_health - current_health)
	if next_health > 0:
		if tween:
			tween.kill()
	else:
		if not tween or not tween.is_running():
			tween = create_tween()
			tween.set_loops()
			tween.tween_property(current_hp, "color", Color(1, 1, 1), 0.5)
			tween.tween_property(current_hp, "color", current_hp_color, 0.5)
