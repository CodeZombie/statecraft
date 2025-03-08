class_name EventHandlerFactory extends Object

var parent: State
var event: Event
var additional_condition: Callable

func _init(parent: State, event: Variant):
	self.parent = parent
	self.event = event

static func _state_call(state_: State, callable: Callable) -> Variant:
	if callable.get_argument_count() == 1:
		return callable.call(state_)
	else:
		return callable.call()
	
func _wrap_callable(callable_: Callable) -> Callable:
	if self.additional_condition:
		var _additional_condition = self.additional_condition
		return func(state_: State):
			if State._call_with_optional_state(state_, _additional_condition):
				State._call_with_optional_state(state_, callable_)
	else:
		return callable_
	
func also(callable: Callable) -> EventHandlerFactory:
	if self.additional_condition:
		var current_additional_condition = self.additional_condition
		self.additional_condition = func(state_: State) -> bool:
			return EventHandlerFactory._state_call(state_, current_additional_condition) and State._call_with_optional_state(state_, callable)
	else:
		self.additional_condition = callable
	return self

func also_inv(callable: Callable) -> EventHandlerFactory:
	if self.additional_condition:
		var current_additional_condition = self.additional_condition
		self.additional_condition = func(state_: State) -> bool:
			return State._call_with_optional_state(state_, current_additional_condition) and not State._call_with_optional_state(state_, callable)
	else:
		self.additional_condition = func(state_: State) -> bool: return not State._call_with_optional_state(state_, callable)
	return self

func then_execute(callable: Callable) -> State:
	self.event.attach_to_state(self.parent, self._wrap_callable(callable))
	return self.parent
	
func then_emit_signal(sig: Variant) -> State:
	if sig is String:
		self.event.attach_to_state(self.parent, self._wrap_callable(func(state_: State): state_.emit_signal(sig)))
	else:
		self.event.attach_to_state(self.parent, func(): sig.emit())
	return self.parent
	
func then_broadcast(broadcast_name: StringName) -> State:
	self.event.attach_to_state(self.parent, self._wrap_callable(func(state_: State): state_.broadcast(broadcast_name)))
	return self.parent

func then_exit() -> State:
	self.event.attach_to_state(self.parent, self._wrap_callable(func(state_: State): state_.exit()))
	return self.parent
