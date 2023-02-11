extends WorldEntity

class_name Character

@export var total_action_points: int
@export var total_move_points: int
@export var total_hit_points: int
var action_points: int
var move_points: float
var hit_points: int
var block: int
var pending_action_cost: int = -1
var pending_move_cost: float = -1.0

var portrait: CharacterPortrait

@export var health_bar: HealthDisplay3D
var is_ready = false

@export var deck: Deck


# Called when the node enters the scene tree for the first time.
func _ready():
	is_ready = true
	hit_points = total_hit_points

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func begin_stage():
	deck.reset()
	
func begin_turn():
	action_points = total_action_points
	move_points = total_move_points
	block = 0
	draw_cards()
	refresh_portrait()

func draw_cards():
	deck.discard_hand()
	deck.draw_cards(4)
	
func set_portrait(character_portrait: CharacterPortrait):
	portrait = character_portrait
	refresh_portrait()

func refresh_portrait():
	if is_ready:
		portrait.set_portrait_texture($Portrait.texture)
		portrait.set_action_points(pending_action_cost, action_points, total_action_points)
		portrait.set_move_points(pending_move_cost, move_points, total_move_points)
		portrait.set_hit_points(hit_points, total_hit_points)
		portrait.set_block(block)
		health_bar.update_health(hit_points, total_hit_points)

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
	
# Apply effect of card to this character.
func apply_card(card: Card):
	if card.move_points > 0:
		move_points += card.move_points
	if card.block > 0:
		block += card.block
	refresh_portrait()

# Apply attack from enemy to this character.
func apply_attack(enemy: Enemy):
	var damage = enemy.damage
	if block > 0:
		if damage <= block:
			block -= damage
			damage = 0
		else:
			damage -= block
			block = 0
	hit_points -= damage
	if hit_points <= 0:
		return true
	refresh_portrait()
