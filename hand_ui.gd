extends Control

class_name HandUI

var character: Character
var card_ui_scene = preload("res://card_ui.tscn")
var disabled = false

var selected_card: Card
var selected_index: int

var animation_finished: Signal
var needs_description_refresh = false

const card_size = Vector2(220, 320)
const separator = 15

signal card_selected(card: Card)

func _ready():
	custom_minimum_size.y = card_size.y
	StatsManager.stats_added.connect(_on_stats_added)

func _process(delta: float):
	if needs_description_refresh:
		update_descriptions()
		needs_description_refresh = false

func reset(character: Character):
	if self.character:
		disconnect_deck(character)
	connect_deck(character)
	self.character = character
	recreate()

func connect_deck(character: Character):
	character.deck.cards_added.connect(_on_cards_drawn)
	character.deck.card_discarded.connect(_on_card_discarded)
	character.deck.card_exhausted.connect(_on_card_exhausted)
	character.deck.discarded.connect(_on_hand_discarded)

func disconnect_deck(character: Character):
	character.deck.cards_added.disconnect(_on_cards_drawn)
	character.deck.card_discarded.disconnect(_on_card_discarded)
	character.deck.card_exhausted.disconnect(_on_card_exhausted)
	character.deck.discarded.disconnect(_on_hand_discarded)

func _on_stats_added(character: Enum.CharacterId, field: Stats.Field, value: int):
	# Anything that changes stats may require a description update.
	needs_description_refresh = true

func _on_cards_drawn(number: int):
	for i in range(get_card_count(), get_card_count() + number):
		add_card(character.deck.hand[i])

func _on_card_discarded(index: int):
	remove_card(index)

func _on_card_exhausted(index: int):
	remove_card(index)

func _on_hand_discarded():
	recreate()

func recreate():
	clear()
	for i in character.deck.hand.size():
		var card = character.deck.hand[i]
		add_card(card)

func reindex():
	for card in get_children():
		card.pressed.disconnect(_on_card_pressed)
	var i = 0
	for card in get_children():
		card.pressed.connect(_on_card_pressed.bind(i))
		i += 1

func add_card(card: Card):
	var new_card = card_ui_scene.instantiate() as CardUI
	new_card.initialize(card, character)
	new_card.pressed.connect(_on_card_pressed.bind(get_child_count()))
	add_child(new_card)
	update_positions()

func remove_selected():
	var index = selected_index
	selected_card = null
	selected_index = -1
	remove_card(index)

func remove_card(index: int):
	var card = get_child(index)
	card.set_removed(true)
	animation_finished = remove_card_animation(index)
	await animation_finished
	animation_finished = Signal()
	remove_child(card)
	card.queue_free()
	reindex()
	update_positions()

func remove_card_animation(index: int):
	var card = get_child(index)
	var new_pos = calculate_new_card_positions()
	var tw = create_tween()
	tw.parallel().tween_property(card, "position", Vector2.UP * 320, 1.0).as_relative()
	tw.parallel().tween_property(card, "modulate", Color(1.0, 0.0, 1.0, 0), 1.0)
	var i = 0
	for pos in new_pos:
		if i == index:
			i += 1
		tw.parallel().tween_property(get_child(i), "position", pos, 0.75)
		i += 1

	return tw.finished

func get_card_count():
	var removed = 0
	for card in get_children():
		if card.removed:
			removed += 1
	return get_child_count() - removed

func calculate_new_card_positions():
	var center = 0
	var card_count = get_card_count()
	var total_x = card_count * card_size.x + (card_count - 1) * separator
	var start_x = -float(total_x)/2.0
	var i = 0
	var positions = []
	for card in get_children():
		if get_child(i).removed:
			i += 1
			continue
		positions.push_back(Vector2(start_x, 0))
		start_x += (card_size.x + separator)
		i += 1
	return positions

func update_positions():
	var positions = calculate_new_card_positions()
	var i = 0
	for pos in positions:
		if get_child(i).removed:
			i += 1
			continue
		get_child(i).position = pos
		i += 1

func update_descriptions():
	for card in get_children():
		if not card.removed:
			card.refresh()

func unselect():
	if selected_index != -1:
		get_child(selected_index).set_selected(false)
	selected_index = -1
	selected_card = null

func clear():
	for card in get_children():
		remove_child(card)
		card.queue_free()

func _on_card_pressed(index: int):
	if not disabled:
		if selected_index != -1:
			get_child(selected_index).set_selected(false)

		var card = character.deck.hand[index]
		if card.cost <= character.action_points:
			selected_index = index
			selected_card= card
			get_child(index).set_selected(true)
			card_selected.emit(selected_card)
