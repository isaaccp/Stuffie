extends Control

class_name BlacksmithStage

@export var main: Control
@export var removal_panel: PanelContainer
@export var removal_panel_label: Label
@export var done_button: Button
# When choosing an option that requires UI change, we'll hide "main" and
# attach sub-screen under advanced_option_parent.
@export var advanced_option_parent: Control

enum State {
	CHOOSING_OPTION,
	REMOVAL,
	UPGRADE,
	DONE,
}


# TODO: Eventually we'll display a box of e.g. 4 cards for purchase,
# potentially relics for purchase, and options to purchase a removal or
# an upgrade. For now, doing removal only.

var removal_cost = 0
var available_removals = 1

var state = State.CHOOSING_OPTION
var characters: Array[Character]
var current_cards: Array[Card]
var card_ui_scene = preload("res://card_ui.tscn")
var removal_scene = preload("res://card_removal.tscn")

signal stage_done

func _ready():
	advanced_option_parent.hide()

func initialize(characters: Array[Character]):
	self.characters = characters
	update_removals()
	
func _process(delta):
	pass

func change_state(new_state: State):
	if state == new_state:
		return
	# Hide main UI.
	if state == State.CHOOSING_OPTION:
		main.hide()
	elif state == State.REMOVAL:
		advanced_option_parent.hide()
	# Show new UI.
	if new_state == State.CHOOSING_OPTION:
		main.show()
	elif new_state == State.REMOVAL:
		var removal = removal_scene.instantiate() as CardRemoval
		removal.initialize(characters)
		removal.connect("done", _on_removal_done)
		removal.connect("canceled", _on_removal_canceled)
		advanced_option_parent.add_child(removal)
		advanced_option_parent.show()
	state = new_state
		
func _on_removal_gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == 1 and event.pressed == true:
			change_state(State.REMOVAL)

func update_removals():
	if available_removals == 0:
		removal_panel.hide()
	else:
		removal_panel_label.text = "Remove card (%d left)" % available_removals
func _on_removal_done():
	available_removals -= 1
	update_removals()
	change_state(State.CHOOSING_OPTION)
	
func _on_removal_canceled():
	change_state(State.CHOOSING_OPTION)

func _on_done_pressed():
	stage_done.emit()
