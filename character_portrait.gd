extends VBoxContainer

class_name CharacterPortrait

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
func set_portrait_texture(texture: Texture):
	$Portrait.texture_normal = texture
	
func set_move_points(pending_move_cost: float, move_points: float, total_move_points: int):
	var color
	var move_left
	if pending_move_cost > 0:
		color = "red"
		move_left = move_points - pending_move_cost
	else:
		color = "white"
		move_left = move_points

	var bb_code = "Mov: [color=%s]%0.1f[/color] / %d" % [color, move_left, total_move_points]
	$MovePoints.parse_bbcode(bb_code)
	
func set_active(active: bool):
	$Portrait/ActiveMarker.visible = active
