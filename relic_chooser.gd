extends PanelContainer

class_name RelicChooser

@export var relic_container: Container
@export var skip_button: Button

var relics: Array
var chosen_relic: Relic = null

signal relic_chosen(relic: Relic)

func _ready():
	pass

func set_skippable():
	skip_button.show()
	skip_button.pressed.connect(_on_skip_button_pressed)

func initialize(relics: Array):
	# TODO: Add a better relic UI.
	for relic in relics:
		var button = Button.new()
		button.text = relic.name
		button.tooltip_text = relic.tooltip
		button.pressed.connect(_on_relic_pressed.bind(relic))
		relic_container.add_child(button)

func _on_relic_pressed(relic: Relic):
	chosen_relic = relic
	relic_chosen.emit(relic)

func _on_skip_button_pressed():
	relic_chosen.emit(null)
