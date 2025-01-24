class_name StateQueue extends StateRunner

#class TransitionToNextState extends Message:
	#func _to_string() -> String:
		#return "TransitionToNextState"
		#
	#func _process(state_queue: StateQueue):
		#var old_state_on_exit_return_value: Variant = state_queue._get_current_state().execute_on_exit_event()
		#if old_state_on_exit_return_value:
			#return old_state_on_exit_return_value
			#
		#if state_queue.current_state_index < len(state_queue.child_states) - 1:
			#state_queue.current_state_index += 1
			#return state_queue._get_current_state().execute_on_enter_event()
		#else:
			#if state_queue.on_finished_method:
				#return state_queue.on_finished_method.call()
			#else:
				## Restart the StateQueue
				#return state_queue.execute_on_enter_event()

#var on_finished_method: Variant = null

func _init(id: String, skippable: bool = false):
	super(id, skippable)
	
#func transition_on(state_id: String, condition_id: Variant) -> StateRunner:
	#self.on_condition_met(state_id, condition_id, self.transition_to_next_state.bind())
	#return self

func advance_on(from: String, condition: Variant) -> StateQueue:
	if condition is String:
		self.on_message(condition, func(): self.transition_to(self.get_next_state_id()))
	else:
		var target_state: State = self.get_state(from)
		target_state.on(condition, func(): self.transition_to(self.get_next_state_id()))
	return self
	
#func transition_from(state_id: String) -> StateEvent:
	#if state_id not in self.state_events.keys():
		#self.state_events[state_id] = []
	#var state_event = StateEvent.new()
	#state_event.event = func(state_queue: StateQueue): state_queue.transition_to(self.get_next_state_id())
	#self.state_events[state_id].append(state_event)
	#return state_event

func get_next_state_id() -> String:
	if self.current_state_index + 1 == len(self.child_states):
		return self.child_states[0].id
	return self.child_states[self.current_state_index + 1].id
	

#func add_advance(from_state_id: String, condition: Variant) -> StateRunner:
	#if from_state_id not in self.transitions.keys():
		#self.transitions[from_state_id] = []
	#if condition is String:
		#condition = self.get_callable_from_condition_path(condition)
	#self.transitions[from_state_id].append(
		#StateEvent.new(
			#func(state):
				#state.transition_to(state.get_next_state_id()), 
			#condition))
	#return self

#func transition_to_next_state_on(from_state_id: String, condition: Callable) -> StateRunner:
	#self.transition_conditions.append(TransitionCondition.new(
		#from_state_id, 
		#func(): return to_state_id,
		#condition))
	#return self

#func transition_to_next_state() -> void:
	#self.get_current_state().exit()
	#if self.current_state_index < len(self.child_states) - 1:
		#self.current_state_index += 1
		#self.get_current_state().enter()
	#else:
		#self.restart()

func enter():
	self.current_state_index = 0
	super()
	
func process_immediately():
	self.skip_all_skippable_states()
	for event in self.queue:
		event.process_immediately()
	self.queue.clear()
	
func skip_all_skippable_states():
	self.queue = self.queue.filter(func(event): return not event.skippable)
	for state_queue in self.queue.filter(func(event): return event is StateQueue):
		state_queue.skip_all_skippable_events()

func update(delta: float, speed_scale: float = 1.0):
	super(delta, speed_scale)
	var current_state = self.get_current_state()
	if not current_state:
		return null
	current_state.update(delta, speed_scale)
	
	#if current_state.id in self.state_events.keys():
		#for state_event in self.state_events[current_state.id]:
			#if state_event.is_condition_met(self):
				#state_event.execute_event(self)
	
func clear():
	self.queue.clear()
