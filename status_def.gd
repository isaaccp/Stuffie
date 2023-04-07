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
