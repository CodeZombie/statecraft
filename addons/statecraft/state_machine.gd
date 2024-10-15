class_name StateMachine extends StateQueue

func _on_child_state_exited():
	pass

func set_initial_state(state_id: String):
	self.initial_state_index = self.get_child_state_index_by_id(state_id)
	return self
