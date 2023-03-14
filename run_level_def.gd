extends Resource

class_name RunLevelDef

var stages: Array[StageDef]

func get_stage(stage: int):
	return stages[stage]

static func create(stages: Array[StageDef]) -> RunLevelDef:
	var level = RunLevelDef.new()
	level.stages = stages
	return level
