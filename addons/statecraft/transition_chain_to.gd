class_name TransitionChainTo

var state_runner: StateRunner
var from_state_id: String
var to_state_id: String

func _init(state_runner: StateRunner, from_state_id: String, to_state_id: String):
	self.state_runner = state_runner
	self.from_state_id = from_state_id
	self.to_state_id = to_state_id
	
func on(condition: Variant, secondary_callable_condition: Variant = null) -> StateRunner:
	self.state_runner.transition_on(self.from_state_id, self.to_state_id, condition, secondary_callable_condition)
	return state_runner

func on_exit() -> StateRunner:
	self.state_runner.transition_on_exit(self.from_state_id, self.to_state_id)
	return self.state_runner
