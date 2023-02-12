extends Node

enum RunState {
	WITHIN_STAGE,
	BETWEEN_STAGES,
}

var state = null

var stage_scene = preload("res://stage.tscn")
var between_stages_scene = preload("res://between_stages.tscn")

var stage_number = 0
# This needs to be in sync with gameplay.gd number of stages,
# but eventually it'll be reworked so it's fine for now.
var max_stage = 2

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
		var stage = stage_scene.instantiate()
		stage.initialize(stage_number, party)
		stage.connect("stage_done", stage_finished)
		stage_parent.add_child(stage)
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
	if stage_number == max_stage:
		run_finished.emit()
	else:
		change_state(RunState.BETWEEN_STAGES)
	
func next_stage():
	stage_number += 1
	change_state(RunState.WITHIN_STAGE)
