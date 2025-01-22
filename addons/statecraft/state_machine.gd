class_name StateMachine extends StateRunner

#var transition_handlers: Dictionary[String, Array] = {}


#class TransitionToState extends Message:
	#var state_id: String
	#func _to_string() -> String:
		#return "TransitionToState(\"{0}\")".format({0: self.state_id})
		#
	#func _init(recipient_state_id: String, state_id: String):
		#super(recipient_state_id)
		#self.state_id = state_id
		
#class RestartCurrentState extends Message:
	#func _to_string() -> String:
		#return "RestartCurrentState"

#func _on_child_state_exited():
	#pass
#

#
#func transition_on_condition(from_state_id: String, to_state_id: String, condition: Callable) -> StateMachine:
	#if from_state_id not in self.transition_handlers.keys():
		#self.transition_handlers[from_state_id] = []
	#
	#self.transition_handlers[from_state_id].append({
		#to_state_id: to_state_id,
		#condition: condition
	#})
	#return self

func set_initial_state(state_id: String):
	self.initial_state_id = state_id
	return self
