extends RefCounted

class_name Stats

enum Field {
	COMBAT_STAGES_FINISHED,
	ENEMIES_KILLED,
	DAMAGE_DEALT,
	DAMAGE_BLOCKED,
	DAMAGE_TAKEN,
	HP_HEALED,
	AP_USED,
	MP_USED,
	CARDS_PLAYED,
	EXTRA_CARDS_DRAWN,
	DISCARDED_CARDS,
	GOLD_EARNED,
	GOLD_SPENT,
	RELICS_ACQUIRED,
	CHESTS_ACQUIRED,
	CARDS_ACQUIRED,
	CARDS_REMOVED,
	CARDS_UPGRADED,
	CAMPS_VISITED,
	BLACKSMITHS_VISITED,
	POWER_ACQUIRED,
	BLOCK_ACQUIRED,
	WEAKNESS_APPLIED,
	ENEMY_MP_REMOVED,
	RUNS_PLAYED,
	RUNS_COMPLETED,
}

var reverse_field_lookup: Dictionary

var stats: Dictionary

func _init():
	super()
	for key in Field.keys():
		reverse_field_lookup[Field[key]] = key

func _field_name(field: Field):
	return reverse_field_lookup[field]

func add(character: Character.CharacterType, field: Field, value: int):
	if character not in stats:
		stats[character] = {}
	var character_stats = stats[character]
	if field not in character_stats:
		character_stats[field] = 0
	character_stats[field] += value

# Used in very rare occassions in which we have to take something back, e.g.
# undoing a move.
func remove(character: Character.CharacterType, field: Field, value: int):
	assert(character in stats)
	stats[character] = {}
	var character_stats = stats[character]
	assert(field in character_stats)
	character_stats[field] -= value
	assert(character_stats[field] >= 0)

func append(new_stats: Stats):
	for character in new_stats.stats.keys():
		var character_stats = new_stats.stats[character]
		for field in character_stats:
			add(character, field, character_stats[field])

func get_value(character: Character.CharacterType, field: Field):
	if not character in stats:
		return 0
	var character_stats = stats[character]
	if field not in character_stats:
		return 0

func print():
	for character_type in stats:
		var character_stats = stats[character_type]
		for field in character_stats:
			print(_field_name(field), ": ", character_stats[field])
