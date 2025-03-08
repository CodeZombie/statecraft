class_name StateMachine extends StateContainer

var states: Dictionary[String, State] = {}

var initial_state_id: StringName
var current_state_id: StringName:
	set(value):
		var previously_current_state = self.get_current_state()
		if previously_current_state:
			previously_current_state.exit()
		current_state_id = value
		var new_current_state = self.get_state(value)
		new_current_state.reset()
		

func on_enter() -> StateMachineEventHandlerFactory:
	return StateMachineEventHandlerFactory.new(self, SignalPathEvent.new(&"entered"))

func on_update() -> StateMachineEventHandlerFactory:
	return StateMachineEventHandlerFactory.new(self, SignalPathEvent.new(&"updated"))

func on_exit() -> StateMachineEventHandlerFactory:
	return StateMachineEventHandlerFactory.new(self, SignalPathEvent.new(&"exited"))

func on_broadcast(broadcast_name: StringName) -> StateMachineEventHandlerFactory:
	return StateMachineEventHandlerFactory.new(self, BroadcastEvent.new(broadcast_name))

func on_signal(sig: Signal) -> StateMachineEventHandlerFactory:
	return StateMachineEventHandlerFactory.new(self, SignalEvent.new(sig))

func on_signal_path(signal_path: String) -> StateMachineEventHandlerFactory:
	return StateMachineEventHandlerFactory.new(self, SignalPathEvent.new(signal_path))

func on_timer(duration: float) -> StateMachineEventHandlerFactory:
	return StateMachineEventHandlerFactory.new(self, TimerEvent.new(duration))

func on(condition: Callable) -> StateMachineEventHandlerFactory:
	return StateMachineEventHandlerFactory.new(self, ConditionEvent.new(condition))
	
func on_inv(condition: Callable) -> StateMachineEventHandlerFactory:
	return StateMachineEventHandlerFactory.new(self, ConditionEvent.new(condition, true))


func on_child_entered(child_state_path: StringName) -> StateMachineEventHandlerFactory:
	return self.on_signal_path("{}.entered".format({0:on_signal_path}))
	#return StateMachineEventHandlerFactory.new(self, ChildStateEvent.new(child_state_path, ChildStateEvent.EventType.ENTERED))

func on_child_updated(child_state_path: StringName) -> StateMachineEventHandlerFactory:
	return self.on_signal_path("{}.updated".format({0:on_signal_path}))
	#return StateMachineEventHandlerFactory.new(self, ChildStateEvent.new(child_state_path, ChildStateEvent.EventType.UPDATED))

func on_child_exited(child_state_path: StringName) -> StateMachineEventHandlerFactory:
	return self.on_signal_path("{}.entered".format({0:on_signal_path}))
	#return StateMachineEventHandlerFactory.new(self, ChildStateEvent.new(child_state_path, ChildStateEvent.EventType.EXITED))

	
###
### This is psychotic - way too many interfaces. Refactor all this shit.
###

func copy(new_id: StringName = self.id, _new_state = null) -> StateMachine:
	return super(new_id, StateMachine.new(new_id) if not _new_state else _new_state)
	
func get_running_states() -> Array[State]:
	return [self.get_current_state()]

func is_state_running(state_id: StringName) -> bool:
	return self.current_state_id == state_id

func add_state(state: State) -> StateMachine:
	if state.id in self.states:
		push_error("StateCraft Error: State with ID \"{0}\" already present in State Machine \"{1}\"".format({0: state.id, 1: self.id}))
	self.propagate_permanent_messages_to_relay_node(state)
	self.states[state.id] = state
	if len(self.states.keys()) == 1:
		self.initial_state_id = state.id
	return self
	
func get_state(id: StringName) -> State:
	if id not in self.states.keys():
		assert(false, "No state with id \"{0}\" in State Machine {1}".format({0: id, 1: self.id}))
	return self.states[id]
	
func get_states(state_id: StringName) -> Array[State]:
	return [self.get_state(state_id)]
	
func get_children() -> Array:
	return self.states.values()
	
