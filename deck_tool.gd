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
	for character_name in character_names:
		print("Finding cards for %s" % character_name)
		var card_collection = CardCollection.new()
		var dir_path = card_base_path + "/" + character_name
		var dir = DirAccess.open(dir_path)
		if dir:
			dir.list_dir_begin()
			var dir_name = dir.get_next()
			while dir_name != "":
				print("Loading cards from %s" % dir_name)
				load_card_dir(card_collection, dir_path, dir_name)
				dir_name = dir.get_next()
		print("Writing card collection with %d levels" % card_collection.cards.size())
		ResourceSaver.save(card_collection, deck_base_path + "/" + character_name + "/card_collection.tres")
		write_character_doc(character_name, card_collection)

func write_character_doc(character_name: String, card_collection: CardCollection):
	var file = FileAccess.open("res://docs/characters/%s.md" % character_name, FileAccess.WRITE)
	file.store_line("# %s" % character_name.to_upper())
	file.store_line("")

	for i in range(card_collection.cards.size()):
		var card_level = card_collection.cards[i]
		if i == 0:
			file.store_line("## Base collection")
		else:
			file.store_line("## Unlock Level %d" % i)
		file.store_line("| Name | Image | Action Cost | Description | Upgrades |")
		file.store_line("| ---- | ----- | ----------- | ----------- |----------|")
		var upgrades = {}
		for card in card_level.cards:
			if card.upgrade_level != 0:
				var base_card_name = card.base_card.card_name
				if not base_card_name in upgrades:
					var card_upgrades: Array[Card]
					upgrades[base_card_name] = card_upgrades
				upgrades[base_card_name].append(card)

		for card in card_level.cards:
			if card.upgrade_level != 0:
				continue
			var card_upgrades: Array[Card]
			if card.card_name in upgrades:
				card_upgrades = upgrades[card.card_name]

			var name = card.card_name
			#var url = "%s/%s.md" % [character_name, name.to_snake_case()]
			#var name_link = "<a href='%s'>%s</a>" % [url, name]
			var unit_card = UnitCard.new(null, card)
			var image = "missing"
			if card.texture:
				image = "<img alt='%s' src='../../%s' width='128'/>" % [name, card.texture.resource_path.trim_prefix("res://")]
			var action_cost = card.cost
			var description = unit_card.get_description().replace("\n", " ")
			var upgrades_text = []
			for upgrade in card_upgrades:
				var unit_upgrade_card = UnitCard.new(null, upgrade)
				var upgrade_text = "*%s* Cost: %d Description: %s" % [upgrade.upgrade_name, upgrade.cost, unit_upgrade_card.get_description().replace("\n", " ")]
				upgrades_text.append(upgrade_text)
			file.store_line("| %s | %s | %s | %s | %s |" % [name, image, action_cost, description, "<br/>".join(upgrades_text)])
