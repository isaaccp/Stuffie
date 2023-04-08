extends Unit

class_name Character

@export var character_type: Enum.CharacterId
@export var cards_per_turn: int
@export var initial_relic: Relic
var pending_action_cost: int = -1
var pending_move_cost: int = -1
var relic_manager = RelicManager.new()
var shared_bag: SharedBag
var is_mock = false
# TODO: Remove this. As of now, this is required because character.teleport()
# needs access to the gameplay to e.g. display a cursor for the move, etc.
# Figure out a cleaner way.
var gameplay: Gameplay
var canvas: CanvasLayer

@export var original_deck: Deck
var deck: Deck
@export var extra_cards: CardSelectionSet
@export var all_cards: CardSelectionSet
@export var camp_choice: CampChoice

var card_upgrades: Dictionary
var upgrade_scene = preload("res://card_upgrade.tscn")
var chooser_scene = preload("res://card_collection_chooser.tscn")

signal made_active(active: bool)
signal stage_started(character: Character)
signal stage_ended(character: Character)
signal turn_started(character: Character)
signal turn_ended(character: Character)
signal card_played(character: Character, card: Card)
signal attacked(character: Character)

func _ready():
	super()

func initialize(full=true):
	relic_manager.connect_signals(self)
	process_cards()
	# Used when starting a run, but not when loading.
	if full:
		deck = original_deck.duplicate()
		heal_full()
		end_stage()
	snap()

# Creates a mock of this character to use in turn simulation.
# All the stats that could be needed to simulate an enemy turn
# need to be here. E.g. if we later add relics that prevent damage
# somehow, then we'd need to have the relics here.
func mock():
	var m = Character.new()
	m.character_type = character_type
	m.is_mock = true
	m.id_position = id_position
	m.hit_points = hit_points
	m.total_hit_points = total_hit_points
	m.status_manager = status_manager.clone()
	m.snap()
	return m

func set_canvas(canvas: CanvasLayer):
	self.canvas = canvas

func add_stat(field: Stats.Field, value: int):
	if is_mock:
		return
	StatsManager.add(character_type, field, value)

func get_stat(level: Enum.StatsLevel, field: Stats.Field):
	return StatsManager.get_value(level, character_type, field)

func process_cards():
	for card in all_cards.cards:
		if card.base_card:
			if not card_upgrades.has(card.base_card.card_name):
				card_upgrades[card.base_card.card_name] = []
			card_upgrades[card.base_card.card_name].push_back(card)

func get_card_upgrades(card: Card):
	if not card_upgrades.has(card.card_name):
		return []
	return card_upgrades[card.card_name].duplicate()

func add_relic(relic: Relic, update_stats=true):
	relic_manager.add_relic(relic)
	if update_stats:
		add_stat(Stats.Field.RELICS_ACQUIRED, 1)

func add_temp_relic(relic: Relic):
	relic_manager.add_temp_relic(relic)

func begin_stage(gameplay: Gameplay):
	self.gameplay = gameplay
	deck.reset()
	end_turn()
	stage_started.emit(self)

func end_stage():
	gameplay = null
	action_points = total_action_points
	move_points = total_move_points
	status_manager.clear()
	deck.reset()
	clear_pending_move_cost()
	clear_pending_action_cost()
	clear_pending_damage()
	stage_ended.emit(self)
	relic_manager.clear_temp_relics()
	changed.emit()

func begin_turn():
	super()
	turn_started.emit(self)
	changed.emit()

func end_turn():
	snap()
	super()
	draw_new_hand()
	action_points = total_action_points
	turn_ended.emit(self)

func discard_hand():
	var discarded = deck.discard_hand()
	add_stat(Stats.Field.DISCARDED_CARDS, discarded)

func num_hand_cards():
	if deck:
		return deck.num_hand_cards()
	return 0

func draw_new_hand():
	deck.discard_hand()
	deck.draw_cards(cards_per_turn)

func draw_cards(number: int, metadata: CardEffectMetadata):
	# TODO: Allow using metadata to apply card changes.
	var drawn = deck.draw_cards(number)
	add_stat(Stats.Field.EXTRA_CARDS_DRAWN, drawn)

func draw_attacks(number: int, metadata: CardEffectMetadata):
	# TODO: Allow using metadata to apply card changes.
	var drawn = deck.draw_attacks(number)
	add_stat(Stats.Field.EXTRA_CARDS_DRAWN, drawn)

