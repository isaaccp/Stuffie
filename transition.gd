extends RefCounted

class_name TransitionScreen

const transition_screen = preload("res://transition_screen.tscn")

static func create(node: Node):
	var transition = transition_screen.instantiate()
	transition.transition()
	node.add_child(transition)
	return transition.blacked_out
