extends Unit

class_name Enemy

@export var base_move_points: int
@export var base_hit_points: int

@export var level_move_points: float
@export var level_hit_points: float
@export var level_damage: float

@export var cards: Array[Card]
var unit_cards: Array[UnitCard]
var level: int
var done: bool

var is_mock = false

@export var enemy_type: Enum.EnemyId
@export var enemy_name: String

# Called when the node enters the scene tree for the first time.
func _ready():
	super()
	for card in cards:
		unit_cards.push_back(UnitCard.new(self, card))

func mock():
	var m = Enemy.new()
	m.is_mock = true
	m.id_position = id_position
	m.move_points = move_points
	m.action_points = action_points
	m.extra_damage = extra_damage
	m.status_manager = status_manager.clone()
	for card in cards:
		m.unit_cards.push_back(UnitCard.new(m, card))
	m.next_turn_cards = next_turn_cards
	m.snap()
	return m

func initialize(pos: Vector2i, level: int):
	self.level = level
	total_move_points = int(base_move_points + level*level_move_points)
	total_hit_points = int(base_hit_points + level*level_hit_points)
	extra_damage = int(level*level_damage)

	hit_points = total_hit_points
	set_id_position(pos)
	end_turn()
	action_points = 0

func end_turn():
	# Do not increase action points if enemy was paralyzed.
	if get_status(StatusDef.Status.PARALYSIS) == 0:
		action_points += total_action_points
	super()

func hp_text():
	if pending_damage_set:
		var lethal_text = ""
		if pending_damage >= hit_points:
			lethal_text = "💀"
		return "HP: %s[color=red]%d[/color]/%d" % [lethal_text, hit_points - pending_damage, total_hit_points]
	else:
		return "HP: %d/%d" % [hit_points, total_hit_points]

func actions_text():
	var text = "%s\n" % enemy_name
	text += hp_text() + "\n"
	text += "Actions\n"
	for unit_card in unit_cards:
		text += "%d💢 %s: %s\n" % [unit_card.card.cost, unit_card.card.card_name, unit_card.get_description()]
	return text

func move(curve: Curve3D, to: Vector2i):
	if not is_mock:
		await move_path(curve)
	set_id_position(to)

func max_attack_distance() -> int:
	var max_distance = 0
	for card in cards:
		if card.is_attack():
			if card.target_distance > max:
				max_distance = card.target_distance
	return max_distance

# Nothing to do as the health bar is managed separately.
func refresh():
	pass

func get_save_state():
	var save_state = EnemySaveState.new()
	save_state.enemy_type = enemy_type
	save_state.id_position = get_id_position()
	save_state.total_move_points = total_move_points
	save_state.total_hit_points = total_hit_points
	save_state.level = level
	save_state.move_points = move_points
	save_state.hit_points = hit_points
	save_state.action_points = action_points
	save_state.status_manager = status_manager
	return save_state

func load_save_state(save_state: EnemySaveState):
	set_id_position(save_state.id_position)
	total_move_points = save_state.total_move_points
	total_hit_points = save_state.total_hit_points
	level = save_state.level
	move_points = save_state.move_points
	hit_points = save_state.hit_points
	action_points = save_state.action_points
	status_manager = save_state.status_manager
