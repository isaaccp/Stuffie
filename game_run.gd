extends Node

enum RunState {
	WITHIN_STAGE,
	BETWEEN_STAGES,
}

var state = null

var stage_player_scene = preload("res://stage.tscn")
var between_stages_scene = preload("res://between_stages.tscn")

var stages = [
	[
		preload("res://stages/diff0/stage0.tscn"),
	],
	[
		preload("res://stages/diff1/stage0.tscn"),
		preload("res://stages/diff1/stage1.tscn"),
	],
]

var stage_number = 0

@export var party: Node
@export var stage_parent: Node

signal run_finished

func _ready():
	change_state(RunState.WITHIN_STAGE)

func change_state(new_state: RunState):
	if state == new_state:
		return
	for node in stage_parent.get_children():
		node.queue_free()
	if new_state == RunState.WITHIN_STAGE:
		var stage_player = stage_player_scene.instantiate()
		var current_stages = stages[stage_number]
		var stage = current_stages[randi() % current_stages.size()].instantiate() as Stage
		stage_player.initialize(stage, party)
		stage_player.connect("stage_done", stage_finished)
		stage_parent.add_child(stage_player)
	elif new_state == RunState.BETWEEN_STAGES:
		var between_stages = between_stages_scene.instantiate()
		var characters: Array[Character] = []
		for character in party.get_children():
			character.end_stage()
			characters.push_back(character)
		between_stages.initialize(characters)
		stage_parent.add_child(between_stages)
		between_stages.connect("between_stages_done", next_stage)
		
func stage_finished():
	if stage_number + 1 == stages.size():
		run_finished.emit()
	else:
		change_state(RunState.BETWEEN_STAGES)
	
func next_stage():
	stage_number += 1
	change_state(RunState.WITHIN_STAGE)
