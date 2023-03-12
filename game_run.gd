extends Node

class_name GameRun

var state = StateMachine.new()
var MAP = state.add("map")
var WITHIN_STAGE = state.add("within_stage")
var BETWEEN_STAGES = state.add("between_stages")
var RUN_SUMMARY = state.add("run_summary")

var stage_player_scene = preload("res://stage.tscn")
var between_stages_scene = preload("res://between_stages.tscn")
var run_map_scene = preload("res://run_map.tscn")

var stage_name: String
var stage_impl: Node
var load_stage_from_save = false
var combat_state: CombatSaveState

var run_victory = false

enum StageType {
	COMBAT,
	BLACKSMITH,
	CAMP,
	CARD_REWARD,
}

enum RewardsType {
	NONE,
	REGULAR,
}

class StageDef:
	var stage_type: StageType
	var combat_difficulty: int
	var combat_added_levels: int
	var blacksmith_removals: int
	var blacksmith_upgrades: int
	var blacksmith_relics: int
	var card_reward_options: int

	func _init(stage_type: StageType):
		super()
		self.stage_type = stage_type

	func rewards_type():
		if stage_type == StageType.COMBAT:
			return RewardsType.REGULAR
		return RewardsType.NONE

	static func combat(difficulty: int, added_levels=0) -> StageDef:
		var stage_def = StageDef.new(StageType.COMBAT)
		stage_def.combat_difficulty = difficulty
		stage_def.combat_added_levels = added_levels
		return stage_def

	static func blacksmith(removals: int = 1, upgrades: int = 1, relics: int = 2):
		var stage_def = StageDef.new(StageType.BLACKSMITH)
		stage_def.blacksmith_removals = removals
		stage_def.blacksmith_upgrades = upgrades
		stage_def.blacksmith_relics = relics
		return stage_def

	static func card_reward(options: int = 5):
		var stage_def = StageDef.new(StageType.CARD_REWARD)
		stage_def.card_reward_options = options
		return stage_def

	static func camp():
		return StageDef.new(StageType.CAMP)

var stages  = [
	["4w", "1w_2a"],
	["3w_2a", "cages"],
	["death_wall", "tight_corridor"],
	["death_cage", "corridor"],
	["big_bad_skeleton"],
	["6w_4a"],
	["first_horde"],
]

var blacksmith_scene = preload("res://stages/blacksmith.tscn")
var camp_scene = preload("res://stages/camp.tscn")
var summary_scene = preload("res://run_summary.tscn")

enum RunType {
	REGULAR,
	REGULAR_PLUS,
	REGULAR_PARTY,
	TEST_BLACKSMITH,
	TEST_CAMP,
	TEST_AFTER_STAGE,
}

var run = []

var stage_number = 0
@export var shared_bag: SharedBag
const GOLD_PER_STAGE = 10

var characters: Array[Character]

@export var party: Node
@export var stage_parent: Node
@export var menu: Control
@export var save_and_quit_button: Button
@export var abandon_button: Button

# Whether the last stage requires rewards.
var rewards_type = RewardsType.NONE

var relic_list = preload("res://resources/relic_list.tres").duplicate()
var all_cards = Dictionary()
var run_type: RunType
var added_levels = 0

signal run_finished

func _ready():
	state.connect_signals(self)
	relic_list.reset()

func set_starting_characters(starting_characters: Array[Character]):
	# Improve this character initialization.
	for character in starting_characters:
		var initial_relic = character.initial_relic
		relic_list.mark_used(initial_relic.name)
		character.shared_bag = shared_bag
		character.add_relic(initial_relic, false)
		character.initialize()
		characters.push_back(character)
		party.add_child(character)
		if run_type == RunType.TEST_BLACKSMITH:
			character.deck.cards = character.all_cards.cards
		elif run_type == RunType.TEST_CAMP:
			character.hit_points -= 30

