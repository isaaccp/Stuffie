extends Node

class_name Stage

enum StageCompletionType {
	KILL_ALL_ENEMIES,
	REACH_POSITION,
	KILL_N_ENEMIES,
	SURVIVE_N_TURNS,
}

var gridmap: GridMap
@export var enemies: Array[EnemyPosition]
@export var doors: Array[DoorDef]
@export var torches: Array[TorchDef]
@export var starting_positions: Array[Vector2i]
@export var stage_completion_type: StageCompletionType
@export var reach_position_target: Vector2i
@export var kill_n_enemies_target: int
@export var survive_n_turns_target: int
@export var triggers: Array[StageTrigger]

@export var solid_tiles: Array[Vector2i]
@export var view_blocking_tiles: Array[Vector2i]
@export var rect: Rect2i

var stage_complete = false
var killed_enemies = 0

signal stage_completed

func _ready():
	# TODO: I was unable to save the gridmap as a exported node path in the stage importer,
	# so need to set it here.
	gridmap = $GridMap

func initialize(enemies_node: Node):
	for enemy_position in enemies:
		var enemy = EnemyLoader.create(enemy_position.enemy_id)
		enemy.initialize(enemy_position.position, enemy_position.level)
		enemies_node.add_child(enemy)

func complete_stage():
	stage_complete = true
	stage_completed.emit()

func get_objective_string() -> String:
	match stage_completion_type:
		StageCompletionType.KILL_ALL_ENEMIES: return "Defeat all enemies"
		StageCompletionType.REACH_POSITION: return "Reach the highlighted location"
		StageCompletionType.KILL_N_ENEMIES: return "Kill %d enemies" % kill_n_enemies_target
		StageCompletionType.SURVIVE_N_TURNS: return "Survive %d turns" % survive_n_turns_target
	assert(false)
	return "Unknown objective"

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
	if turn == (survive_n_turns_target + 1):
		complete_stage()
