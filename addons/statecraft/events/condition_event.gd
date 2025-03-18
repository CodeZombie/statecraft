class_name ConditionEvent extends Event

var condition: Callable
var invert: bool

func _init(condition: Callable, invert: bool = false):
	self.condition = condition
	self.invert = invert

func attach_to_state(state: State, callable: Callable, target_state_paths: Array = [^""]) -> void:
	var bound_condition: Callable = SCUtils.weakbind_state_to_callable(state, self.condition)
	if self.invert:
		bound_condition = func(): return not bound_condition.call()

	var bound_callable: Callable = SCUtils.weakbind_state_to_callable(state, callable)

	for target_state_path in target_state_paths:
		state.recieve_message(RelayMessage.new(
			target_state_path,
			&"add_on_condition_event",
			[bound_condition, bound_callable],
		))
