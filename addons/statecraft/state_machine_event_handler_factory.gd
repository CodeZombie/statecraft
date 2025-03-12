class_name StateMachineEventHandlerFactory extends EventHandlerFactory
	
func then_transition(from: Array, to: Variant) -> StateMachine:

	var wrapped_callable: Callable
	
	if to is NodePath:
		wrapped_callable = self._wrap_additional_conditions(
			func(state: StateMachine): 
				state.transition_to(to))
	else:
		wrapped_callable = self._wrap_additional_conditions(
			func(state_: StateMachine): 
				state_.transition_to_dynamic(to))
	
	# TODO: why the fuck is this necessary.
	# Why can't we just have `from: Array[NodePath]` in the type definition in the args for `from`
	# and it just autocasts everything to NodePath?
	# Why does that not work????
	var from_: Array[NodePath] = []
	for v in from:
		from_.append(NodePath(v))
	
	self.event.attach_to_state(self.parent, wrapped_callable, from_)
	return self.parent

func then_transition_from_any(to: Variant) -> StateMachine:
	var wrapped_callable: Callable
	
	if to is NodePath:
		wrapped_callable = self._wrap_additional_conditions(func(state: StateMachine): state.transition_to(to))
				
	else:
		wrapped_callable = self._wrap_additional_conditions(func(state_: StateMachine): state_.transition_to_dynamic(to))

	self.event.attach_to_state(self.parent, wrapped_callable)
	return self.parent

#func transition_dynamic(from: Variant, to: Callable) -> State:
	#if from is String:
		#from = [from]
#
	#var wrapped_callable: Callable = self._wrap_additional_conditions(
		#func(state_: StateMachine):
			#state_.transition_to_dynamic(to))
#
	#self.event.attach_to_state(self.parent, wrapped_callable, from)
	#return self.parent


##  UGHGHHGHG

#
#func also(callable: Callable) -> StateMachineEventHandlerFactory:
	#return super(callable)
#
#func also_inv(callable: Callable) -> StateMachineEventHandlerFactory:
	#if self.additional_condition:
		#var current_additional_condition = self.additional_condition
		#self.additional_condition = func(state_: State) -> bool:
			#return SCUtils.call_with_possible_args(current_additional_condition, [state_]) and not SCUtils.call_with_possible_args(callable, [state_])
	#else:
		#self.additional_condition = func(state_: State) -> bool: 
			#return not SCUtils.call_with_possible_args(callable, [state_])
#
	#return self
#
#func then_call(callable: Callable) -> StateMachine:
	#return super(callable)
	#
#func then_emit_signal(sig: Variant) -> StateMachine:
	#return super(sig)
	#
#func then_broadcast(broadcast_name: StringName) -> StateMachine:
	#return super(broadcast_name)
#
#func then_exit() -> StateMachine:
	#return super()
