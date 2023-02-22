extends Resource

class_name CardEffect

@export var block: int
@export var power: int
@export var hit_points: int
@export var move_points: int
@export var action_points: int
@export var weakness: int
@export var vulnerability: int
@export var draw_cards: int
@export var draw_attack: int
@export var total_hit_points: int

func apply_to_character(character: Character):
	if move_points > 0:
		character.move_points += move_points
	if block > 0:
		character.add_block(block)
	if power > 0:
		character.power += power
	if action_points > 0:
		character.action_points += action_points
	if hit_points > 0:
		character.heal(hit_points)
	if total_hit_points > 0:
		character.total_hit_points += total_hit_points
		character.heal(total_hit_points)
	if draw_cards > 0:
		character.draw_cards(draw_cards)
	if draw_attack > 0:
		character.draw_attack(draw_attack)

func apply_to_enemy(enemy: Enemy):
	if weakness:
		enemy.weakness += weakness
	if vulnerability:
		enemy.vulnerability += weakness
	if move_points:
		enemy.move_points += move_points
		if enemy.move_points < 0:
			enemy.move_points = 0

func get_description() -> String:
	var effect_texts: PackedStringArray = []
	if hit_points > 0:
		effect_texts.push_back("heals %d" % hit_points)
	if total_hit_points > 0:
		effect_texts.push_back("increases max HP by %d" % total_hit_points)
	if block > 0:
		effect_texts.push_back("adds %d [url]block[/url]" % block)
	if power > 0:
		effect_texts.push_back("adds %d [url]power[/url]" % power)
	if move_points > 0:
		effect_texts.push_back("adds %d MP" % move_points)
	elif move_points < 0:
		effect_texts.push_back("removes %d MP" % -move_points)
	if action_points > 0:
		effect_texts.push_back("adds %d AP" % action_points)
	if weakness > 0:
		effect_texts.push_back("adds %d [url]weakness[/url]" % weakness)
	if vulnerability > 0:
		effect_texts.push_back("adds %d [url]vulnerability[/url]" % vulnerability)
	if draw_cards > 0:
		effect_texts.push_back("draws %d cards" % draw_cards)
	if draw_attack > 0:
		effect_texts.push_back("draws %d attack cards" % draw_attack)
	if effect_texts.size() == 0:
		return ""
	return ", ".join(effect_texts)
