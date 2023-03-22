extends Unit

class_name Enemy

enum AttackStyle {
	FIRE,
}

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
@export var attack_style: AttackStyle
@export var weapon: Node3D

# Called when the node enters the scene tree for the first time.
func _ready():
	super()
	for card in cards:
		unit_cards.push_back(UnitCard.new(self, card))
	# For fireable weapons, hide them until attack.
	if attack_style == AttackStyle.FIRE:
		if weapon:
			weapon.hide()

func mock():
	var m = Enemy.new()
	m.is_mock = true
	m.id_position = id_position
	m.total_move_points = total_move_points
	m.extra_damage = extra_damage
	for card in cards:
		m.unit_cards.push_back(UnitCard.new(m, card))
	return m

func initialize(pos: Vector2i, level: int):
	self.level = level
	total_move_points = int(base_move_points + level*level_move_points)
	total_hit_points = int(base_hit_points + level*level_hit_points)
	extra_damage = int(level*level_damage)

	hit_points = total_hit_points
	set_id_position(pos)
	end_turn()

func info_text() -> String:
	var format_vars = {
		"name": enemy_name,
		"level": level,
		"move_points": move_points,
		"total_move_points": total_move_points,
		"hit_points": hit_points,
		"total_hit_points": total_hit_points,
		"block": block,
		"dodge": dodge,
		"power": power,
		"weakness": weakness,
		"paralysis": paralysis,
	}
	var text = (
		"[b]{name}[/b]\n" +
		"Level: {level}\n" +
		"HP: {hit_points}/{total_hit_points}\n" +
		"MP: {move_points}/{total_move_points}\n"
	)
	if block > 0:
		text += "[url]Block[/url]: {block}\n"
	if dodge > 0:
		text += "[url]Dodge[/url]: {dodge}\n"
	if power > 0:
		text += "[url]Power[/url]: {power}\n"
	if weakness > 0:
		text += "[url]Weakness[/url]: {weakness}\n"
	if paralysis > 0:
		text += "[url]Paralysis[/url]: {paralysis}\n"
	text += "Actions\n"
	for unit_card in unit_cards:
		text += "%s: %s\n" % [unit_card.card.card_name, unit_card.get_description()]
	var formatted_text = text.format(format_vars)
	return formatted_text

func move(curve: Curve3D, to: Vector2i):
	var from = get_id_position()
	if not is_mock:
		await move_path(curve)
	set_id_position(to)

func max_attack_distance() -> int:
	var max = 0
	for card in cards:
		if card.is_attack():
			if card.target_distance > max:
				max = card.target_distance
	return max

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
	save_state.weakness = weakness
	save_state.paralysis = paralysis
	return save_state

func load_save_state(save_state: EnemySaveState):
	set_id_position(save_state.id_position)
	total_move_points = save_state.total_move_points
	total_hit_points = save_state.total_hit_points
	level = save_state.level
	move_points = save_state.move_points
	hit_points = save_state.hit_points
	weakness = save_state.weakness
	paralysis = save_state.paralysis
