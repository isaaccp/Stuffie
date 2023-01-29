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
	
func set_move_points(move_points: int, total_move_points: int):
	$MovePoints.text = "Mov: %d / %d" % [move_points, total_move_points]
