extends PanelContainer

class_name CharacterPortrait

@export var portrait: TextureButton
@export var active_marker: TextureRect
@export var action_points_label: RichTextLabel
@export var move_points_label: RichTextLabel
@export var hit_points_label: RichTextLabel
@export var block_label: Label
@export var dodge_label: Label
@export var power_label: Label
@export var relics_container: Container
@export var powers_container: Container

var character: Character

func set_character(character: Character):
	self.character = character
	character.made_active.connect(_set_active)
	character.changed.connect(_update_character)
	_update_character()
	# TODO: If relics can change in the lifetime of portrait,
	# handle that later.
	_set_relics(character.relic_manager.relics)

func _update_character():
	_set_portrait_texture(character.portrait_texture.texture)
	_set_action_points(character.pending_action_cost, character.action_points, character.total_action_points)
	_set_move_points(character.pending_move_cost, character.move_points, character.total_move_points)
	_set_hit_points(character.pending_damage_set, character.pending_damage, character.hit_points, character.total_hit_points)
	_set_block(character.block)
	_set_dodge(character.dodge)
	_set_power(character.power)
	_set_powers(character.relic_manager.temp_relics)

func _set_portrait_texture(texture: Texture):
	portrait.texture_normal = texture

func _set_relics(relics: Array[Relic]):
	for relic in relics:
		var label = Label.new()
		label.text = relic.name
		label.tooltip_text = relic.tooltip
		label.mouse_filter = Control.MOUSE_FILTER_PASS
		relics_container.add_child(label)

func _set_powers(powers: Array[Relic]):
	for child in powers_container.get_children():
		child.queue_free()
	if powers.size() == 0:
		return
	var title_label = Label.new()
	title_label.text = "Powers"
	title_label.tooltip_text = "Powers are active until end of combat"
	title_label.mouse_filter = Control.MOUSE_FILTER_PASS
	powers_container.add_child(title_label)
	for power in powers:
		var label = Label.new()
		label.text = power.name
		label.tooltip_text = power.tooltip
		label.mouse_filter = Control.MOUSE_FILTER_PASS
		powers_container.add_child(label)

func _set_move_points(pending_move_cost: int, move_points: int, total_move_points: int):
	var color
	var move_left
	if pending_move_cost > 0:
		color = "red"
		move_left = move_points - pending_move_cost
	else:
		color = "white"
		move_left = move_points

	var bb_code = "MP: [color=%s]%d[/color] / %d" % [color, move_left, total_move_points]
	move_points_label.parse_bbcode(bb_code)

func _set_action_points(pending_action_cost: int, action_points: int, total_action_points: int):
	var color
	var actions_left
	if pending_action_cost > 0:
		color = "red"
		actions_left  = action_points - pending_action_cost
	else:
		color = "white"
		actions_left = action_points

	var bb_code = "AP💢: [color=%s]%d[/color] / %d" % [color, actions_left, total_action_points]
	action_points_label.parse_bbcode(bb_code)

func _set_hit_points(pending_damage_set: bool, pending_damage: int, hit_points: int, total_hit_points: int):
	var color: String

	if hit_points / total_hit_points < 0.5:
		color = "red"
	else:
		color = "white"

	var pending_color: String
	var pending_damage_text = ""
	if pending_damage_set:
		var lethal_text = ""
		if pending_damage >= hit_points:
			lethal_text = "💀"
		if pending_damage > 0:
			pending_color = "red"
		elif pending_damage < 0:
			pending_color = "green"
		else:
			pending_color = "white"
		pending_damage_text = "Next HP: %s [color=%s]%d[/color]" % [lethal_text, pending_color, hit_points - pending_damage]
	else:
		pending_damage_text = "Next HP: ?"
	var bb_code = "HP: [color=%s]%d[/color] / %d\n%s" % [color, hit_points, total_hit_points, pending_damage_text]
	hit_points_label.parse_bbcode(bb_code)

func _set_block(block: int):
	if block == 0:
		block_label.text = ""
		block_label.hide()
	else:
		block_label.text = "Block: %d" % block
		block_label.show()

func _set_dodge(dodge: int):
	if dodge == 0:
		dodge_label.text = ""
		dodge_label.hide()
	else:
		dodge_label.text = "Dodge: %d" % dodge
		dodge_label.show()

func _set_power(power: int):
	if power == 0:
		power_label.text = ""
		power_label.hide()
	else:
		power_label.text = "Power: %d⌚" % power
		power_label.show()

func _set_active(active: bool):
	active_marker.visible = active
