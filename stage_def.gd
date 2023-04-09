extends RefCounted

class_name StageDef

enum StageType {
	COMBAT,
	BLACKSMITH,
	CAMP,
	CARD_REWARD,
	CHARACTER,
	EVENT,
}

enum RewardsType {
	NONE,
	REGULAR,
}

var stage_type: StageType
var combat_difficulty: int
var combat_added_levels: int
var blacksmith_removals: int
var blacksmith_upgrades: int
var blacksmith_relics: int
var card_reward_options: int

func rewards_type():
	if stage_type == StageType.COMBAT:
		return RewardsType.REGULAR
	return RewardsType.NONE

static func combat(difficulty: int, added_levels=0) -> StageDef:
	var stage_def = StageDef.new()
	stage_def.stage_type = StageType.COMBAT
	stage_def.combat_difficulty = difficulty
	stage_def.combat_added_levels = added_levels
	return stage_def

static func blacksmith(removals: int = 1, upgrades: int = 1, relics: int = 2):
	var stage_def = StageDef.new()
	stage_def.stage_type = StageType.BLACKSMITH
	stage_def.blacksmith_removals = removals
	stage_def.blacksmith_upgrades = upgrades
	stage_def.blacksmith_relics = relics
	return stage_def

static func card_reward(options: int = 5):
	var stage_def = StageDef.new()
	stage_def.stage_type = StageType.CARD_REWARD
	stage_def.card_reward_options = options
	return stage_def

static func camp():
	var stage_def = StageDef.new()
	stage_def.stage_type = StageType.CAMP
	return stage_def

static func character():
	var stage_def = StageDef.new()
	stage_def.stage_type = StageType.CHARACTER
	return stage_def

static func event():
	var stage_def = StageDef.new()
	stage_def.stage_type = StageType.EVENT
	return stage_def
