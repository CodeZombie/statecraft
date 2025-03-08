class_name TransitionChainFrom

var state_runner: StateContainer
var from_state_ids: Array[StringName]

func _init(state_runner: StateContainer, from_state_ids: Array[StringName]):
	self.state_runner = state_runner
	self.from_state_ids = from_state_ids
	
func to(next_state_id: String) -> TransitionChainTo:
	return TransitionChainTo.new(self.state_runner, self.from_state_ids, next_state_id)

func to_dynamic(callable: Callable) -> StateContainer:
	for from_state_id in self.from_state_ids:
		self.state_runner.transition_dynamic(from_state_id, callable)
	return self.state_runner
		
