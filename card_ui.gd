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

func get_card_effect_description(effect: CardEffect) -> String:
	var effect_texts: PackedStringArray
	if effect.hit_points > 0:
		effect_texts.push_back("heals %d" % effect.hit_points)
	if effect.block > 0:
		effect_texts.push_back("adds %d block" % effect.block)
	if effect.power > 0:
		effect_texts.push_back("adds %d power" % effect.power)
	if effect.move_points > 0:
		effect_texts.push_back("adds %d MP" % effect.move_points)
	if effect.action_points > 0:
		effect_texts.push_back("adds %d AP" % effect.action_points)
	if effect_texts.size() == 0:
		return ""
	return ", ".join(effect_texts)
	
func get_description_text() -> String:
	var description = ""
	if card.target_mode in [Card.TargetMode.SELF, Card.TargetMode.SELF_ALLY or Card.TargetMode.SELF_ALLY]:
		var target_text = ""
		if card.target_mode == Card.TargetMode.SELF:
			target_text = "character"
		elif card.target_mode == Card.TargetMode.SELF_ALLY:
			target_text = "character or ally"
		elif card.target_mode == Card.TargetMode.ALLY:
			target_text = "ally"
		if card.on_play_effect:
			var on_play_text = get_card_effect_description(card.on_play_effect)
			if on_play_text:
				description += "On Play: %s %s" % [target_text, on_play_text]
	elif card.target_mode == Card.TargetMode.ENEMY:
		if card.damage:
			var damage_text = "%d" % card.damage
			if card.damage != card.effective_damage(character):
				damage_text = "%d ([color=red]%d[/color])" % [card.damage, card.effective_damage(character)]
			description += "Attack for %s dmg\n" % damage_text
		if card.on_kill_effect:
			var on_kill_text = get_card_effect_description(card.on_kill_effect)
			description += "On Kill: %s" % on_kill_text
	return description
	
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
