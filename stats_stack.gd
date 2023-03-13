extends Resource

class_name StatsStack

@export var stack: Array[Stats]

var overall_stats:
	get: return stack[Enum.StatsLevel.OVERALL]
var run_stats:
	get: return stack[Enum.StatsLevel.GAME_RUN]
var stage_stats:
	get: return stack[Enum.StatsLevel.STAGE]
var turn_stats:
	get: return stack[Enum.StatsLevel.TURN]

func _init():
	super()
	add_level(Enum.StatsLevel.OVERALL)

func add_level(level: Enum.StatsLevel):
	assert(stack.size() == level)
	assert(level != Enum.StatsLevel.MAX)
	stack.push_back(Stats.new())

func remove_level(level: Enum.StatsLevel):
	assert((stack.size() - 1) == level)
	# OVERALL aggregation shouldn't be removed.
	assert(stack.size() != 1)
	stack.pop_back()

# This shouldn't be used in general, just temporarily during coding.
func trim_to_level(level: Enum.StatsLevel):
	print_debug("This function shouldn't be called long-term, remove")
	while stack.size() > level + 1:
		remove_level(stack.size()-1)

func get_level(level: Enum.StatsLevel):
	assert(level < stack.size())
	return stack[level]

func add(character: Enum.CharacterId, field: Stats.Field, value: int):
	print(overall_stats.get_field_name(field), " ", value)
	for level in range(stack.size()):
		stack[level].add(character, field, value)

func remove(character: Enum.CharacterId, field: Stats.Field, value: int):
	for level in range(stack.size()):
		stack[level].remove(character, field, value)

func get_value(level: Enum.StatsLevel, character: Enum.CharacterId, field: Stats.Field) -> int:
	assert(level <= stack.size())
	return stack[level].get_value(character, field)

func print(level: Enum.StatsLevel):
	assert(level <= stack.size())
	stack[level].print()
