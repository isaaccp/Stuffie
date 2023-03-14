extends PanelContainer

class_name RunCharacterStats

@export var portrait: CharacterPortrait
@export var stats_grid: GridContainer
var character: Character

func initialize(character: Character):
	self.character = character
	portrait.set_character(character)

func add_stat(field: Stats.Field):
	var name_label = Label.new()
	name_label.text = StatsManager.run_stats.get_pretty_field_name(field)
	var value_label = Label.new()
	value_label.text = "%d" % StatsManager.run_stats.get_value(character.character_type, field)
	stats_grid.add_child(name_label)
	stats_grid.add_child(value_label)
