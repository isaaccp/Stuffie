extends PanelContainer

class_name CharacterPortrait

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
func set_portrait_texture(texture: Texture):
	$Margin/VBox/Portrait.texture_normal = texture

func get_portrait_button() -> TextureButton:
	return $Margin/VBox/Portrait
		
func set_move_points(pending_move_cost: float, move_points: float, total_move_points: int):
	var color
	var move_left
	if pending_move_cost > 0:
		color = "red"
		move_left = move_points - pending_move_cost
	else:
		color = "white"
		move_left = move_points

	var bb_code = "MP: [color=%s]%0.1f[/color] / %d" % [color, move_left, total_move_points]
	$Margin/VBox/MovePoints.parse_bbcode(bb_code)
	
func set_action_points(pending_action_cost: int, action_points: int, total_action_points: int):
	var color
	var actions_left
	if pending_action_cost > 0:
		color = "red"
		actions_left  = action_points - pending_action_cost
	else:
		color = "white"
		actions_left = action_points

	var bb_code = "AP: [color=%s]%d[/color] / %d" % [color, actions_left, total_action_points]
	$Margin/VBox/ActionPoints.parse_bbcode(bb_code)
	
func set_active(active: bool):
	$Margin/VBox/Portrait/ActiveMarker.visible = active
