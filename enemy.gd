extends Node2D

class_name Enemy

@export var initial_position: Vector2i
@export var total_action_points: int
@export var total_move_points: int
@export var total_hit_points: int
var action_points: int
var move_points: float
var hit_points: int
@export var enemy_name: String

var id_position: Vector2i

# Move somewhere where it can be used from anywhere or figure out how to pass.
var tile_size: int = 16

# Called when the node enters the scene tree for the first time.
func _ready():
	hit_points = total_hit_points
	set_id_position(initial_position)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func begin_turn():
	action_points = total_action_points
	move_points = total_move_points

func set_id_position(id_pos: Vector2i):
	id_position = id_pos
	position = id_position * tile_size + Vector2i(tile_size/2, tile_size/2)
	
func get_id_position() -> Vector2i:
	return id_position

func info_text() -> String:
	var format_vars = {
		"name": enemy_name,
		"hit_points": hit_points,
		"total_hit_points": total_hit_points,
	}
	return "[b]{name}[/b]\nHP: {hit_points}/{total_hit_points}".format(format_vars)

# Returns true if enemy died.
func apply_card(card: Card) -> bool:
	hit_points -= card.damage
	if hit_points <= 0:
		return true
	return false
