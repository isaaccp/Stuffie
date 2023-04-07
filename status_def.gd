extends Resource

class_name StatusDef

enum Status {
	NO_STATUS,
	BLOCK,
	DODGE,
	POWER,
	WEAKNESS,
	PARALYSIS,
	BLEED,
}

@export var status: Status
@export var name: String
@export var tooltip: String
@export var icon: Texture
# If present, increase this stat field when character receives this status.
@export var received_stats_field: Stats.Field
# If present, increase this stat field when character applies this status.
@export var applied_stats_field: Stats.Field
