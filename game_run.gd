extends Node

enum RunState {
	WITHIN_STAGE,
	BETWEEN_STAGES,
}

var state = null

var stage_scene = preload("res://stuffie3d.tscn")
var between_stages_scene = preload("res://between_stages.tscn")

func _ready():
	change_state(RunState.WITHIN_STAGE)

func change_state(new_state: RunState):
	if state == new_state:
		return
	for node in get_children():
		node.queue_free()
	if new_state == RunState.WITHIN_STAGE:
		var stage = stage_scene.instantiate()
		add_child(stage)
		# TODO: Connect stage finished signal.
	elif new_state == RunState.BETWEEN_STAGES:
		var between_stages = between_stages_scene.instantiate()
		add_child(between_stages)
		# TODO: Implement and connect signal to go back to next stage.
