extends Node3D

class_name WorldEntity

var id_position: Vector2i
var tile_size = 2

var hit_points: int
@export var total_hit_points: int
var pending_damage_set = false
var pending_damage: int = 0

var health_bar: HealthDisplay3D
var health_bar_scene = preload("res://health_display_3d.tscn")

var status_manager = StatusManager.new()
var is_destroyed = false

signal health_changed
signal changed
signal destroyed

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

func set_pending_damage(pending_damage: int):
	pending_damage_set = true
	self.pending_damage = pending_damage
	health_changed.emit()
	changed.emit()

func clear_pending_damage():
	pending_damage_set = false
	health_changed.emit()
	changed.emit()

func _on_health_changed():
	if pending_damage_set:
		health_bar.set_health(hit_points, total_hit_points, hit_points - pending_damage)
	else:
		health_bar.set_health(hit_points, total_hit_points, hit_points)

# For now this is called in Character to update portrait, possibly replace with
# some signal.
func refresh():
	pass

func add_status(status: StatusDef.Status, amount: int):
	status_manager.add_status(status, amount)
	var metadata = StatusMetadata.metadata(status) as StatusDef
	if metadata.received_stats_field != Stats.Field.NO_FIELD:
		add_stat(metadata.received_stats_field, amount)
	changed.emit()

# Returns true if any damage was caused.
func apply_damage(damage: int, blockable=true, dodgeable=true) -> bool:
	add_stat(Stats.Field.ATTACKS_RECEIVED, 1)
	# Handle dodge.
	if dodgeable:
		if status_manager.get_status(StatusDef.Status.DODGE) > 0:
			status_manager.decrement_status(StatusDef.Status.DODGE, 1)
			damage = 0
			add_stat(Stats.Field.ATTACKS_DODGED, 1)
			changed.emit()
	if blockable:
		var blocked_damage = 0
		var block = status_manager.get_status(StatusDef.Status.BLOCK)
		if block > 0:
			if damage <= block:
				status_manager.decrement_status(StatusDef.Status.BLOCK, damage)
				blocked_damage = damage
				damage = 0
			else:
				damage -= block
				blocked_damage = block
				status_manager.clear_status(StatusDef.Status.BLOCK)
		if blocked_damage:
			add_stat(Stats.Field.DAMAGE_BLOCKED, blocked_damage)
	if damage == 0:
		return false
	add_stat(Stats.Field.DAMAGE_TAKEN, damage)
	hit_points -= damage
	if hit_points <= 0:
		set_destroyed()
	# This clears pending damage, as it's no longer valid, and also causes a refresh.
	clear_pending_damage()
	return true

func set_destroyed():
	if not is_destroyed:
		is_destroyed = true
		destroyed.emit()

# Heals 'hp' without going over total hp.
func heal(hp: int):
	# No healing if entity was destroyed.
	if is_destroyed:
		return
	var original_hp = hit_points
	hit_points += hp
	if hit_points > total_hit_points:
		hit_points = total_hit_points
	add_stat(Stats.Field.HP_HEALED, hit_points - original_hp)
	health_changed.emit()
	changed.emit()

func heal_full():
	# No healing if entity was destroyed.
	if is_destroyed:
		return
	hit_points = total_hit_points
	health_changed.emit()
	changed.emit()

# Empty add_stat() implementation that should only be overriden by Character.
# This allows to easily share all the code without having to worry about Stats.
func add_stat(field: Stats.Field, value: int):
	pass

func get_stat(level: Enum.StatsLevel, field: Stats.Field):
	return 0

func begin_turn():
	status_manager.clear_status(StatusDef.Status.BLOCK)
	# At most can carry 1 dodge.
	if status_manager.get_status(StatusDef.Status.DODGE) > 1:
		status_manager.set_status(StatusDef.Status.DODGE, 1)
	changed.emit()

func end_turn():
	changed.emit()
