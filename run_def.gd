extends Resource

class_name RunDef

enum RunType {
	REGULAR,
	REGULAR_PLUS,
	REGULAR_PARTY,
	TEST_BLACKSMITH,
	TEST_CAMP,
	TEST_AFTER_STAGE,
}

var levels: Array
var added_levels: int = 0
var shared_bag_gold: int = 0
var stages: Array

func get_level(level: int):
	return levels[level]

func get_stage(level: int, stage: int):
	return levels[level].get_stage(stage)

static func get_run(run_type: RunType):
	var run_def = RunDef.new()
	run_def.stages  = [
		["4w", "1w_2a"],
		["3w_2a", "cages"],
		["death_wall", "tight_corridor"],
		["death_cage", "corridor"],
		["big_bad_skeleton"],
		["6w_4a"],
		["first_horde"],
	]
	match run_type:
		RunType.REGULAR:
			run_def.levels = [
				RunLevelDef.create([
					StageDef.combat(0),
					StageDef.combat(1),
					StageDef.blacksmith(),
					StageDef.combat(2),
					StageDef.camp(),
					StageDef.combat(3),
					StageDef.blacksmith(),
					StageDef.character(),
					StageDef.combat(4),
				]),
				RunLevelDef.create([
					StageDef.combat(5),
					StageDef.blacksmith(),
					StageDef.combat(6),
				]),
			]
		RunType.REGULAR_PARTY:
			run_def.added_levels = 4
			run_def.shared_bag_gold = 20
			run_def.levels = [
				RunLevelDef.create([
					StageDef.combat(2),
					StageDef.combat(3),
					StageDef.blacksmith(2, 2),
					StageDef.combat(5),
					StageDef.camp(),
					StageDef.combat(6),
				]),
			]
		RunType.REGULAR_PLUS:
			run_def.added_levels = 3
			run_def.shared_bag_gold = 100
			run_def.levels = [
				RunLevelDef.create([
					StageDef.card_reward(5),
					StageDef.card_reward(5),
					StageDef.card_reward(5),
					StageDef.blacksmith(4, 4, 3),
					StageDef.combat(0),
					StageDef.combat(1),
					StageDef.blacksmith(),
					StageDef.combat(2),
					StageDef.camp(),
					StageDef.combat(3),
					StageDef.blacksmith(),
					StageDef.combat(4),
				]),
			]
		RunType.TEST_BLACKSMITH:
			run_def.shared_bag_gold = 30
			run_def.levels = [
				RunLevelDef.create([
					StageDef.blacksmith(),
					StageDef.combat(0),
				]),
			]
		RunType.TEST_CAMP:
			run_def.levels = [
				RunLevelDef.create([
					StageDef.camp(),
					StageDef.combat(0),
				]),
			]
		RunType.TEST_AFTER_STAGE:
			run_def.levels = [
				RunLevelDef.create([
					StageDef.combat(0),
					StageDef.character(),
					StageDef.combat(0),
				]),
				#RunLevelDef.create([
				#	StageDef.combat(0),
				#]),
			]
			run_def.stages = [
				["simple"],
			]
	return run_def
