@tool

extends EditorScript

var card_base_path = "res://resources/cards"
var deck_base_path = "res://resources/decks"
var character_name = "warrior"

func _run():
	create_card_lists()

func create_card_lists():
	var extra_cards = CardSelectionSet.new()
	var all_cards = CardSelectionSet.new()

	var dir_path = card_base_path + "/" + character_name
	var dir = DirAccess.open(dir_path)
	if dir:
		dir.list_dir_begin()
		var filename = dir.get_next()
		while filename != "":
			print("Loading %s" % filename)
			var card = load(dir_path + "/" + filename) as Card
			all_cards.cards.push_back(card)
			if not card.basic and card.upgrade_level == 0:
				print("Adding to extra_cards")
				extra_cards.cards.push_back(card)
			filename = dir.get_next()

	print("Found %d all_cards" % all_cards.cards.size())
	print("Found %d extra_cards" % extra_cards.cards.size())
	ResourceSaver.save(extra_cards, deck_base_path + "/" + character_name + "/extra_cards.tres",)
	ResourceSaver.save(all_cards, deck_base_path + "/" + character_name + "/all_cards.tres")
