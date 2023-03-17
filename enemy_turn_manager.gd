extends RefCounted

class_name EnemyTurnManager

var fresh = false
var current_thread = Thread.new()
var enemy_turn: EnemyTurn

var map_manager: MapManager

signal calculated(damage_taken: Array)
signal invalidated
signal character_died(character: Character)

func initialize(map_manager: MapManager):
	self.map_manager = map_manager

func execute_moves(map: MapManager):
	assert(fresh)
	await enemy_turn.execute_moves(map)

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
		enemy_turn.character_died.connect(_on_character_died)

func _on_character_died(character: Character):
	character_died.emit(character)
