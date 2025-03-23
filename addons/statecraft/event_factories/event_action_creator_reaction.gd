class_name EventActionCreatorReaction extends Object

var from_state_nodepaths: Array
var additional_condition: Callable
var parent: State
var event: StateEvent

func _init(parent: State, from_state_nodepaths: Array, event: StateEvent):
	self.parent = parent
	self.from_state_nodepaths = from_state_nodepaths
	self.event = event

func _wrap_additional_conditions(callable_: Callable) -> Callable:
	if self.additional_condition:
		var _additional_condition = self.additional_condition
		return func(state_: State):
			if SCUtils.call_with_possible_args(_additional_condition, [state_]):
				SCUtils.call_with_possible_args(callable_, [state_])
	else:
		return callable_

func and_if_true(callable: Callable) -> EventActionCreatorReaction:
	if self.additional_condition:
		var current_additional_condition = self.additional_condition
		self.additional_condition = func(state_: State) -> bool:
			return SCUtils.call_with_possible_args(current_additional_condition, [state_]) and SCUtils.call_with_possible_args(callable, [state_])
	else:
		self.additional_condition = callable
	return self

func and_if_false(callable: Callable) -> EventActionCreatorReaction:
	if self.additional_condition:
		var current_additional_condition = self.additional_condition
		self.additional_condition = func(state_: State) -> bool:
			return SCUtils.call_with_possible_args(current_additional_condition, [state_]) and not SCUtils.call_with_possible_args(callable, [state_])
	else:
		self.additional_condition = func(state_: State) -> bool: 
			return not SCUtils.call_with_possible_args(callable, [state_])

	return self

func then_call(callable: Callable) -> State:
	self.event.attach_to_state(self.parent, self._wrap_additional_conditions(callable), self.from_state_nodepaths)
	return self.parent
	
func then_emit(sig: Variant, args: Array = []) -> State:
	if sig is String or sig is StringName:
		self.event.attach_to_state(self.parent, self._wrap_additional_conditions(func(state_: State): 
			print("Attempting to call signal: ", sig)
			print("With args: ", args)
			
			state_.emit_signal.callv([sig] + args)), self.from_state_nodepaths)
	else:
		self.event.attach_to_state(self.parent, self._wrap_additional_conditions(func(): sig.emit.callv(args)), self.from_state_nodepaths)
	return self.parent
	
func then_broadcast(broadcast_name: StringName) -> State:
	self.event.attach_to_state(self.parent, self._wrap_additional_conditions(func(state_: State): state_.broadcast(broadcast_name)), self.from_state_nodepaths)
	return self.parent

func then_exit() -> State:
	self.event.attach_to_state(self.parent, self._wrap_additional_conditions(func(state_: State): state_.exit()), self.from_state_nodepaths)
	return self.parent

func then_transition_to(to: Variant) -> StateMachine:
	self.event.attach_to_state(self.parent, self._wrap_additional_conditions(func(state_: StateMachine): state_.transition_to(to)), self.from_state_nodepaths)
	return self.parent

func then_transition_to_dynamic(to_callable: Callable) -> StateMachine:
	self.event.attach_to_state(self.parent, self._wrap_additional_conditions(func(state_: StateMachine): state_.transition_to_dynamic(to_callable)), self.from_state_nodepaths)
	return self.parent
