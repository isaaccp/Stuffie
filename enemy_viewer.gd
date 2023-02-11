@tool

extends Node

var stage: Stage

var enemy_scenes: Dictionary
var enemies: Array[EnemyPosition] = []
var last_check = 0

func _ready():
	stage = get_parent() as Stage
	enemy_scenes = {
		Stage.EnemyId.SKELETON_WARRIOR: preload("res://skeleton_warrior.tscn"),
	}

func compare(prev_enemies: Array[EnemyPosition], new_enemies: Array[EnemyPosition]):
	if prev_enemies.size() != new_enemies.size():
		return true
	var prev_dict = Dictionary()
	for enemy_pos in prev_enemies:
		prev_dict[enemy_pos.enemy_position] = enemy_pos.enemy_id
	for enemy_pos in new_enemies:
		if prev_dict[enemy_pos.position] != enemy_pos.enemy_id:
			return true
	return false

func _process(delta):
	if Engine.is_editor_hint():
		if (Time.get_ticks_msec() - last_check) > 1000:
			last_check = Time.get_ticks_msec()
			var changed = compare(enemies, stage.enemies)
			if changed:
				for enemy in get_children():
					enemy.queue_free()
				for enemy_position in stage.enemies:
					var enemy = enemy_scenes[enemy_position.enemy_id].instantiate() as Enemy
					enemy.initial_position = enemy_position.position
					add_child(enemy)
