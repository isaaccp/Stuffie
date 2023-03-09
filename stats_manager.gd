extends Node

enum Level {
	OVERALL,
	GAME_RUN,
	STAGE,
	TURN,
	MAX,
}

var stack: StatsStack

var stats:
	get: return stack
	set(stats): stack = stats
var overall_stats:
	get: return stack.get_level(Level.OVERALL)
var run_stats:
	get: return stack.get_level(Level.GAME_RUN)
var stage_stats:
	get: return stack.get_level(Level.STAGE)
var turn_stats:
	get: return stack.get_level(Level.TURN)


signal stats_added(character: Character, field: Stats.Field, value: int)

func _init():
	super()
	stack = StatsStack.new()

func add_level(level: Level):
	stack.add_level(level)

func remove_level(level: Level):
	stack.remove_level(level)

func add(character: Character, field: Stats.Field, value: int):
	stack.add(character, field, value)
	stats_added.emit(character, field, value)

func remove(character: Character, field: Stats.Field, value: int):
	stack.remove(character, field, value)

func get_value(level: Level, character: Character, field: Stats.Field) -> int:
	return stack.get_value(level, character, field)

func print(level: Level):
	stack.print(level)
