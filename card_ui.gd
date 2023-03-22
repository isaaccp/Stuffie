extends Control

class_name CardUI

var unit_card: UnitCard
var character: Character
var keyword_tooltips = {
	"power": "If character has any power, damage +50%.\nRemove 1 power per turn.",
	"block": "If character has block, block is reduced before HP when receiving damage.\nAll block is removed at beginning of next turn.",
	"dodge": "If character has dodge, ignore all damage from the next attack and remove 1 dodge. Up to 1 dodge carries to next turn.",
	"weakness": "If character has weakness, attack damage is reduced to 50%.\nRemove 1 weakness per turn.",
	"paralysis": "If character has paralysis, do not act this turn.\nRemove 1 paralysis per turn.",
	"MP": "Move points. Used to move the character. Can be raised over Total MP.",
	"exhaust": "When played, remove the card from play until next stage.",
}

@export var card_name: Label
@export var upgrade_label: Label
@export var cost: Label
@export var description: RichTextLabel
@export var tooltip: Label
@export var image: TextureRect
var stylebox: StyleBoxFlat

var selected = false
var focused = false
var removed = false
var tw: Tween

signal pressed

# Called when the node enters the scene tree for the first time.
func _ready():
	tooltip.hide()
	stylebox = get_theme_stylebox("panel").duplicate()
	# Replace stylebox with duplicate so we can make individual changes to cards.
	add_theme_stylebox_override("panel", stylebox)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func initialize(card: Card, unit: Unit):
	unit_card = UnitCard.new(unit, card)
	keyword_tooltips.merge(card.extra_tooltips())
	self.character = character
	refresh()

func get_description_text() -> String:
	return unit_card.get_description()

func tooltip_text(keyword: String) -> String:
	if keyword_tooltips.has(keyword):
		return keyword_tooltips[keyword]
	else:
		return "Unknown keyword, please file a bug"

func get_cost_text() -> String:
	return "%d" % unit_card.card.cost

func refresh():
	card_name.text = unit_card.card.card_name
	if unit_card.card.upgrade_level and unit_card.card.upgrade_level > 0:
		card_name.text = unit_card.card.base_card.card_name
		upgrade_label.show()
		if unit_card.card.upgrade_name:
			upgrade_label.text = unit_card.card.upgrade_name
	cost.text = get_cost_text()
	image.texture = unit_card.card.texture
	description.text = get_description_text()

func set_selected(selected: bool):
	var changed = selected != self.selected
	self.selected = selected
	_on_highlight_change(changed, false)

func set_focused(focused: bool):
	var changed = focused != self.focused
	self.focused = focused
	_on_highlight_change(false, changed)

func set_removed(removed: bool):
	self.removed = removed

func _on_highlight_change(selected_changed: bool, focused_changed: bool):
	if selected_changed:
		if not selected and tw :
			tw.stop()
		if selected:
			stylebox.shadow_color = Color(1.0, 0, 1.0)
			tw = create_tween()
			tw.tween_property(stylebox, "shadow_size", 30, 0.75)
			tw.tween_property(stylebox, "shadow_size", 5, 0.75)
			tw.set_loops()
	if not selected:
		if focused:
			stylebox.shadow_color = Color(1.0, 0, 1.0)
			stylebox.shadow_size = 5
		else:
			stylebox.shadow_size = 0

func _gui_input(event):
		if event is InputEventMouseButton:
			if event.button_index == 1 and event.pressed:
				pressed.emit()
				accept_event()

func _on_description_meta_hover_started(meta):
	var keyword = meta as String
	tooltip.text = tooltip_text(keyword)
	tooltip.show()
	image.hide()

func _on_description_meta_hover_ended(meta):
	tooltip.hide()
	image.show()

func _on_mouse_entered():
	set_focused(true)

func _on_mouse_exited():
	set_focused(false)
