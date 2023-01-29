extends Node2D

var total_ap: int = 5
var total_mp: int = 10
var ap: int
var mp: int

var portrait: CharacterPortrait

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func begin_turn():
	ap = total_ap
	mp = total_mp
	refresh_portrait()

func set_portrait(character_portrait: CharacterPortrait):
	portrait = character_portrait
	refresh_portrait()

func refresh_portrait():
	portrait.set_portrait_texture($Picture.texture)
	portrait.set_move_points(mp, total_mp)
