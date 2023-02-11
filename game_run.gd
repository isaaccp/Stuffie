extends Node

enum RunState {
	WITHIN_STAGE,
	BETWEEN_STAGES,
}

var state = null

var stage_scene = preload("res://stage.tscn")
var between_stages_scene = preload("res://between_stages.tscn")

var stage_number = 0
var max_stage = 3

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
		stage_parent.add_child(between_stages)
		between_stages.connect("between_stages_done", next_stage)

func stage_finished():
	change_state(RunState.BETWEEN_STAGES)
	
func next_stage():
	stage_number += 1
	if stage_number < max_stage:
		change_state(RunState.WITHIN_STAGE)
	else:
		run_finished.emit()
