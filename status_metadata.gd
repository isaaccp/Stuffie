extends Node

@export var status_defs: Array[StatusDef]

var status_metadata: Dictionary
var tooltips: Dictionary

func _ready():
	for def in status_defs:
		status_metadata[def.status] = def
		tooltips[def.name] = def.tooltip

func metadata(status: StatusDef.Status) -> StatusDef:
	return status_metadata[status]

func status_icon(status: StatusDef.Status) -> Texture:
	return status_metadata[status].icon

func status_name(status: StatusDef.Status) -> String:
	return status_metadata[status].name

func status_tooltip(status: StatusDef.Status) -> String:
	return status_metadata[status].tooltip
