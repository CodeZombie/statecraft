class_name StateMachine extends StateQueue

class TransitionToState extends Message:
	var state_id: String
	func _init(recipient_state_id: String, state_id: String):
		super(recipient_state_id)
		self.state_id = state_id
		
class RestartCurrentState extends Message:
	pass

func _on_child_state_exited():
	pass

func set_initial_state(state_id: String):
	self.initial_state_index = self.get_child_state_index_by_id(state_id)
	return self
