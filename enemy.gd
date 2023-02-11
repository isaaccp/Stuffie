#@tool
extends WorldEntity

class_name Enemy

@export var total_action_points: int
@export var total_move_points: int
@export var total_hit_points: int
@export var damage = 5
@export var attack_range = 1
var action_points: int
var move_points: float
var hit_points: int
var done: bool
@export var enemy_name: String
@export var health_bar: HealthDisplay3D

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func initialize(pos: Vector2i):
	hit_points = total_hit_points
	set_id_position(pos)
	begin_turn()
	
func begin_turn():
	action_points = total_action_points
	move_points = total_move_points

func info_text() -> String:
	var format_vars = {
		"name": enemy_name,
		"damage": damage,
		"attack_range": attack_range,
		"move_points": move_points,
		"hit_points": hit_points,
		"total_hit_points": total_hit_points,
	}
	return (
		"[b]{name}[/b]\n" +
		"HP: {hit_points}/{total_hit_points}\n" +
		"Attack: {damage}\n" +
		"Range: {attack_range}"
	).format(format_vars)

# Returns true if enemy died.
func apply_card(card: Card) -> bool:
	hit_points -= card.damage
	health_bar.update_health(hit_points, total_hit_points)
	if hit_points <= 0:
		return true
	return false