func get_current_state() -> State:
	if self.current_state_id in self.states.keys():
		return self.states[self.current_state_id]
	return null
	
func get_all_states() -> Array[State]:
	return self.states.values()
	
func enter() -> bool:
	if self._debug: print(self.id, " ENTER (StateMachine)")
	if len(self.states) == 0:
		super()
		exit()
		return true
	if not self.current_state_id:
		self.current_state_id = self.initial_state_id
	return super()
	
func update(delta: float, speed_scale: float = 1.0) -> bool:
	if self._debug: print(self.id, "UPDATE (StateMachine)")
	var r_val: bool = super(delta, speed_scale)
	if r_val:
		return true
	var current_state = self.get_current_state()
	if current_state:
		current_state.run(delta, speed_scale)
	return false
	
func exit() -> bool:
	if self._debug: print(self.id, " EXIT (StateMachine)")
	for state in self.get_children():
		state.exit()
	var x = super()
	#self.current_state_id = self.initial_state_id
	return x

# func transition_on_exit(from: StringName, to: StringName) -> StateContainer:
# 	self.get_state(from).exited.connect(self.transition_to.bind(to))
# 	return self
	
# func from(state_id: StringName) -> TransitionChainFrom:
# 	return TransitionChainFrom.new(self, [state_id])
	
# func from_any(state_ids: Array[StringName]) -> TransitionChainFrom:
# 	return TransitionChainFrom.new(self, state_ids)

# TODO: Finish fixing this
# func transition_dynamic(from: StringName, condition: Callable) -> StateContainer:
# 	self.recieve_message(RelayMessage.new(
# 		from,
# 		RelayMessage.Type.CALL_METHOD,
# 		#{'bound_callable': State.on.bind(
# 			#func() -> bool:
# 				#return true,
# 			#func():
# 				#return false
# 				#)
# 		#}
# 	))
# 	self.actions.append(func():
# 		if self.current_state_id == from:
# 			if self.get_current_state().id == from and self.get_current_state().status == StateStatus.RUNNING:
# 				var return_value = condition.call(self) if condition.get_argument_count() > 0 else condition.call()
# 				if return_value:
# 					self.transition_to(return_value))
# 	return self
		
# func transition_on(from: StringName, to: StringName, condition: Variant, additional_callable_condition: Variant = null) -> StateContainer:
# 	var transition_callable: Callable = self.transition_to.bind(to)
# 	if additional_callable_condition:
# 		transition_callable = func():
# 			if additional_callable_condition.call():
# 				self.transition_to(to)
				
# 	if condition is String:
# 		self.on_signal_path(condition, transition_callable)
# 	else:
# 		self.get_state(from).on(condition, transition_callable)
# 	return self
	
func transition_to(state_id: StringName) -> StateContainer:
	if self._debug: print("{0}.transitioning from {from} to {to}".format({0: self.id, 'from': current_state_id, 'to': state_id}))
	var state_path: Array
	if state_id.contains('.'):
		state_path = Array(state_id.split('.'))
		state_id = state_path.pop_front()
	
	var target_state: State = self.get_state(state_id)
	
	if not target_state:
		assert(false, "StateMachine {0} tried to transition to unknown state \"{1}\"".format({0: self.id, 1: state_id}))
		
	self.current_state_id = state_id
	
	if state_path:
		self.get_current_state().transition_to('.'.join(state_path))
	
	return self
	
#func sq_t_to(state_id: StringName) -> StateContainer:
	#var state_path: Array = Array(state_id.split('.'))
	#if len(state_path) == 1:
		#assert(false, "StateQueues cannot be manually transitioned")
	#
	#var target_state_id: String = state_path.pop_front()
	#var target_states: Array[State] = self.get_states(target_state_id)
	#if len(target_states) == 0:
		#assert(false, "StateQueue attempting to pass transition to child, but child \"{}\" was not found".format({0: target_state_id}))
	#
	#
	
func transition_to_dynamic(state_id_return_method: Callable) -> StateMachine:
	self.transition_to(State._call_with_optional_state(self, state_id_return_method))
	return self
