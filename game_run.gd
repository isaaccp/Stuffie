extends Node

class_name GameRun

var state = StateMachine.new()
var MAP = state.add("map")
var WITHIN_STAGE = state.add("within_stage")
var BETWEEN_STAGES = state.add("between_stages")

var stage_player_scene = preload("res://stage.tscn")
var between_stages_scene = preload("res://between_stages.tscn")
var run_map_scene = preload("res://run_map.tscn")

enum StageType {
	COMBAT,
	BLACKSMITH,
}

enum RewardsType {
	NONE,
	REGULAR,
}

class StageDef:
	var stage_type: StageType
	var combat_difficulty: int

	func _init(stage_type: StageType):
		super()
		self.stage_type = stage_type

	func rewards_type():
		if stage_type == StageType.COMBAT:
			return RewardsType.REGULAR
		return RewardsType.NONE

func make_combat_stage(difficulty: int):
	var stage_def = StageDef.new(StageType.COMBAT)
	stage_def.combat_difficulty = difficulty
	return stage_def

func make_blacksmith_stage():
	return StageDef.new(StageType.BLACKSMITH)

var stages = [
	# Super simple stage for easy testing of stage transitions, etc.
	# [ preload("res://stages/diff0/stage_simple.stage")],
	[
		preload("res://stages/4w.stage"),
		preload("res://stages/1w_2a.stage"),
	],
	[
		preload("res://stages/3w_2a.stage"),
		preload("res://stages/cages.stage"),
	],
	[
		preload("res://stages/death_wall.stage"),
		preload("res://stages/tight_corridor.stage"),
	],
	[
		preload("res://stages/death_cage.stage"),
		preload("res://stages/corridor.stage"),
	],
	[
		preload("res://stages/big_bad_skeleton.stage"),
	],
]

var blacksmith_scene = preload("res://stages/blacksmith.tscn")

enum RunType {
	REGULAR,
	TEST_BLACKSMITH,
}

var run = []

var stage_number = 0
@export var shared_bag: SharedBag
const GOLD_PER_STAGE = 15

var characters: Array[Character]

@export var party: Node
@export var stage_parent: Node
# Whether the last stage requires rewards.
var rewards_type = RewardsType.NONE

var relic_list = preload("res://resources/relic_list.tres")
var all_cards = Dictionary()
var run_type: RunType

signal run_finished

func _ready():
	state.connect_signals(self)
	for character in party.get_children():
		var initial_relic = character.initial_relic
		relic_list.mark_used(initial_relic.name)
		character.add_relic(initial_relic)
		characters.push_back(character)
		if run_type == RunType.TEST_BLACKSMITH:
			character.deck.cards = character.all_cards.cards
	state.change_state(MAP)

func set_run_type(run_type: RunType):
	self.run_type = run_type
	if run_type == RunType.REGULAR:
		run = [
			make_combat_stage(0),
			make_combat_stage(1),
			make_blacksmith_stage(),
			make_combat_stage(2),
			make_combat_stage(3),
			make_blacksmith_stage(),
			make_combat_stage(4),
		]
	elif run_type == RunType.TEST_BLACKSMITH:
		shared_bag.add_gold(30)
		run = [
			make_blacksmith_stage(),
			make_combat_stage(0),
		]

func current_stage_def():
	return run[stage_number]

func get_combat_stage(difficulty: int):
	assert(difficulty < stages.size())
	var options = stages[difficulty]
	var stage = options[randi() % options.size()].instantiate() as Stage
	return stage

func get_blacksmith_stage():
	var stage = blacksmith_scene.instantiate() as BlacksmithStage
	return stage

func _on_within_stage_entered():
	var stage_def = current_stage_def()
	rewards_type = stage_def.rewards_type()
	if stage_def.stage_type == StageType.COMBAT:
		var stage_player = stage_player_scene.instantiate()
		var stage = get_combat_stage(stage_def.combat_difficulty)
		stage_player.initialize(stage, party, shared_bag)
		stage_player.stage_done.connect(stage_finished)
		stage_player.game_over.connect(game_over)
		stage_parent.add_child(stage_player)
	elif stage_def.stage_type == StageType.BLACKSMITH:
		var blacksmith = get_blacksmith_stage()
		blacksmith.initialize(characters, shared_bag, relic_list)
		blacksmith.stage_done.connect(stage_finished)
		stage_parent.add_child(blacksmith)

func _on_within_stage_exited():
	for node in stage_parent.get_children():
		node.queue_free()
	if current_stage_def().stage_type == StageType.COMBAT:
		for character in characters:
			character.end_stage()
	stage_number += 1

func _on_between_stages_entered():
	# Possibly just push this into between_stages and
	# handle it there. Or rename "between_stages" to "rewards_stage".
	if rewards_type == RewardsType.NONE:
		state.change_state.call_deferred(MAP)
	else:
		var between_stages = between_stages_scene.instantiate()
		between_stages.initialize(characters)
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
	for node in stage_parent.get_children():
		node.queue_free()

func stage_finished():
	if stage_number + 1 == run.size():
		run_finished.emit()
	else:
		shared_bag.add_gold(GOLD_PER_STAGE)
		state.change_state(BETWEEN_STAGES)

func next_stage():
	state.change_state(WITHIN_STAGE)

func game_over():
	run_finished.emit()
