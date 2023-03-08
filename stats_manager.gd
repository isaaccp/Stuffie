extends Node

enum Level {
	OVERALL,
	GAME_RUN,
	STAGE,
	TURN,
	MAX,
}

var stack: Array[Stats]

var overall_stats:
	get: return stack[Level.OVERALL]
var run_stats:
	get: return stack[Level.GAME_RUN]
var stage_stats:
	get: return stack[Level.STAGE]
var turn_stats:
	get: return stack[Level.TURN]

signal stats_added(character: Character, field: Stats.Field, value: int)

func _init():
	super()
	add_level(Level.OVERALL)

func add_level(level: Level):
	assert(stack.size() == level)
	assert(level != Level.MAX)
	stack.push_back(Stats.new())

func remove_level(level: Level):
	assert((stack.size() - 1) == level)
	# OVERALL aggregation shouldn't be removed.
	assert(stack.size() != 1)
	stack.pop_back()

func add(character: Character, field: Stats.Field, value: int):
	print(overall_stats.get_field_name(field), " ", value)
	var character_type = character.character_type
	for level in range(stack.size()):
		stack[level].add(character_type, field, value)
	stats_added.emit(character, field, value)

func remove(character: Character, field: Stats.Field, value: int):
	var character_type = character.character_type
	for level in range(stack.size()):
		stack[level].remove(character_type, field, value)

func get_value(level: Level, character: Character, field: Stats.Field) -> int:
	assert(level <= stack.size())
	return stack[level].get_value(character, field)

func print(level: Level):
	assert(level <= stack.size())
	stack[level].print()
