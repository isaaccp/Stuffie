extends WorldEntity

class_name Character

enum CharacterType {
	NO_CHARACTER,
	WARRIOR,
	WIZARD,
}

@export var character_type: CharacterType
@export var total_action_points: int
@export var total_move_points: int
@export var total_hit_points: int
@export var cards_per_turn: int
@export var initial_relic: Relic
@export var portrait_texture: TextureRect
var action_points: int
var move_points: int
var hit_points: int
var block: int
var power: int
var dodge: int
var pending_action_cost: int = -1
var pending_move_cost: int = -1
var relic_manager = RelicManager.new()
var shared_bag: SharedBag
# TODO: Remove this. As of now, this is required because character.teleport()
# needs access to the gameplay to e.g. display a cursor for the move, etc.
# Figure out a cleaner way.
var gameplay: Gameplay

@export var health_bar: HealthDisplay3D
@export var deck: Deck
@export var extra_cards: CardSelectionSet
@export var all_cards: CardSelectionSet
@export var camp_choice: CampChoice

var card_upgrades: Dictionary
var upgrade_scene = preload("res://card_upgrade.tscn")
var chooser_scene = preload("res://card_collection_chooser.tscn")

signal changed
signal made_active(active: bool)
signal stage_started(character: Character)
signal stage_ended(character: Character)
signal turn_started(character: Character)
signal turn_ended(character: Character)
signal card_played(character: Character, card: Card)
signal attacked(character: Character)
signal killed_enemy(character: Character)

class Snapshot:
	var action_points: int
	var move_points: int
	var hit_points: int
	var block: int
	var power: int
	var dodge: int
	var num_hand_cards: int

	func _init(character: Character):
		action_points = character.action_points
		move_points = character.move_points
		hit_points = character.hit_points
		block = character.block
		power = character.power
		dodge = character.dodge
		num_hand_cards = character.num_hand_cards()

var snapshot: Snapshot

# Called when the node enters the scene tree for the first time.
func _ready():
	process_cards()
	changed.connect(_on_changed)
	heal_full()
	relic_manager.connect_signals(self)
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

func get_card_upgrades(card: Card):
	if not card_upgrades.has(card.card_name):
		return []
	return card_upgrades[card.card_name].duplicate()

func add_relic(relic: Relic, update_stats=true):
	relic_manager.add_relic(relic)
	if update_stats:
		StatsManager.add(self, Stats.Field.RELICS_ACQUIRED, 1)

func add_temp_relic(relic: Relic):
	relic_manager.add_temp_relic(relic)

func begin_stage(gameplay: Gameplay):
	self.gameplay = gameplay
	deck.reset()
	stage_started.emit(self)

func end_stage():
	gameplay = null
	power = 0
	dodge = 0
	stage_ended.emit(self)
	relic_manager.clear_temp_relics()
	refresh()

func begin_turn():
	snap()
	action_points = total_action_points
	move_points = total_move_points
	block = 0
	# At most can carry 1 dodge.
	if dodge > 0:
		dodge = 1
	if power > 0:
		power -= 1
	draw_new_hand()
	turn_started.emit(self)
	refresh()

func end_stage_restore():
	action_points = total_action_points
	move_points = total_move_points
	block = 0
	power = 0
	dodge = 0
	deck.reset()
	clear_pending_move_cost()
	clear_pending_action_cost()
	refresh()

func end_turn():
	snap()
	turn_ended.emit(self)

func discard_hand():
	var discarded = deck.discard_hand()
	StatsManager.add(self, Stats.Field.DISCARDED_CARDS, discarded)

func num_hand_cards():
	return deck.num_hand_cards()

func draw_new_hand():
	deck.discard_hand()
	deck.draw_cards(cards_per_turn)

func draw_cards(number: int):
	var drawn = deck.draw_cards(number)
	StatsManager.add(self, Stats.Field.EXTRA_CARDS_DRAWN, drawn)

func draw_attacks(number: int):
	var drawn = deck.draw_attacks(number)
	StatsManager.add(self, Stats.Field.EXTRA_CARDS_DRAWN, drawn)

