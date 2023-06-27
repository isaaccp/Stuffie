extends RefCounted

class_name CardSimulation

var map: MapManager
var unit_card: UnitCard
var target_tile: Vector2i
var direction: Vector2

var aborted: bool
var damage_taken: Array

func _init(map: MapManager, character_pos: Vector2i, card: Card, target_tile: Vector2i, direction: Vector2):
	# Need to clone entities and fov.
	self.map = map.clone(true, true)
	var character = self.map.character_locs[character_pos]
	self.unit_card = UnitCard.new(character, card)
	self.unit_card.set_simulation()
	self.target_tile = target_tile
	self.direction = direction
	aborted = false

func abort():
	aborted = true

func calculate() -> bool:
	if aborted:
		return false
	var characters = []
	var enemies = []
	# Save party and enemies in case they die.
	for character in map.character_locs.values():
		characters.push_back(character)
	for enemy in map.enemy_locs.values():
		enemies.push_back(enemy)
	play_card()
	if aborted:
		return false
	# Play mock enemies begin_turn to account for e.g. bleed effects.
	for enemy in enemies:
		enemy.begin_turn()
	if aborted:
		return false
	for character in characters:
		record_damage(character)
	for enemy in enemies:
		record_damage(enemy)
	return true

func play_card():
	var card_player = CardPlayer.new(map, null)
	await card_player.play_card(unit_card, target_tile, direction)

func record_damage(unit: Unit):
	if unit.snapshot.hit_points == unit.hit_points:
		return
	damage_taken.push_back([unit.get_id_position(), unit.snapshot.hit_points - unit.hit_points])
