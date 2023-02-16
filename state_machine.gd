extends Object

class_name StateMachine

class State:
	pass
	
var state: State
var class_check: Callable
signal state_entered(state: State)
signal state_exited(state: State)

func _init(class_check: Callable):
	self.class_check = class_check
	state = null
	
func change_state(new_state: State):
	assert(class_check.call(new_state))
	if state != null:
		if state.name == new_state.name:
			return
		state_exited.emit(state)
	state = new_state
	state_entered.emit(new_state)