func pick_cards_condition(number: int, condition: Callable = func(c): return true):
	# TODO: Support picking more than 1.
	assert(number == 1)
	# Shuffle discard into deck before choosing.
	deck.shuffle_discard()
	var tree = get_tree().current_scene
	var chooser = chooser_scene.instantiate() as CardCollectionChooser
	chooser.initialize_from_character(self, CardCollectionChooser.Filter.DECK, condition)
	tree.add_child(chooser)
	# Not sure if there is a way to get the card that is a parameter of the signal easily.
	await chooser.card_chosen
	var card = chooser.chosen_card
	deck.hand.push_back(card)
	deck.deck.erase(card)
	chooser.queue_free()
	# TODO: Check if we actually upgraded.
	StatsManager.add(self, Stats.Field.EXTRA_CARDS_DRAWN, number)

func pick_cards(number: int):
	pick_cards_condition(number)

func pick_attacks(number: int):
	await pick_cards_condition(number, func(c): return c.is_attack())

func upgrade_cards(number: int):
	# TODO: Support upgrading more than 1 in CardUpgrade.
	assert(number == 1)
	var tree = get_tree().current_scene
	var upgrade = upgrade_scene.instantiate() as CardUpgrade
	upgrade.initialize([self])
	tree.add_child(upgrade)
	await upgrade.done
	upgrade.queue_free()
	# TODO: Check if we actually upgraded.
	StatsManager.add(self, Stats.Field.CARDS_UPGRADED, number)

func add_power(power_amount: int):
	self.power += power_amount
	StatsManager.add(self, Stats.Field.POWER_ACQUIRED, power_amount)
	refresh()

func add_block(block_amount: int):
	block += block_amount
	StatsManager.add(self, Stats.Field.BLOCK_ACQUIRED, block_amount)
	refresh()

func add_dodge(dodge_amount: int):
	dodge += dodge_amount
	StatsManager.add(self, Stats.Field.DODGE_ACQUIRED, dodge_amount)
	refresh()

func teleport(distance: int):
	await gameplay.teleport(self, distance)

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

func reduce_move(move_cost: int):
	move_points -= move_cost
	refresh()

func set_pending_move_cost(pending_cost: int):
	pending_move_cost = pending_cost
	refresh()

func clear_pending_move_cost():
	pending_move_cost = -1
	refresh()

# Heals 'hp' without going over total hp.
func heal(hp: int):
	var original_hp = hit_points
	hit_points += hp
	if hit_points > total_hit_points:
		hit_points = total_hit_points
	StatsManager.add(self, Stats.Field.HP_HEALED, hit_points - original_hp)
	refresh()

func heal_full():
	hit_points = total_hit_points
	refresh()

func add_gold(gold: int):
	shared_bag.add_gold(gold)
	StatsManager.add(self, Stats.Field.GOLD_EARNED, gold)

func apply_relic_damage_change(damage: int):
	return relic_manager.apply_damage_change(self, damage)

func apply_damage(damage: int, blockable=true, dodgeable=true):
	StatsManager.add(self, Stats.Field.ATTACKS_RECEIVED, 1)
	# Handle dodge.
	if dodgeable:
		if dodge > 0:
			dodge -= 1
			StatsManager.add(self, Stats.Field.ATTACKS_DODGED, 1)
			refresh()
			return
	if blockable:
		var blocked_damage = 0
		if block > 0:
			if damage <= block:
				block -= damage
				blocked_damage = damage
				damage = 0
			else:
				damage -= block
				blocked_damage = block
				block = 0
		if blocked_damage:
			StatsManager.add(self, Stats.Field.DAMAGE_BLOCKED, blocked_damage)
	StatsManager.add(self, Stats.Field.DAMAGE_TAKEN, damage)
	hit_points -= damage
	if hit_points <= 0:
		return true
	refresh()

# Apply attack from enemy to this character.
func apply_attack(enemy: Enemy):
	var damage = enemy.effective_damage(self)
	apply_damage(damage)

func camp_choices():
	return [camp_choice] + relic_manager.camp_choices()