func pick_cards_condition(number: int, metadata: CardEffectMetadata, condition: Callable = func(c): return true):
	# TODO: Support picking more than 1.
	assert(number == 1)
	# Shuffle discard into deck before choosing.
	deck.shuffle_discard()
	var chooser = chooser_scene.instantiate() as CardCollectionChooser
	chooser.initialize_from_character(self, CardCollectionChooser.Filter.DECK, condition)
	chooser.set_skippable()
	canvas.add_child(chooser)
	get_tree().paused = true
	await chooser.card_chosen
	get_tree().paused = false
	var card = chooser.chosen_card
	if card != null:
		if metadata.original_card_change:
			card.apply_card_change(metadata.original_card_change)
		deck.add_to_hand_from_deck(card)
		add_stat(Stats.Field.EXTRA_CARDS_DRAWN, number)
	chooser.queue_free()

func pick_cards(number: int, metadata: CardEffectMetadata):
	pick_cards_condition(number, metadata)

func pick_attacks(number: int, metadata: CardEffectMetadata):
	await pick_cards_condition(number, metadata, func(c): return c.is_attack())

func upgrade_cards(number: int):
	# TODO: Support upgrading more than 1 in CardUpgrade.
	assert(number == 1)
	var upgrade = upgrade_scene.instantiate() as CardUpgrade
	upgrade.initialize([self])
	canvas.add_child(upgrade)
	get_tree().paused = true
	await upgrade.done
	get_tree().paused = false
	upgrade.queue_free()
	# TODO: Check if we actually upgraded.
	add_stat(Stats.Field.CARDS_UPGRADED, number)

func duplicate_cards(number: int, metadata: CardEffectMetadata):
	var chooser = chooser_scene.instantiate() as CardCollectionChooser
	chooser.initialize_from_character(self, CardCollectionChooser.Filter.HAND, Card.filter_condition(metadata.card_filter))
	chooser.set_skippable()
	canvas.add_child(chooser)
	get_tree().paused = true
	await chooser.card_chosen
	get_tree().paused = false
	var card = chooser.chosen_card
	if card != null:
		var card_copy = card.duplicate()
		if metadata.original_card_change:
			card.apply_card_change(metadata.original_card_change)
		for i in range(number):
			var new_card = card_copy.duplicate()
			if metadata.copied_card_change:
				new_card.apply_card_change(metadata.copied_card_change)
			deck.add_to_hand(new_card)
	chooser.queue_free()

func teleport(distance: int):
	await gameplay.teleport(self, distance)

func set_active(active: bool):
	made_active.emit(active)

func set_pending_action_cost(pending_cost: int):
	pending_action_cost = pending_cost
	changed.emit()

func clear_pending_action_cost():
	pending_action_cost = -1
	changed.emit()

func reduce_move(move_cost: int):
	move_points -= move_cost
	changed.emit()

func set_pending_move_cost(pending_cost: int):
	pending_move_cost = pending_cost
	changed.emit()

func clear_pending_move_cost():
	pending_move_cost = -1
	changed.emit()

func add_gold(gold: int):
	shared_bag.add_gold(gold)
	add_stat(Stats.Field.GOLD_EARNED, gold)

func apply_relic_damage_change(damage: int):
	return relic_manager.apply_damage_change(self, damage)

func camp_choices():
	return [camp_choice] + relic_manager.camp_choices()

func move(map_manager: MapManager, to: Vector2i):
	var from = get_id_position()
	var curve = map_manager.curve_from_path(map_manager.get_path(from, to))
	await move_path(curve)
	set_id_position(to)
	map_manager.move_character(from, to)

func on_move_map_update(map_manager: MapManager, from: Vector2i, to: Vector2i):
	map_manager.move_character(from, to)

func get_save_state():
	var save_state = CharacterSaveState.new()
	save_state.character_type = character_type
	save_state.id_position = get_id_position()
	save_state.total_action_points = total_action_points
	save_state.total_move_points = total_move_points
	save_state.total_hit_points = total_hit_points
	save_state.cards_per_turn = cards_per_turn
	save_state.action_points = action_points
	save_state.move_points = move_points
	save_state.hit_points = hit_points
	save_state.is_destroyed = is_destroyed
	save_state.relic_manager = relic_manager
	save_state.status_manager = status_manager
	save_state.deck = deck
	return save_state

func load_save_state(save_state: CharacterSaveState):
	set_id_position(save_state.id_position)
	total_action_points = save_state.total_action_points
	total_move_points = save_state.total_move_points
	total_hit_points = save_state.total_hit_points
	cards_per_turn = save_state.cards_per_turn
	action_points = save_state.action_points
	move_points = save_state.move_points
	hit_points = save_state.hit_points
	is_destroyed = save_state.is_destroyed
	relic_manager = save_state.relic_manager
	status_manager = save_state.status_manager
	deck = save_state.deck
	initialize(false)
