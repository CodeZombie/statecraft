class_name StateMachineEventHandlerFactory extends EventHandlerFactory

func transition(from: Variant, to: StringName) -> State:
	if from is String:
		from = [from]
		
	var transition_callable: Callable = func(state_: StateMachine): state_.transition_to(to)
	print("Attaching transition from: {0} to {1}".format({0: from, 1: to}))
	self.event.attach_to_state(self.parent, self._wrap_callable(transition_callable), from)
	return self.parent

func transition_from_any(state_id: StringName) -> State:
	self.event.attach_to_state(self.parent, func(state: StateMachine): state.transition_to(state_id))
	return self.parent

func transition_dynamic(from: Variant, to: Callable) -> State:
	if from is String:
		from = [from]

	var transition_callable: Callable = func(state_: StateMachine):
		if from.has(state_.current_state):
			state_.transition_to_dynamic(to)

	self.event.attach_to_state(self.parent, self._wrap_callable(transition_callable), from)
	return self.parent
