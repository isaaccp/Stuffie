extends Unit

class_name Enemy

enum AttackStyle {
	FIRE,
}

@export var base_move_points: int
@export var base_hit_points: int
@export var base_damage: int
@export var base_attack_range: int

@export var level_move_points: float
@export var level_hit_points: float
@export var level_damage: float
@export var level_attack_range: float

var total_move_points: int
var total_damage: int
var total_attack_range: int

var level: int
var move_points: float
var weakness: int
var paralysis: int
# TODO: Implement effect of this.
var vulnerability: int
var done: bool

var is_mock = false

@export var enemy_type: Enum.EnemyId
@export var enemy_name: String
@export var health_bar: HealthDisplay3D
@export var attack_style: AttackStyle
@export var weapon: Node3D

# Called when the node enters the scene tree for the first time.
func _ready():
	# For fireable weapons, hide them until attack.
	if attack_style == AttackStyle.FIRE:
		if weapon:
			weapon.hide()

func mock():
	var m = Enemy.new()
	m.is_mock = true
	m.id_position = id_position
	m.total_move_points = total_move_points
	m.total_damage = total_damage
	m.total_attack_range = total_attack_range
	return m

func initialize(pos: Vector2i, level: int):
	self.level = level
	total_move_points = int(base_move_points + level*level_move_points)
	total_hit_points = int(base_hit_points + level*level_hit_points)
	total_damage = int(base_damage + level*level_damage)
	total_attack_range = int(base_attack_range + level*level_attack_range)

	hit_points = total_hit_points
	set_id_position(pos)
	end_turn()

func end_turn():
	move_points = total_move_points
	if weakness > 0:
		weakness -= 1
	if vulnerability > 0:
		vulnerability -= 1
	if paralysis > 0:
		paralysis -= 1

func info_text() -> String:
	var damage_text = "%s" % total_damage
	if total_damage != effective_damage(null):
		damage_text = "%s ([color=red]%s[/color])" % [total_damage, effective_damage(null)]
	var format_vars = {
		"name": enemy_name,
		"level": level,
		"damage": damage_text,
		"attack_range": total_attack_range,
		"move_points": move_points,
		"total_move_points": total_move_points,
		"hit_points": hit_points,
		"total_hit_points": total_hit_points,
		"weakness": weakness,
		"vulnerability": vulnerability,
		"paralysis": paralysis,
	}
	var text = (
		"[b]{name}[/b]\n" +
		"Level: {level}\n" +
		"HP: {hit_points}/{total_hit_points}\n" +
		"MP: {move_points}/{total_move_points}\n"
	)
	text += "Attack: {damage}\n"
	text += "Range: {attack_range}\n"
	if weakness > 0:
		text += "[url]Weakness[/url]: {weakness}\n"
	if paralysis > 0:
		text += "[url]Paralysis[/url]: {paralysis}\n"
	if vulnerability > 0:
		text += "[url]Vulnerability[/url]: {vulnerability}\n"
	var formatted_text = text.format(format_vars)
	return formatted_text

func effective_damage(character: Character):
	var new_damage = total_damage
	if weakness > 0:
		new_damage *= 0.5
	return int(new_damage)

func attack_range():
	return total_attack_range

func move(map_manager: MapManager, to: Vector2i):
	var from = get_id_position()
	if not is_mock:
		await move_path(map_manager, map_manager.get_enemy_path(from, to))
	set_id_position(to)
	map_manager.move_enemy(from, to)

func draw_attack(target: Character):
	if is_mock:
		return
	if not weapon:
		return
	weapon.show()
	var direction = (weapon.global_position - target.global_position).normalized()
	weapon.look_at(target.global_position, Vector3.UP)
	direction.y = 0
	var prev_distance = -1
	while true:
		var diff = weapon.global_position - target.global_position
		diff.y = 0
		var new_distance = diff.length()
		if prev_distance != -1 and prev_distance < new_distance:
			break
		prev_distance = new_distance
		weapon.global_position -= (direction * 0.5)
		await get_tree().create_timer(0.02, false).timeout
	weapon.position = Vector3(0, 0, 0)
	weapon.hide()

func refresh():
	health_bar.update_health(hit_points, total_hit_points)

func get_save_state():
	var save_state = EnemySaveState.new()
	save_state.enemy_type = enemy_type
	save_state.id_position = get_id_position()
	save_state.total_move_points = total_move_points
	save_state.total_hit_points = total_hit_points
	save_state.total_damage = total_damage
	save_state.total_attack_range = total_attack_range
	save_state.level = level
	save_state.move_points = move_points
	save_state.hit_points = hit_points
	save_state.weakness = weakness
	save_state.paralysis = paralysis
	save_state.vulnerability = vulnerability
	return save_state

func load_save_state(save_state: EnemySaveState):
	set_id_position(save_state.id_position)
	total_move_points = save_state.total_move_points
	total_hit_points = save_state.total_hit_points
	total_damage = save_state.total_damage
	total_attack_range = save_state.total_attack_range
	level = save_state.level
	move_points = save_state.move_points
	hit_points = save_state.hit_points
	weakness = save_state.weakness
	paralysis = save_state.paralysis
	vulnerability = save_state.vulnerability
