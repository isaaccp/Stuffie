extends Node

enum RunState {
	WITHIN_STAGE,
	BETWEEN_STAGES,
}

var state = null

var stage_player_scene = preload("res://stage.tscn")
var between_stages_scene = preload("res://between_stages.tscn")

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
	[
		preload("res://stages/diff0/stage0_simple.tscn")
	],
	[
		preload("res://stages/diff0/stage0.tscn"),
	],
	[
		preload("res://stages/diff1/stage0.tscn"),
		preload("res://stages/diff1/stage1.tscn"),
	],
]

var blacksmith_scene = preload("res://stages/blacksmith.tscn")

var run = [
	make_combat_stage(0),
	make_blacksmith_stage(),
	make_combat_stage(1),
	make_combat_stage(2),
]

var stage_number = 0

@export var party: Node
@export var stage_parent: Node
# Whether the last stage requires rewards.
var rewards_type = RewardsType.NONE

signal run_finished

func _ready():
	change_state(RunState.WITHIN_STAGE)

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
	
func change_state(new_state: RunState):
	if state == new_state:
		return
	for node in stage_parent.get_children():
		node.queue_free()
	if new_state == RunState.WITHIN_STAGE:
		var stage_def = current_stage_def()
		rewards_type = stage_def.rewards_type()
		if stage_def.stage_type == StageType.COMBAT:
			var stage_player = stage_player_scene.instantiate()
			var stage = get_combat_stage(stage_def.combat_difficulty)
			stage_player.initialize(stage, party)
			stage_player.connect("stage_done", stage_finished)
			stage_parent.add_child(stage_player)
		elif stage_def.stage_type == StageType.BLACKSMITH:
			var blacksmith = get_blacksmith_stage()
			blacksmith.connect("stage_done", stage_finished)
			stage_parent.add_child(blacksmith)
	elif new_state == RunState.BETWEEN_STAGES:
		# Possibly just push this into between_stages and
		# handle it there. Or rename "between_stages" to "rewards_stage".
		if rewards_type == RewardsType.NONE:
			next_stage()
			return
		var between_stages = between_stages_scene.instantiate()
		var characters: Array[Character] = []
		for character in party.get_children():
			character.end_stage()
			characters.push_back(character)
		between_stages.initialize(characters)
		stage_parent.add_child(between_stages)
		between_stages.connect("between_stages_done", next_stage)
		
func stage_finished():
	if stage_number + 1 == run.size():
		run_finished.emit()
	else:
		change_state(RunState.BETWEEN_STAGES)
	
func next_stage():
	stage_number += 1
	change_state(RunState.WITHIN_STAGE)
