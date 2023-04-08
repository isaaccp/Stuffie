extends RefCounted

class_name CardSimulationManager

var fresh = false
var current_thread = Thread.new()
var card_simulation: CardSimulation

var map_manager: MapManager

signal calculated(damage_taken: Array)
signal invalidated

func initialize(map_manager: MapManager):
	self.map_manager = map_manager

func update(character_pos: Vector2i, card: Card, target_tile: Vector2i, direction: Vector2):
	print("Updating card simulation manager")
	fresh = false
	invalidated.emit()
	if current_thread.is_alive():
		card_simulation.abort()
	current_thread = Thread.new()
	card_simulation = CardSimulation.new(map_manager, character_pos, card, target_tile, direction)
	current_thread.start(_async_card_simulation.bind(current_thread))

func stop():
	print("Stopping card simulation manager")
	invalidated.emit()
	if current_thread.is_alive():
		card_simulation.abort()

func _async_card_simulation(thread: Thread):
	var result = card_simulation.calculate()
	_wait_card_simulation_completed.bind(thread).call_deferred()
	return result

func _wait_card_simulation_completed(thread: Thread):
	var thread_id = thread.get_id()
	var current_thread_id = current_thread.get_id()
	var result = thread.wait_to_finish()
	if thread_id == current_thread_id:
		fresh = result
		calculated.emit(card_simulation.damage_taken)
