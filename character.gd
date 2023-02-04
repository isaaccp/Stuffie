extends WorldEntity

class_name Character

@export var total_action_points: int
@export var total_move_points: int
@export var total_hit_points: int
var action_points: int
var move_points: float
var hit_points: int
var pending_action_cost: int = -1
var pending_move_cost: float = -1.0

var portrait: CharacterPortrait

@export var deck: Deck

# Called when the node enters the scene tree for the first time.
func _ready():
	hit_points = total_hit_points

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func begin_turn():
	action_points = total_action_points
	move_points = total_move_points
	draw_cards()
	refresh_portrait()

func draw_cards():
	deck.discard_hand()
	deck.draw_cards(2)
	
func set_portrait(character_portrait: CharacterPortrait):
	portrait = character_portrait
	refresh_portrait()

func refresh_portrait():
	portrait.set_portrait_texture($Portrait.texture)
	portrait.set_action_points(pending_action_cost, action_points, total_action_points)
	portrait.set_move_points(pending_move_cost, move_points, total_move_points)
	
func set_active(active: bool):
	portrait.set_active(active)

func set_pending_action_cost(pending_cost: int):
	pending_action_cost = pending_cost
	refresh_portrait()
	
func clear_pending_action_cost():
	pending_action_cost = -1
	refresh_portrait()
	
func reduce_move(move_cost: float):
	move_points -= move_cost
	refresh_portrait()

func set_pending_move_cost(pending_cost: float):
	pending_move_cost = pending_cost
	refresh_portrait()
	
func clear_pending_move_cost():
	pending_move_cost = -1.0
	refresh_portrait()
	
func apply_card(card: Card):
	if card.move_points > 0:
		move_points += card.move_points
