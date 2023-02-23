extends PanelContainer

class_name CardUI

var cb: Callable
var card: Card
var character: Character
var keyword_tooltips = {
	"power": "If character has any power, damage +50%.\nRemove 1 power per turn.",
	"block": "If character has block, block is reduced before HP when receiving damage.\nAll block is removed at beginning of next turn.",
	"weakness": "If character has weakness, attack damage is reduced to 50%.\nRemove 1 weakness per turn.",
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

func get_description_text() -> String:
	return card.get_description(character)

func tooltip_text(keyword: String) -> String:
	if keyword_tooltips.has(keyword):
		return keyword_tooltips[keyword]
	else:
		return "Unknown keyword, please file a bug"

func get_cost_text() -> String:
	return "%d💢" % card.cost

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
