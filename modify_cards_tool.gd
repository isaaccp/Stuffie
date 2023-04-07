@tool

extends EditorScript

var card_base_path = "res://resources/cards"
var character_names = ["warrior", "wizard"]

func _run():
	modify_cards()

var field_to_status_map = {
	CardEffectValue.Field.BLOCK: StatusDef.Status.BLOCK,
	CardEffectValue.Field.BLEED: StatusDef.Status.BLEED,
	CardEffectValue.Field.DODGE: StatusDef.Status.DODGE,
	CardEffectValue.Field.WEAKNESS: StatusDef.Status.WEAKNESS,
	CardEffectValue.Field.POWER: StatusDef.Status.POWER,
	CardEffectValue.Field.PARALYSIS: StatusDef.Status.PARALYSIS,
}

func field_to_status(effects: Array):
	for effect in effects:
		if effect.effect_type == CardEffect.EffectType.FIELD:
			if not effect.target_field in field_to_status_map:
				continue
			effect.effect_type = CardEffect.EffectType.STATUS
			effect.target_status = field_to_status_map[effect.target_field]
			effect.target_field = CardEffectValue.Field.NO_FIELD

func modify(card: Card):
	field_to_status(card.on_play_self_effects)
	field_to_status(card.on_play_effects)
	field_to_status(card.on_play_after_effects)
	field_to_status(card.on_damage_effects)
	field_to_status(card.on_kill_effects)
	field_to_status(card.on_next_turn_effects)

func modify_cards():
	for character_name in character_names:
		var dir_path = card_base_path + "/" + character_name
		var dir = DirAccess.open(dir_path)
		if dir:
			dir.list_dir_begin()
			var filename = dir.get_next()
			while filename != "":
				print("Loading %s" % filename)
				var full_path = dir_path + "/" + filename
				var card = load(full_path) as Card
				modify(card)
				ResourceSaver.save(card, full_path)
				filename = dir.get_next()
