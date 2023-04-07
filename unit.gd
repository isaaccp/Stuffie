extends WorldEntity

class_name Unit

@export var total_move_points: int
# Both player and enemy have action points, but
# they work slightly different. Enemies gain
# total_action_points per round, can only play
# one action regardless of action points, and
# don't lose action points at beginning of turn.
@export var total_action_points: int
@export var portrait_texture: Texture
var move_points: int
var action_points: int
# Mostly intended for enemies so levels can add extra damage.
var extra_damage = 0
# Cards to be played at beginning of next turn.
var next_turn_cards: Array[Card]

func begin_turn():
	var bleed = status_manager.get_status(StatusDef.Status.BLEED)
	if bleed > 0:
		# Not blockable or dodgeble.
		apply_damage(bleed, false, false)
		status_manager.decrement_status(StatusDef.Status.BLEED)
	# Remove block/dodge after damage effects, so if some of the damage is
	# preventable, block from previous turn can be used.
	super()

func clear_next_turn_cards():
	next_turn_cards.clear()

func end_turn():
	super()
	move_points = total_move_points
	status_manager.decrement_status(StatusDef.Status.POWER)
	status_manager.decrement_status(StatusDef.Status.WEAKNESS)
	status_manager.decrement_status(StatusDef.Status.PARALYSIS)

func add_next_turn_card(card: Card):
	next_turn_cards.push_back(card)
