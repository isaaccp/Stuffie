extends Relic

class_name CampChoiceRelic

@export var camp_choice: CampChoice

func _tooltip():
	return "Adds camp choice in camp. %s\n" % camp_choice.get_description()

func camp_choices():
	return [camp_choice]
