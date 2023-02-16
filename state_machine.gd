extends Object

class_name StateMachine

class State:
	pass
	
var state: State
var states: Array[State]
var class_check: Callable

func enter_signal_name(s: State):
	return ("%s_state_entered" % s.name)

func exit_signal_name(s: State):
	return ("%s_state_exited" % s.name)
	
func _init(states: Array[State], class_check: Callable):
	self.states = states
	self.class_check = class_check
	for s in states:
		add_user_signal(enter_signal_name(s))
		add_user_signal(exit_signal_name(s))
	state = null
	
func change_state(new_state: State):
	assert(class_check.call(new_state))
	if state != null:
		if state.name == new_state.name:
			return
		emit_signal(exit_signal_name(state))
	state = new_state
	emit_signal(enter_signal_name(new_state))
