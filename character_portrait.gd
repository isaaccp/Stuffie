extends PanelContainer

class_name CharacterPortrait

@export var portrait: TextureButton
@export var active_marker: TextureRect
@export var action_points_label: RichTextLabel
@export var move_points_label: RichTextLabel
@export var hit_points_label: RichTextLabel
@export var block_label: Label
@export var power_label: Label
@export var relics_container: Container

var character: Character

func set_character(character: Character):
	self.character = character
	character.made_active.connect(_set_active)
	character.changed.connect(_update_character)
	_update_character()
	# TODO: If relics can change in the lifetime of portrait,
	# handle that later.
	_set_relics(character.relics)


func _update_character():
	_set_portrait_texture(character.portrait_texture.texture)
	_set_action_points(character.pending_action_cost, character.action_points, character.total_action_points)
	_set_move_points(character.pending_move_cost, character.move_points, character.total_move_points)
	_set_hit_points(character.hit_points, character.total_hit_points)
	_set_block(character.block)
	_set_power(character.power)

func _set_portrait_texture(texture: Texture):
	portrait.texture_normal = texture

func _set_relics(relics: Array[Relic]):
	for relic in relics:
		var label = Label.new()
		label.text = relic.name
		label.tooltip_text = relic.tooltip
		label.mouse_filter = Control.MOUSE_FILTER_PASS
		relics_container.add_child(label)

func _set_move_points(pending_move_cost: float, move_points: float, total_move_points: int):
	var color
	var move_left
	if pending_move_cost > 0:
		color = "red"
		move_left = move_points - pending_move_cost
	else:
		color = "white"
		move_left = move_points

	var bb_code = "MP: [color=%s]%0.1f[/color] / %d" % [color, move_left, total_move_points]
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

func _set_hit_points(hit_points: int, total_hit_points: int):
	var color
	if hit_points / total_hit_points < 0.5:
		color = "red"
	else:
		color = "white"

	var bb_code = "HP: [color=%s]%d[/color] / %d" % [color, hit_points, total_hit_points]
	hit_points_label.parse_bbcode(bb_code)

func _set_block(block: int):
	if block == 0:
		block_label.text = ""
	else:
		block_label.text = "Block: %d" % block

func _set_power(power: int):
	if power == 0:
		power_label.text = ""
	else:
		power_label.text = "Power: %d⌚" % power

func _set_active(active: bool):
	active_marker.visible = active
