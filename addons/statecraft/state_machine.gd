class_name StateMachine extends StateContainer

var states: Dictionary[String, State] = {}

var current_state_id: String:
	set(value):
		var current_state = self.get_current_state()
		if current_state:
			current_state.reset()
		current_state_id = value

func connect_deferred_signals() -> void:
	super()
	for state in self.states.values():
		forward_deferred_signal_connections_to_child(state, self._deferred_signal_connections)

func copy(new_id: String = self.id, _new_state = null) -> StateMachine:
	return super(new_id, StateMachine.new(new_id) if not _new_state else _new_state)
	
func get_running_states() -> Array[State]:
	return [self.get_current_state()]

func add_state(state: State) -> StateMachine:
	if state.id in self.states:
		push_error("StateCraft Error: State with ID \"{0}\" already present in State Machine \"{1}\"".format({0: state.id, 1: self.id}))
	self.forward_deferred_signal_connections_to_child(state, self._deferred_signal_connections)
	self.states[state.id] = state
	if len(self.states) == 1:
		self.current_state_id = state.id
	return self
	
func get_state(id: String) -> State:
	return self.states[id]
	
func get_states(state_id: String) -> Array[State]:
	return [self.get_state(state_id)]
	
func get_current_state() -> State:
	if self.current_state_id in self.states.keys():
		return self.states[self.current_state_id]
	return null
	
func get_all_states() -> Array[State]:
	return self.states.values()
	
func update(delta: float, speed_scale: float = 1.0) -> bool:
	var r_val: bool = super(delta, speed_scale)
	if r_val:
		return true
	var current_state = self.get_current_state()
	if current_state:
		current_state.run(delta, speed_scale)
	return false

func transition_on_exit(from: String, to: String) -> StateContainer:
	self.get_state(from).on_exit_transition_method = self.transition_to.bind(to)
	return self
	
func from(state_id: String) -> TransitionChainFrom:
	return TransitionChainFrom.new(self, state_id)
	
func transition_dynamic(from: String, condition: Callable) -> StateContainer:
	self.actions.append(func():
		if self.current_state_id == from:
			if self.get_current_state().id == from and self.get_current_state().status == StateStatus.RUNNING:
				var return_value = condition.call(self) if condition.get_argument_count() > 0 else condition.call()
				if return_value:
					self.transition_to(return_value))
	return self
		
func transition_on(from: String, to: String, condition: Variant, additional_callable_condition: Variant = null) -> StateContainer:
	var transition_callable: Callable = self.transition_to.bind(to)
	if additional_callable_condition:
		transition_callable = func():
			if additional_callable_condition.call():
				self.transition_to(to)
				
	if condition is String:
		self.on_signal_path(condition, transition_callable)
	else:
		self.get_state(from).on(condition, transition_callable)
	return self
	
func transition_to(state_id: String) -> StateContainer:
	if state_id not in self.states.keys():
		assert(false, "StateCraft Error: Tried to transition to unknown state \"{0}\"".format({0: state_id}))
		
	self.current_state_id = state_id
	return self
