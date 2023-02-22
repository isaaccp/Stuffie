extends WorldEntity

class_name Character

@export var total_action_points: int
@export var total_move_points: int
@export var total_hit_points: int
@export var initial_relic: Relic
@export var portrait_texture: TextureRect
var action_points: int
var move_points: float
var hit_points: int
var block: int
var power: int
var pending_action_cost: int = -1
var pending_move_cost: float = -1.0
var relics: Array[Relic]

@export var health_bar: HealthDisplay3D
@export var deck: Deck
@export var extra_cards: CardSelectionSet
@export var all_cards: CardSelectionSet
@export var camp_choice: CampChoice

var card_upgrades: Dictionary

signal changed
signal made_active(active: bool)
signal stage_started(character: Character)
signal stage_ended(character: Character)
signal turn_started(character: Character)
signal turn_ended(character: Character)
signal attacked(character: Character)
signal killed_enemy(character: Character)

class Snapshot:
	var action_points: int
	var move_points: int
	var hit_points: int
	var block: int
	var power: int

	func _init(character: Character):
		action_points = character.action_points
		move_points = character.move_points
		hit_points = character.hit_points
		block = character.block
		power = character.power

var snapshot: Snapshot

# Called when the node enters the scene tree for the first time.
func _ready():
	process_cards()
	changed.connect(_on_changed)
	heal_full()
	snap()

func process_cards():
	for card in all_cards.cards:
		if card.base_card:
			if not card_upgrades.has(card.base_card.card_name):
				card_upgrades[card.base_card.card_name] = []
			card_upgrades[card.base_card.card_name].push_back(card)

func _on_changed():
	health_bar.update_health(hit_points, total_hit_points)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func snap():
	snapshot = Snapshot.new(self)

func add_relic(relic: Relic):
	relics.push_back(relic)
	relic.connect_signals(self)

func begin_stage():
	deck.reset()
	stage_started.emit(self)

func end_stage():
	power = 0
	stage_ended.emit(self)
	refresh()

func begin_turn():
	snap()
	action_points = total_action_points
	move_points = total_move_points
	block = 0
	if power > 0:
		power -= 1
	get_new_hand()
	turn_started.emit(self)
	refresh()

func end_turn():
	snap()
	turn_ended.emit(self)

func get_new_hand():
	deck.discard_hand()
	deck.draw_cards(4)

func draw_cards(number: int):
	deck.draw_cards(number)

func draw_attack(number: int):
	deck.draw_attack(number)

func refresh():
	changed.emit()

func set_active(active: bool):
	made_active.emit(active)

func set_pending_action_cost(pending_cost: int):
	pending_action_cost = pending_cost
	refresh()

func clear_pending_action_cost():
	pending_action_cost = -1
	refresh()

func reduce_move(move_cost: float):
	move_points -= move_cost
	refresh()

func set_pending_move_cost(pending_cost: float):
	pending_move_cost = pending_cost
	refresh()

func clear_pending_move_cost():
	pending_move_cost = -1.0
	refresh()

func heal(hp: int):
	hit_points += hp
	if hit_points > total_hit_points:
		hit_points = total_hit_points
	refresh()

func heal_full():
	hit_points = total_hit_points
	refresh()

func add_block(block_amount: int):
	block += block_amount
	refresh()

func apply_relic_damage_change(damage: int):
	var dmg = damage
	for relic in relics:
		dmg = relic.apply_damage_change(dmg, self)
	return dmg

# Apply attack from enemy to this character.
func apply_attack(enemy: Enemy):
	var damage = enemy.effective_damage(self)
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
	refresh()

func camp_choices():
	var camp_choices = [camp_choice]
	for relic in relics:
		for choice in relic.camp_choices():
			camp_choices.push_back(choice)
	return camp_choices
