extends Control

class_name BlacksmithStage

@export var main: Control
@export var removal_panel: PanelContainer
@export var removal_panel_label: Label
@export var done_button: Button
# When choosing an option that requires UI change, we'll hide "main" and
# attach sub-screen under advanced_option_parent.
@export var advanced_option_parent: Control

class BlacksmithState extends StateMachine.State:
	pass
	
class ChoosingOption extends BlacksmithState:
	var name = "ChoosingOption"
	
class Removal extends BlacksmithState:
	var name = "Removal"
	
class Upgrade extends BlacksmithState:
	var name = "Upgrade"

class Done extends BlacksmithState:
	var name = "Done"

func class_check(state: BlacksmithState):
	return (state is BlacksmithState)


# TODO: Eventually we'll display a box of e.g. 4 cards for purchase,
# potentially relics for purchase, and options to purchase a removal or
# an upgrade. For now, doing removal only.

var removal_cost = 0
var available_removals = 1

var state = StateMachine.new(class_check)
var characters: Array[Character]
var current_cards: Array[Card]
var card_ui_scene = preload("res://card_ui.tscn")
var removal_scene = preload("res://card_removal.tscn")

signal stage_done

func _ready():
	state.connect("state_entered", _on_state_entered)
	state.connect("state_exited", _on_state_exited)
	state.change_state(ChoosingOption.new())
	advanced_option_parent.hide()

func _on_state_entered(new_state: BlacksmithState):
	if new_state is ChoosingOption:
		main.show()
	elif new_state is Removal:
		var removal = removal_scene.instantiate() as CardRemoval
		removal.initialize(characters)
		removal.connect("done", _on_removal_done)
		removal.connect("canceled", _on_removal_canceled)
		advanced_option_parent.add_child(removal)
		advanced_option_parent.show()
	
func _on_state_exited(state: BlacksmithState):
	if state is ChoosingOption:
		main.hide()
	elif state is Removal:
		advanced_option_parent.hide()
	
func initialize(characters: Array[Character]):
	self.characters = characters
	update_removals()
	
func _process(delta):
	pass

func _on_removal_gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == 1 and event.pressed == true:
			state.change_state(Removal.new())

func update_removals():
	if available_removals == 0:
		removal_panel.hide()
	else:
		removal_panel_label.text = "Remove card (%d left)" % available_removals
func _on_removal_done():
	available_removals -= 1
	update_removals()
	state.change_state(ChoosingOption.new())
	
func _on_removal_canceled():
	state.change_state(ChoosingOption.new())

func _on_done_pressed():
	stage_done.emit()
