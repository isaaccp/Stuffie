#@tool
extends WorldEntity

class_name Enemy

enum AttackStyle {
	FIRE,
}

@export var total_action_points: int
@export var total_move_points: int
@export var total_hit_points: int
@export var damage = 5
@export var attack_range = 1
var action_points: int
var move_points: float
var hit_points: int
var weakness: int
# TODO: Implement effect of this.
var vulnerability: int
var done: bool

@export var enemy_name: String
@export var health_bar: HealthDisplay3D
@export var attack_style: AttackStyle
@export var weapon: Node3D

# Called when the node enters the scene tree for the first time.
func _ready():
	# For fireable weapons, hide them until attack.
	if attack_style == AttackStyle.FIRE:
		weapon.hide()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func initialize(pos: Vector2i):
	hit_points = total_hit_points
	set_id_position(pos)
	end_turn()
	
func end_turn():
	action_points = total_action_points
	move_points = total_move_points
	if weakness > 0:
		weakness -= 1
	if vulnerability > 0:
		vulnerability -= 1

func info_text() -> String:
	var damage_text = "%s" % damage
	if damage != effective_damage(null):
		damage_text = "%s ([color=red]%s[/color])" % [damage, effective_damage(null)]
	var format_vars = {
		"name": enemy_name,
		"damage": damage_text,
		"attack_range": attack_range,
		"move_points": move_points,
		"hit_points": hit_points,
		"total_hit_points": total_hit_points,
		"weakness": weakness,
		"vulnerability": vulnerability,
	}
	var text = (
		"[b]{name}[/b]\n" +
		"HP: {hit_points}/{total_hit_points}\n"
	)
	text += "Attack: {damage}\n"
	text += "Range: {attack_range}\n"
	if weakness > 0:
		text += "[url]Weakness[/url]: {weakness}\n"
	if vulnerability > 0:
		text += "[url]Vulnerability[/url]: {vulnerability}\n"
	var formatted_text = text.format(format_vars)
	return formatted_text

func effective_damage(character: Character):
	var new_damage = damage
	if weakness > 0:
		new_damage *= 0.5
	return int(new_damage)

func refresh():
	health_bar.update_health(hit_points, total_hit_points)
