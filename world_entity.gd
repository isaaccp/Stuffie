extends Node3D

class_name WorldEntity

var id_position: Vector2i
var tile_size = 2

var hit_points: int
@export var total_hit_points: int
var health_bar: HealthDisplay3D
var health_bar_scene = preload("res://health_display_3d.tscn")

var block: int
var dodge: int
var destroyed = false
# TODO: var vulnerability: int

signal health_changed
signal changed

func _ready():
	if total_hit_points > 0:
		health_bar = health_bar_scene.instantiate()
		add_child(health_bar)
		health_bar.position.y = 2.2
		health_changed.connect(_on_health_changed)

func set_id_position(id_pos: Vector2i):
	id_position = id_pos
	position = Vector3(
		id_position[0] * tile_size + tile_size/2,
		1.5,
		id_position[1] * tile_size + tile_size/2)

func get_id_position() -> Vector2i:
	return id_position

func move_path(curve: Curve3D):
	# Moving 1 "baked point" per 0.01 seconds, each point being
	# at a distance of 0.2 from each other.
	for point in curve.get_baked_points():
		look_at(point)
		position = point
		# Set timer to not pass time during pause.
		await get_tree().create_timer(0.01, false).timeout

func _on_health_changed():
	health_bar.update_health(hit_points, total_hit_points)

# For now this is called in Character to update portrait, possibly replace with
# some signal.
func refresh():
	pass

func add_block(block_amount: int):
	block += block_amount
	add_stat(Stats.Field.BLOCK_ACQUIRED, block_amount)
	changed.emit()

func add_dodge(dodge_amount: int):
	dodge += dodge_amount
	add_stat(Stats.Field.DODGE_ACQUIRED, dodge_amount)
	changed.emit()

func apply_damage(damage: int, blockable=true, dodgeable=true):
	add_stat(Stats.Field.ATTACKS_RECEIVED, 1)
	# Handle dodge.
	if dodgeable:
		if dodge > 0:
			dodge -= 1
			add_stat(Stats.Field.ATTACKS_DODGED, 1)
			changed.emit()
			return
	if blockable:
		var blocked_damage = 0
		if block > 0:
			if damage <= block:
				block -= damage
				blocked_damage = damage
				damage = 0
			else:
				damage -= block
				blocked_damage = block
				block = 0
		if blocked_damage:
			add_stat(Stats.Field.DAMAGE_BLOCKED, blocked_damage)
	add_stat(Stats.Field.DAMAGE_TAKEN, damage)
	hit_points -= damage
	health_changed.emit()
	if hit_points <= 0:
		destroyed = true
		changed.emit()
		return true
	changed.emit()

# Heals 'hp' without going over total hp.
func heal(hp: int):
	var original_hp = hit_points
	hit_points += hp
	if hit_points > total_hit_points:
		hit_points = total_hit_points
	add_stat(Stats.Field.HP_HEALED, hit_points - original_hp)
	health_changed.emit()
	changed.emit()

func heal_full():
	hit_points = total_hit_points
	health_changed.emit()
	changed.emit()

# Empty add_stat() implementation that should only be overriden by Character.
# This allows to easily share all the code without having to worry about Stats.
func add_stat(field: Stats.Field, value: int):
	pass

func end_turn():
	block = 0
	# At most can carry 1 dodge.
	if dodge > 0:
		dodge = 1
	changed.emit()
