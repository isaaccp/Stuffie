extends RefCounted

class_name EnemyLoader

const enemy_scenes = {
	Enum.EnemyId.SKELETON_WARRIOR: preload("res://skeleton_warrior.tscn"),
	Enum.EnemyId.SKELETON_ARCHER: preload("res://skeleton_archer.tscn"),
	Enum.EnemyId.SKELETON_MAGE: preload("res://skeleton_mage.tscn"),
	Enum.EnemyId.GOBLIN_CROSSBOW: preload("res://crossbow_goblin.tscn"),
}

static func create(enemy_id: Enum.EnemyId) -> Enemy:
	return enemy_scenes[enemy_id].instantiate() as Enemy

static func restore(save_state: EnemySaveState) -> Enemy:
	var enemy = EnemyLoader.create(save_state.enemy_type)
	enemy.load_save_state(save_state)
	return enemy
