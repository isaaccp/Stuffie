extends Resource

class_name StatsStack

@export var stack: Array[Stats]

var overall_stats:
	get: return stack[StatsManager.Level.OVERALL]
var run_stats:
	get: return stack[StatsManager.Level.GAME_RUN]
var stage_stats:
	get: return stack[StatsManager.Level.STAGE]
var turn_stats:
	get: return stack[StatsManager.Level.TURN]

func _init():
	super()
	add_level(StatsManager.Level.OVERALL)

func add_level(level: StatsManager.Level):
	assert(stack.size() == level)
	assert(level != StatsManager.Level.MAX)
	stack.push_back(Stats.new())

func remove_level(level: StatsManager.Level):
	assert((stack.size() - 1) == level)
	# OVERALL aggregation shouldn't be removed.
	assert(stack.size() != 1)
	stack.pop_back()

# This shouldn't be used in general, just temporarily during coding.
func trim_to_level(level: StatsManager.Level):
	print_debug("This function shouldn't be called long-term, remove")
	while stack.size() > level + 1:
		remove_level(stack.size()-1)

func get_level(level: StatsManager.Level):
	assert(level < stack.size())
	return stack[level]

func add(character: Character, field: Stats.Field, value: int):
	print(overall_stats.get_field_name(field), " ", value)
	var character_type = character.character_type
	for level in range(stack.size()):
		stack[level].add(character_type, field, value)

func remove(character: Character, field: Stats.Field, value: int):
	var character_type = character.character_type
	for level in range(stack.size()):
		stack[level].remove(character_type, field, value)

func get_value(level: StatsManager.Level, character: Character, field: Stats.Field) -> int:
	assert(level <= stack.size())
	return stack[level].get_value(character, field)

func print(level: StatsManager.Level):
	assert(level <= stack.size())
	stack[level].print()
