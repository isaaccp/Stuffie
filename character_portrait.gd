extends PanelContainer

class_name CharacterPortrait

@export var portrait: TextureRect
@export var action_points_label: RichTextLabel
@export var move_points_label: RichTextLabel
@export var hit_points_bar: CurrentNextHealthBar
@export var status_effects: StatusEffectsDisplay
@export var enemy_actions: Control
@export var enemy_actions_label: RichTextLabel

enum PortraitMode {
	DEFAULT = 0,
	COMBAT,
}

var unit: Unit
var stylebox: StyleBoxFlat

# TODO: Have per-relic icons in some fancy way.
var relic_icon = preload("res://resources/icons/buffs/enemy_spawn_down.png")
var relic_power_icon = preload("res://resources/icons/buffs/negative_status_resistance.png")

signal pressed

func _ready():
	stylebox = get_theme_stylebox("panel").duplicate()
	# Replace stylebox with duplicate so we can make individual changes to characters.
	add_theme_stylebox_override("panel", stylebox)

func set_mode(mode: PortraitMode):
	if mode == PortraitMode.DEFAULT:
		status_effects.hide()
	elif mode == PortraitMode.COMBAT:
		status_effects.show()

func set_character(unit: Unit):
	self.unit = unit
	unit.changed.connect(_update_unit)
	_update_unit()

func _update_unit():
	if not is_instance_valid(unit):
		return
	_set_portrait_texture(unit.portrait_texture)
	if unit is Character:
		var character = unit as Character
		_set_action_points(character.pending_action_cost, character.action_points, character.total_action_points)
		_set_move_points(character.pending_move_cost, character.move_points, character.total_move_points)
		_set_hit_points(character.pending_damage_set, character.pending_damage, character.hit_points, character.total_hit_points)
		enemy_actions.hide()
	elif unit is Enemy:
		var enemy = unit as Enemy
		_set_action_points(0, unit.action_points, unit.total_action_points)
		_set_move_points(0, unit.move_points, unit.total_move_points)
		_set_hit_points(false, 0, unit.hit_points, unit.total_hit_points)
		enemy_actions.show()
		enemy_actions_label.parse_bbcode(enemy.actions_text())
	_set_status_effects()
	if unit.is_destroyed:
		modulate = Color(1, 0, 0, 0.5)
	else:
		modulate = Color(1, 1, 1)

func _set_portrait_texture(texture: Texture):
	portrait.texture = texture

func _set_move_points(pending_move_cost: int, move_points: int, total_move_points: int):
	var color
	var move_left
	if pending_move_cost > 0:
		color = "red"
		move_left = move_points - pending_move_cost
	else:
		color = "white"
		move_left = move_points

	var bb_code = "[center][color=%s]%d[/color][/center]" % [color, move_left]
	move_points_label.parse_bbcode(bb_code)
	move_points_label.tooltip_text = "Move Points: %d/%d" % [move_points, total_move_points]

func _set_action_points(pending_action_cost: int, action_points: int, total_action_points: int):
	var color
	var actions_left
	if pending_action_cost > 0:
		color = "red"
		actions_left  = action_points - pending_action_cost
	else:
		color = "white"
		actions_left = action_points

	var bb_code = "[center][color=%s]%d[/color]/%d[/center]" % [color, actions_left, total_action_points]
	action_points_label.parse_bbcode(bb_code)

func _set_hit_points(pending_damage_set: bool, pending_damage: int, hit_points: int, total_hit_points: int):
	if unit is Character:
		var pending_damage_text = ""
		if pending_damage_set:
			var lethal_text = ""
			if pending_damage >= hit_points:
				lethal_text = "💀"
			pending_damage_text = "HP after enemy turn: %s%d" % [lethal_text, hit_points - pending_damage]
		else:
			pending_damage_text = "HP after enemy turn: ?"
		hit_points_bar.tooltip_text = "HP: %d/%d\n%s" % [hit_points, total_hit_points, pending_damage_text]
	else:
		hit_points_bar.tooltip_text = "HP: %d/%d" % [hit_points, total_hit_points]
	if pending_damage_set:
		hit_points_bar.set_health(hit_points, total_hit_points, hit_points - pending_damage)
	else:
		hit_points_bar.set_health(hit_points, total_hit_points, hit_points)

func _set_status_effects():
	status_effects.clear()
	if unit is Character:
		var character = unit as Character
		for relic in character.relic_manager.relics:
			status_effects.add_relic(relic_icon, "%s: %s" % [relic.name, relic.tooltip])
		for power in character.relic_manager.temp_relics:
			status_effects.add_relic(relic_power_icon, "%s: %s (until end of combat)" % [power.name, power.tooltip])
	for status in unit.status_manager.statuses:
		var value = unit.status_manager.get_status(status)
		status_effects.add_status_effect(value, status)

func set_active(active: bool):
	if stylebox:
		if active:
			stylebox.border_color = Color(1, 1, 1)
		else:
			stylebox.border_color = Color(0.5, 0.5, 0.5)

func _on_gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == 1 and event.pressed == true:
			pressed.emit()
