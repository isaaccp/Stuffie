extends PanelContainer

class_name CardUI

var cb: Callable
var card: Card
var character: Character

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
func initialize(card: Card, character: Character, callback: Callable):
	self.card = card
	self.character = character
	cb = callback
	refresh()

func get_description_text() -> String:
	var damage_text = "%d" % card.damage
	if card.damage != card.effective_damage(character):
		damage_text = "%d ([color=red]%d[/color])" % [card.damage, card.effective_damage(character)]
	var format_vars = {
		"damage": damage_text,
		"distance": card.target_distance,
	}
	if card.on_play_effect:
		format_vars["move_points"] = card.on_play_effect.move_points
		format_vars["block"] = card.on_play_effect.block
		format_vars["power"] = card.on_play_effect.power
	return card.description.format(format_vars)
	
func get_cost_text() -> String:
	return "%d" % card.cost
	
func refresh():
	$Margin/VBox/CardTop/Name.text = card.card_name
	$Margin/VBox/CardTop/Cost.text = get_cost_text()
	$Margin/VBox/Image.texture = card.texture
	$Margin/VBox/Description.text = get_description_text()

func set_highlight(highlight: bool):
	$Margin/VBox/Playing.visible = highlight
	
func _gui_input(event):
		if event is InputEventMouseButton:
			if event.button_index == 1 and event.pressed:
				if cb.is_valid():
					cb.call()
				accept_event()
