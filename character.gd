extends Node2D

class_name Character

var total_action_points: int = 5
var total_move_points: int = 10
var action_points: int
var move_points: float
var pending_move_cost: float = -1.0

# Move somewhere where it can be used from anywhere or figure out how to pass.
var tile_size: int = 16

var portrait: CharacterPortrait
var id_position: Vector2i

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func begin_turn():
	action_points = total_action_points
	move_points = total_move_points
	refresh_portrait()

func set_portrait(character_portrait: CharacterPortrait):
	portrait = character_portrait
	refresh_portrait()

func refresh_portrait():
	portrait.set_portrait_texture($Portrait.texture)
	portrait.set_move_points(pending_move_cost, move_points, total_move_points)
	
func set_active(active: bool):
	portrait.set_active(active)

func reduce_move(move_cost: float):
	move_points -= move_cost
	refresh_portrait()

func set_pending_move_cost(pending_cost: float):
	pending_move_cost = pending_cost
	refresh_portrait()
	
func clear_pending_move_cost():
	pending_move_cost = -1.0
	refresh_portrait()
	
func set_id_position(id_pos: Vector2i):
	id_position = id_pos
	position = id_position * tile_size + Vector2i(tile_size/2, tile_size/2)
	
func get_id_position() -> Vector2i:
	return id_position

