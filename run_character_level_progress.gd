extends Control

class_name RunCharacterLevelProgress

@export var portrait: CharacterPortrait
@export var label: Label
@export var level_progress_bar: ProgressBar
@export var level_progress_label: Label
@export var unlocked_cards_label: Label
@export var unlocked_cards_container: Container

var initial_delay = 0.25
var xp_per_second = 50.0
var character: Character

var card_ui_scene = preload("res://card_ui.tscn")

# Those are all temporary info to handle the animation.
var new_overall_xp: int
var current_overall_xp: int
var current_level: int

func initialize(character: Character):
	self.character = character
	portrait.set_character(character)

func _ready():
	var run_xp = character.get_stat(Enum.StatsLevel.GAME_RUN, Stats.Field.XP)
	new_overall_xp = character.get_stat(Enum.StatsLevel.OVERALL, Stats.Field.XP)
	current_overall_xp = new_overall_xp - run_xp
	current_level = character.current_unlock_level(current_overall_xp)
	unlocked_cards_label.modulate = Color(1.0, 1.0, 1.0, 0.0)
	tween_xp(initial_delay)

func tween_xp(delay=0.0):
	if current_level == character.max_unlock_level():
		label.text = "All Unlocks Acquired"
		var last_level_xp = character.unlock_threshold(current_level) - (character.unlock_threshold(current_level - 1))
		level_progress_bar.max_value = last_level_xp
		level_progress_bar.value = last_level_xp
	else:
		label.text = "Unlock Level: %d" % current_level
		# First tween should start with a half second delay.
		run_one_level_tween.call_deferred(delay)

func run_one_level_tween(delay):
	var xp_required_for_current_level = character.unlock_threshold(current_level)
	var xp_required_for_next_level = character.unlock_threshold(current_level + 1)
	level_progress_bar.max_value = xp_required_for_next_level - xp_required_for_current_level
	level_progress_bar.value = current_overall_xp - xp_required_for_current_level
	var tw = create_tween()
	tw.tween_interval(delay)
	var level_up = new_overall_xp >= xp_required_for_next_level
	var new_xp: int
	if level_up:
		new_xp = xp_required_for_next_level - xp_required_for_current_level
	else:
		new_xp = new_overall_xp - xp_required_for_current_level
	tw.tween_property(level_progress_bar, "value", new_xp, float(new_xp - level_progress_bar.value) / xp_per_second).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	if level_up:
		# We can already update those variables as we won't use them until the next tween_xp is run.
		current_overall_xp = xp_required_for_next_level
		current_level += 1
		# Show new unlocked cards.
		var new_cards = character.card_collection.cards[current_level]
		var added_cards_ui = []
		for card in new_cards.cards:
			# Only show base cards, not upgrades.
			if card.upgrade_level != 0:
				continue
			var card_ui = card_ui_scene.instantiate() as CardUI
			card_ui.initialize(card, character)
			card_ui.modulate = Color(0.0, 1.0, 0.0, 0.0)
			added_cards_ui.push_back(card_ui)
			tw.tween_callback(unlocked_cards_container.add_child.bind(card_ui))
		if added_cards_ui.size() > 0:
			tw.parallel().tween_property(unlocked_cards_label, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.5)
			for card_ui in added_cards_ui:
				tw.parallel().tween_property(card_ui, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.5)
		# Schedule progress for next level.
		tw.tween_callback(tween_xp)

func update_level_progress_label():
	level_progress_label.text = "%d / %d" % [level_progress_bar.value, level_progress_bar.max_value]

func _process(delta):
	update_level_progress_label()
