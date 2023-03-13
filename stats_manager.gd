extends Node

var stack: StatsStack

var stats:
	get: return stack
	set(stats): stack = stats
var overall_stats:
	get: return stack.get_level(Enum.StatsLevel.OVERALL)
var run_stats:
	get: return stack.get_level(Enum.StatsLevel.GAME_RUN)
var stage_stats:
	get: return stack.get_level(Enum.StatsLevel.STAGE)
var turn_stats:
	get: return stack.get_level(Enum.StatsLevel.TURN)


signal stats_added(character: Enum.CharacterId, field: Stats.Field, value: int)

func _init():
	super()
	stack = StatsStack.new()

func add_level(level: Enum.StatsLevel):
	stack.add_level(level)

func remove_level(level: Enum.StatsLevel):
	stack.remove_level(level)

func add(character: Enum.CharacterId, field: Stats.Field, value: int):
	stack.add(character, field, value)
	stats_added.emit(character, field, value)

func remove(character: Enum.CharacterId, field: Stats.Field, value: int):
	stack.remove(character, field, value)

func get_value(level: Enum.StatsLevel, character: Enum.CharacterId, field: Stats.Field) -> int:
	return stack.get_value(level, character, field)

func print(level: Enum.StatsLevel):
	stack.print(level)
