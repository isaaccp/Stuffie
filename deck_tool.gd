@tool

extends EditorScript

var card_base_path = "res://resources/cards"
var deck_base_path = "res://resources/decks"
var character_names = ["warrior", "wizard"]

func _run():
	create_card_lists()

func load_card_dir(card_collection: CardCollection, base_dir: String, dir_name: String):
	var all_cards = CardSelectionSet.new()
	var dir_path = base_dir + "/" + dir_name
	var dir = DirAccess.open(dir_path)
	if dir:
		dir.list_dir_begin()
		var filename = dir.get_next()
		while filename != "":
			print("Loading %s" % filename)
			var card = load(dir_path + "/" + filename) as Card
			all_cards.cards.push_back(card)
			filename = dir.get_next()
		print("%s: Found %d all_cards" % [dir_path, all_cards.cards.size()])
		# This relies on the fact that initial, level1, etc are all in order
		# alphabetically.
		card_collection.cards.push_back(all_cards)

# Given a directory with initial, level1, level2 subdirs, we want:
# card_collection.tres     # a CardCollection with all the cards split in levels
func create_card_lists():
	var card_collection = CardCollection.new()
	for character_name in character_names:
		var dir_path = card_base_path + "/" + character_name
		var dir = DirAccess.open(dir_path)
		if dir:
			dir.list_dir_begin()
			var dir_name = dir.get_next()
			while dir_name != "":
				load_card_dir(card_collection, dir_path, dir_name)
				dir_name = dir.get_next()
		ResourceSaver.save(card_collection, deck_base_path + "/" + character_name + "/card_collection.tres")
