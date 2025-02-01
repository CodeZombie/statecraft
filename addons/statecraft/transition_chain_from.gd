class_name TransitionChainFrom

var state_runner: StateRunner
var from_state_id: String

func _init(state_runner: StateRunner, from_state_id: String):
	self.state_runner = state_runner
	self.from_state_id = from_state_id
	
func to(next_state_id: String) -> TransitionChainTo:
	return TransitionChainTo.new(self.state_runner, self.from_state_id, next_state_id)
	
func to_dynamic(callable: Callable) -> StateRunner:
	self.state_runner.transition_dynamic(self.from_state_id, callable)
	return self.state_runner
		
