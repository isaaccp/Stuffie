extends RefCounted

class_name EnemyTurnManager

var fresh = false
var current_thread = Thread.new()
var enemy_turn: EnemyTurn

var map_manager: MapManager
var effects_node: Node

signal calculated(damage_taken: Array)
signal invalidated
signal enemy_died(enemy: Enemy)

func initialize(map_manager: MapManager, effects_node: Node):
	self.map_manager = map_manager
	self.effects_node = effects_node

func execute_moves(map: MapManager):
	assert(fresh)
	await enemy_turn.execute_moves(map, effects_node)

func update():
	fresh = false
	invalidated.emit()
	if current_thread.is_alive():
		enemy_turn.abort()
	current_thread = Thread.new()
	enemy_turn = EnemyTurn.new(map_manager)
	current_thread.start(_async_enemy_turn.bind(current_thread))

func _async_enemy_turn(thread: Thread):
	var result = enemy_turn.calculate()
	_wait_enemy_turn_completed.bind(thread).call_deferred()
	return result

func _wait_enemy_turn_completed(thread: Thread):
	var thread_id = thread.get_id()
	var current_thread_id = current_thread.get_id()
	var result = thread.wait_to_finish()
	if thread_id == current_thread_id:
		fresh = result
		calculated.emit(enemy_turn.damage_taken)
		enemy_turn.enemy_died.connect(_on_enemy_died)

func _on_enemy_died(enemy: Enemy):
	enemy_died.emit(enemy)