func set_run_type(run_type: RunType):
	self.run_type = run_type
	if run_type == RunType.REGULAR:
		run = [
			StageDef.combat(0),
			StageDef.combat(1),
			StageDef.blacksmith(),
			StageDef.combat(2),
			StageDef.camp(),
			StageDef.combat(3),
			StageDef.blacksmith(),
			StageDef.combat(4),
		]
	elif run_type == RunType.REGULAR_PARTY:
		added_levels = 4
		shared_bag.add_gold(20)
		run = [
			StageDef.combat(2),
			StageDef.combat(3),
			StageDef.blacksmith(2, 2),
			StageDef.combat(5),
			StageDef.camp(),
			StageDef.combat(6),
		]
	elif run_type == RunType.REGULAR_PLUS:
		added_levels = 3
		shared_bag.add_gold(100)
		run = [
			StageDef.card_reward(5),
			StageDef.card_reward(5),
			StageDef.card_reward(5),
			StageDef.blacksmith(4, 4, 3),
			StageDef.combat(0),
			StageDef.combat(1),
			StageDef.blacksmith(),
			StageDef.combat(2),
			StageDef.camp(),
			StageDef.combat(3),
			StageDef.blacksmith(),
			StageDef.combat(4),
		]
	elif run_type == RunType.TEST_BLACKSMITH:
		shared_bag.add_gold(30)
		run = [
			StageDef.blacksmith(),
			StageDef.combat(0),
		]
	elif run_type == RunType.TEST_CAMP:
		run = [
			StageDef.camp(),
			StageDef.combat(0),
		]
	elif run_type == RunType.TEST_AFTER_STAGE:
		run = [
			StageDef.combat(0),
			StageDef.combat(0),
		]
		stages = [
			["fov_test"],
		]

func start():
	state.change_state(MAP)

func current_stage_def():
	return run[stage_number]

func load_stage(stage_name: String) -> Stage:
	var path = "res://stages/" + stage_name + ".stage"
	var scene = load(path) as PackedScene
	var stage = scene.instantiate() as Stage
	return stage

func get_combat_stage(difficulty: int):
	assert(difficulty < stages.size())
	var options = stages[difficulty]
	stage_name = options[randi() % options.size()]
	return load_stage(stage_name)

func get_blacksmith_stage():
	var stage = blacksmith_scene.instantiate() as BlacksmithStage
	return stage

func get_camp_stage():
	var stage = camp_scene.instantiate() as CampStage
	return stage

func get_card_reward_stage():
	var stage = between_stages_scene.instantiate()
	return stage

func _on_within_stage_entered():
	var stage_def = current_stage_def()
	rewards_type = stage_def.rewards_type()
	if load_stage_from_save:
		var stage_player = stage_player_scene.instantiate()
		var stage = load_stage(stage_name)
		stage_parent.add_child(stage_player)
		stage_player.initialize(stage, party, shared_bag, combat_state)
		stage_player.stage_done.connect(stage_finished.bind(StageType.COMBAT))
		stage_player.game_over.connect(game_over)
		stage_impl = stage_player
	else:
		if stage_def.stage_type == StageType.COMBAT:
			StatsManager.add_level(StatsManager.Level.STAGE)
			var stage_player = stage_player_scene.instantiate()
			var stage = get_combat_stage(stage_def.combat_difficulty)
			for enemy in stage.enemies:
				enemy.level += added_levels + stage_def.combat_added_levels
			stage_parent.add_child(stage_player)
			stage_player.initialize(stage, party, shared_bag)
			stage_player.stage_done.connect(stage_finished.bind(StageType.COMBAT))
			stage_player.game_over.connect(game_over)
			stage_impl = stage_player
		elif stage_def.stage_type == StageType.BLACKSMITH:
			var blacksmith = get_blacksmith_stage()
			blacksmith.initialize(characters, shared_bag, relic_list, stage_def.blacksmith_removals, stage_def.blacksmith_upgrades, stage_def.blacksmith_relics)
			blacksmith.stage_done.connect(stage_finished.bind(StageType.BLACKSMITH))
			stage_parent.add_child(blacksmith)
			stage_impl = blacksmith
		elif stage_def.stage_type == StageType.CAMP:
			var camp = get_camp_stage()
			camp.initialize(characters, shared_bag)
			camp.stage_done.connect(stage_finished.bind(StageType.CAMP))
			stage_parent.add_child(camp)
			stage_impl = camp
		elif stage_def.stage_type == StageType.CARD_REWARD:
			var card_reward = get_card_reward_stage()
			card_reward.initialize(characters, shared_bag, stage_def.card_reward_options)
			card_reward.between_stages_done.connect(stage_finished.bind(StageType.CARD_REWARD))
			stage_parent.add_child(card_reward)
			stage_impl = card_reward

func _on_within_stage_exited():
	await TransitionScreen.create(self)
	# If we had restore state from a save, drop it as we have
	# now finished the stage.
	load_stage_from_save = false
	combat_state = null
	for node in stage_parent.get_children():
		node.queue_free()
	if current_stage_def().stage_type == StageType.COMBAT:
		for character in characters:
			# TODO: Consider not destroying the character, just marking it as dead.
			# This would also help with resurrect, etc.
			if is_instance_valid(character):
				character.end_stage()
	stage_number += 1

