extends PanelContainer

class_name CardUI

var cb: Callable
var card: Card
var character: Character
var keyword_tooltips = {
	"power": "If character has any power, damage +50%.\nRemove 1 power per turn.",
	"block": "If character has block, block is reduced before HP when receiving damage.\nAll block is removed at beginning of next turn.",
}

@export var description: RichTextLabel
@export var tooltip: Label
@export var image: TextureRect

# Called when the node enters the scene tree for the first time.
func _ready():
	tooltip.hide()

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
		effect_texts.push_back("adds %d [url]block[/url]" % effect.block)
	if effect.power > 0:
		effect_texts.push_back("adds %d [url]power[/url]" % effect.power)
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
		var attack_text = "Attack"
		if card.effect_area(Vector2.RIGHT).size() > 1:
			attack_text += " enemies in area"
		if card.damage:
			var damage_text = "%d" % card.damage
			if card.damage != card.effective_damage(character):
				damage_text = "%d ([color=red]%d[/color])" % [card.damage, card.effective_damage(character)]
			description += "%s for %s dmg\n" % [attack_text, damage_text]
		if card.on_kill_effect:
			var on_kill_text = get_card_effect_description(card.on_kill_effect)
			description += "On Kill: %s" % on_kill_text
	return description

func tooltip_text(keyword: String) -> String:
	if keyword_tooltips.has(keyword):
		return keyword_tooltips[keyword]
	else:
		return "Unknown keyword, please file a bug"
	
func get_cost_text() -> String:
	return "%d" % card.cost
	
func refresh():
	$Margin/VBox/CardTop/Name.text = card.card_name
	$Margin/VBox/CardTop/Cost.text = get_cost_text()
	image.texture = card.texture
	description.text = get_description_text()

func set_highlight(highlight: bool):
	$Margin/VBox/Playing.visible = highlight
	
func _gui_input(event):
		if event is InputEventMouseButton:
			if event.button_index == 1 and event.pressed:
				if cb.is_valid():
					cb.call()
				accept_event()

func _on_description_meta_hover_started(meta):
	var keyword = meta as String
	tooltip.text = tooltip_text(keyword)
	tooltip.show()
	image.hide()


func _on_description_meta_hover_ended(meta):
	tooltip.hide()
	image.show()
