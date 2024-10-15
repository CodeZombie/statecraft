class_name StateMachine extends StateQueue

func _on_child_state_exited():
	pass

func _on_update(delta: float, speed_scale: float = 1.0):
	var my_command = super(delta, speed_scale)
	if my_command is State.EXIT_COMMAND:
		return my_command

	#if self.child_states[self.current_state_index]._state == StateState.WAITING:
		#self.child_states[self.current_state_index]._on_enter()
		
	var child_state_command = self.child_states[self.current_state_index]._on_update(delta, speed_scale)