func _on_between_stages_entered():
	# Possibly just push this into between_stages and
	# handle it there. Or rename "between_stages" to "rewards_stage".
	if rewards_type == RewardsType.NONE:
		state.change_state.call_deferred(MAP)
	else:
		shared_bag.add_gold(GOLD_PER_STAGE)
		for character in characters:
			StatsManager.add(character.character_type, Stats.Field.GOLD_EARNED, GOLD_PER_STAGE/characters.size())
		var between_stages = between_stages_scene.instantiate()
		between_stages.initialize(characters, shared_bag)
		stage_parent.add_child(between_stages)
		between_stages.between_stages_done.connect(state.change_state.bind(MAP))

func _on_between_stages_exited():
	for node in stage_parent.get_children():
		node.queue_free()

func _on_map_entered():
	var run_map = run_map_scene.instantiate() as RunMap
	run_map.initialize(run, stage_number, shared_bag)
	stage_parent.add_child(run_map)
	run_map.done.connect(next_stage)

func _on_map_exited():
	await TransitionScreen.create(self)
	for node in stage_parent.get_children():
		node.queue_free()

func _on_run_summary_entered():
	var summary = summary_scene.instantiate() as RunSummary
	summary.initialize(characters, run_victory)
	stage_parent.add_child(summary)
	summary.done.connect(finish_run)

func _on_run_summary_exited():
	pass

func add_stat(field: Stats.Field, value: int):
	for character in characters:
		StatsManager.add(character.character_type, field, value)

func stage_finished(stage_type: StageType):
	if stage_type == StageType.COMBAT:
		StatsManager.remove_level(StatsManager.Level.STAGE)
		add_stat(Stats.Field.COMBAT_STAGES_FINISHED, 1)
	StatsManager.run_stats.print()
	if stage_number + 1 == run.size():
		add_stat(Stats.Field.RUNS_VICTORY, 1)
		run_victory = true
		state.change_state(RUN_SUMMARY)
	else:
		state.change_state(BETWEEN_STAGES)

func next_stage():
	state.change_state(WITHIN_STAGE)

func game_over():
	StatsManager.remove_level(StatsManager.Level.STAGE)
	add_stat(Stats.Field.RUNS_DEFEAT, 1)
	state.change_state(RUN_SUMMARY)

func finish_run():
	run_finished.emit()

func _input(event):
	# TODO: Implement can_save() in all stage things.
	if Input.is_action_just_released("ui_cancel"):
		var stage = stage_parent.get_child(0)
		if menu.visible:
			menu.hide()
			get_tree().paused = false
		else:
			menu.show()
			save_and_quit_button.disabled = (stage and not stage.can_save())
			get_tree().paused = true

func _on_abandon_run_pressed():
	var stage = stage_parent.get_child(0)
	if stage:
		stage.cleanup()
	menu.hide()
	get_tree().paused = false
	game_over()

func _on_save_quit_pressed():
	var main_game = $/root/MainGame
	main_game.save_game_state()
	get_tree().paused = false
	get_tree().quit()

func get_save_state():
	var run_state = RunSaveState.new()
	run_state.run_type = run_type
	run_state.state = state.current_state_name()
	run_state.stage_number = stage_number
	run_state.gold = shared_bag.gold
	run_state.relic_list = relic_list
	for character in characters:
		run_state.characters.push_back(character.get_save_state())
	if state.is_state(MAP):
		# If we are on map, this is the easiest situation. Just
		# need to restore to map, nothing extra to save.
		pass
	else:
		run_state.stage_type = current_stage_def().stage_type
		match run_state.stage_type:
			StageType.COMBAT:
				run_state.stage_name = stage_name
				run_state.combat_state = stage_impl.get_save_state()
			StageType.BLACKSMITH:
				pass
			StageType.CAMP:
				pass
			StageType.CARD_REWARD:
				pass
	return run_state

func load_save_state(run_state: RunSaveState):
	set_run_type(run_state.run_type)
	stage_number = run_state.stage_number
	shared_bag.gold = run_state.gold
	relic_list = run_state.relic_list
	for character_data in run_state.characters:
		var character = CharacterLoader.restore(character_data)
		character.shared_bag = shared_bag
		characters.push_back(character)
		party.add_child(character)
	match run_state.state:
		MAP.name:
			state.change_state(MAP)
		WITHIN_STAGE.name:
			match run_state.stage_type:
				StageType.COMBAT:
					load_stage_from_save = true
					stage_name = run_state.stage_name
					combat_state = run_state.combat_state
					state.change_state(WITHIN_STAGE)
