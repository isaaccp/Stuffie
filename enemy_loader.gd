extends RefCounted

class_name EnemyLoader

const enemy_scenes = {
	Enum.EnemyId.SKELETON_WARRIOR: preload("res://skeleton_warrior.tscn"),
	Enum.EnemyId.SKELETON_ARCHER: preload("res://skeleton_archer.tscn"),
}

static func create(enemy_id: Enum.EnemyId) -> Enemy:
	return enemy_scenes[enemy_id].instantiate() as Enemy

static func restore(save_state: EnemySaveState) -> Enemy:
	var enemy = EnemyLoader.create(save_state.enemy_type)
	enemy.set_id_position(save_state.id_position)
	enemy.total_move_points = save_state.total_move_points
	enemy.total_hit_points = save_state.total_hit_points
	enemy.total_damage = save_state.total_damage
	enemy.total_attack_range = save_state.total_attack_range
	enemy.level = save_state.level
	enemy.move_points = save_state.move_points
	enemy.hit_points = save_state.hit_points
	enemy.weakness = save_state.weakness
	enemy.paralysis = save_state.paralysis
	enemy.vulnerability = save_state.vulnerability
	return enemy
