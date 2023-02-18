extends Control

class_name BlacksmithStage

@export var main: Control
@export var removal_panel: PanelContainer
@export var removal_panel_label: Label
@export var done_button: Button
# When choosing an option that requires UI change, we'll hide "main" and
# attach sub-screen under advanced_option_parent.
@export var advanced_option_parent: Control
@export var shared_bag_gold_ui: SharedBagGoldUI

var state = StateMachine.new()
var CHOOSING_OPTION = state.add("choosing_option")
var REMOVAL = state.add("removal")
# var UPGRADE = state.add("upgrade")

# TODO: Eventually we'll display a box of e.g. 4 cards for purchase,
# potentially relics for purchase, and options to purchase a removal or
# an upgrade. For now, doing removal only.

var removal_cost = 10
var available_removals = 1

var characters: Array[Character]
var shared_bag: SharedBag
var current_cards: Array[Card]
var card_ui_scene = preload("res://card_ui.tscn")
var removal_scene = preload("res://card_removal.tscn")

signal stage_done

func _ready():
	state.connect_signals(self)
	state.change_state(CHOOSING_OPTION)
	advanced_option_parent.hide()

func _on_choosing_option_entered():
	main.show()

func _on_removal_entered():
	var removal = removal_scene.instantiate() as CardRemoval
	removal.initialize(characters)
	removal.connect("done", _on_removal_done)
	removal.connect("canceled", _on_removal_canceled)
	advanced_option_parent.add_child(removal)
	advanced_option_parent.show()

func _on_choosing_option_exited():
	main.hide()

func _on_removal_exited():
	advanced_option_parent.hide()

func initialize(characters: Array[Character], shared_bag: SharedBag):
	self.characters = characters
	self.shared_bag = shared_bag
	shared_bag_gold_ui.set_shared_bag(shared_bag)
	update_removals()

func _process(delta):
	pass

func _on_removal_gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == 1 and event.pressed == true:
			state.change_state(REMOVAL)

func update_removals():
	removal_panel_label.text = "Remove card (%d🪙) (%d left)" % [removal_cost, available_removals]
	if available_removals == 0 or shared_bag.gold < removal_cost:
		removal_panel.modulate = Color(0.5, 0.5, 0.5, 0.5)
		removal_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	else:
		removal_panel.modulate = Color(1, 1, 1, 1)
		removal_panel.mouse_filter = Control.MOUSE_FILTER_STOP

func _on_removal_done():
	available_removals -= 1
	shared_bag.spend_gold(removal_cost)
	update_removals()
	state.change_state(CHOOSING_OPTION)

func _on_removal_canceled():
	state.change_state(CHOOSING_OPTION)

func _on_done_pressed():
	stage_done.emit()
