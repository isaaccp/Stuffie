extends PanelContainer

class_name CardUI

var cb: Callable

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
func initialize(card: Card, callback: Callable):
	$Margin/VBox/CardTop/Name.text = card.card_name
	$Margin/VBox/CardTop/Cost.text = card.get_cost_text()
	$Margin/VBox/Image.texture = card.texture
	$Margin/VBox/Description.text = card.get_description_text()
	cb = callback

func set_highlight(highlight: bool):
	$Margin/VBox/Playing.visible = highlight
	
func _gui_input(event):
		if event is InputEventMouseButton:
			if event.button_index == 1 and event.pressed:
				if cb.is_valid():
					cb.call()
				accept_event()
