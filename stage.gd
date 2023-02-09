extends Node

class_name Stage

enum StageCompletionType {
	KILL_ALL_ENEMIES,
	REACH_POSITION,
	KILL_N_ENEMIES,
	SURVIVE_N_TURNS,
}

@export var gridmap: GridMap
@export var starting_positions: Array
# TODO: Display information about how to complete stage in UI.
@export var stage_completion_type: StageCompletionType
@export var reach_position_target: Vector2i
@export var kill_n_enemies_target: int
@export var survive_n_turns_target: int

var stage_complete = false
var killed_enemies = 0

signal stage_completed

func complete_stage():
	stage_complete = true
	stage_completed.emit()
	
func enemy_died_handler():
	if stage_complete:
		return
	if stage_completion_type != StageCompletionType.KILL_N_ENEMIES:
		return
	killed_enemies += 1
	if killed_enemies >= kill_n_enemies_target:
		complete_stage()
	
func character_moved_handler(pos: Vector2i):
	if stage_complete:
		return
	if stage_completion_type != StageCompletionType.REACH_POSITION:
		return
	if pos == reach_position_target:
		complete_stage()
	
func all_enemies_died_handler():
	if stage_complete:
		return
	if stage_completion_type != StageCompletionType.KILL_ALL_ENEMIES:
		return
	complete_stage()
	
func new_turn_started_handler(turn: int):
	if stage_complete:
		return
	if stage_completion_type != StageCompletionType.SURVIVE_N_TURNS:
		return
	if turn == survive_n_turns_target:
		complete_stage()
