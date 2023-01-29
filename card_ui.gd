extends PanelContainer

class_name CardUI

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
func initialize(card: Card):
	$VBox/CardTop/Name.text = card.card_name
	$VBox/CardTop/Cost.text = card.get_cost_text()
	$VBox/Image.texture = card.texture
	$VBox/Description.text = card.get_description_text()
