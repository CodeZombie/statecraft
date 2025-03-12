class_name EventHandlerFactory extends Object

var parent: State
var event: Event
var additional_condition: Callable

func _init(parent: State, event: Variant):
	self.parent = parent
	self.event = event

static func _weakref_bind(state: State, callable: Callable, invert: bool = false) -> Callable:
	var callable_args: int = callable.get_argument_count()
	if callable_args == 0:
		if invert:
			return func(): return not callable.call()
		else:
			return callable

	var bound_callable: Callable
	if callable_args == 0:
		return callable
	elif callable_args == 1:
		return func(state_: State):
			return callable.call(state_)
	else:
		return callable

# static func _state_call(state_: State, callable: Callable) -> Variant:
# 	if callable.get_argument_count() == 1:
# 		return callable.call(state_)
# 	else:
# 		return callable.call()
	
# TODO: Optimize this with `bind` so that we don't have to check the argument count every time we call the callable or condition
func _wrap_additional_conditions(callable_: Callable) -> Callable:
	if self.additional_condition:
		var _additional_condition = self.additional_condition
		return func(state_: State):
			if SCUtils.call_with_possible_args(_additional_condition, [state_]):
				SCUtils.call_with_possible_args(callable_, [state_])
	else:
		return callable_

		
	
func also(callable: Callable) -> EventHandlerFactory:
	if self.additional_condition:
		var current_additional_condition = self.additional_condition
		self.additional_condition = func(state_: State) -> bool:
			return SCUtils.call_with_possible_args(current_additional_condition, [state_]) and SCUtils.call_with_possible_args(callable, [state_])
			#return EventHandlerFactory._state_call(state_, current_additional_condition) and State._call_with_optional_state(state_, callable)
	else:
		self.additional_condition = callable
	return self

func also_inv(callable: Callable) -> EventHandlerFactory:
	if self.additional_condition:
		var current_additional_condition = self.additional_condition
		self.additional_condition = func(state_: State) -> bool:
			return SCUtils.call_with_possible_args(current_additional_condition, [state_]) and not SCUtils.call_with_possible_args(callable, [state_])
	else:
		self.additional_condition = func(state_: State) -> bool: 
			return not SCUtils.call_with_possible_args(callable, [state_])

	return self

func then_call(callable: Callable) -> State:
	self.event.attach_to_state(self.parent, self._wrap_additional_conditions(callable))
	return self.parent
	
func then_emit_signal(sig: Variant) -> State:
	if sig is String:
		self.event.attach_to_state(self.parent, self._wrap_additional_conditions(func(state_: State): state_.emit_signal(sig)))
	else:
		self.event.attach_to_state(self.parent, self._wrap_additional_conditions(func(): sig.emit()))
	return self.parent
	
func then_broadcast(broadcast_name: StringName) -> State:
	self.event.attach_to_state(self.parent, self._wrap_additional_conditions(func(state_: State): state_.broadcast(broadcast_name)))
	return self.parent

func then_exit() -> State:
	self.event.attach_to_state(self.parent, self._wrap_additional_conditions(func(state_: State): state_.exit()))
	return self.parent
