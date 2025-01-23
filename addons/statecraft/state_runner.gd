class_name StateRunner extends State

#class StateEvent:
	#var event: Callable
	#var condition: Variant = null
	#var condition_path: String
		#
	#func is_condition_met(state_runner: StateRunner) -> bool:
		#if not self.condition and self.condition_path:
			#self.condition = state_runner.get_callable_from_condition_path(self.condition_path)
		#return self.condition.call()
		#
	#func execute_event(state: State):
		#self.event.call(state)
		#
	## Chaining methods
	#func to(state_id: String) -> StateEvent:
		#self.event = func(state_runner: StateRunner):
			#state_runner.transition_to(state_id)
		#return self
		#
	#func on(condition: Variant) -> StateEvent:
		#if condition is String:
			#self.condition_path = condition
		#elif condition is Callable:
			#self.condition = condition
		#else:
			#assert(false, "Invalid condition type: {0}".format({0: typeof(condition)}))
		#return self


#var child_states: OrderedDictionary = OrderedDictionary.new()
var child_states: Array[State]
#var initial_state_id: String
var current_state_index: int = 0
#var state_events: Dictionary[String, Array] = {}
var transitions: Array[Callable] = []


func _init(id: String, skippable: bool = false):
	
	self.child_states = []
	self.add_enter_method(func():
		#self.current_state_index = self.get_child_state_index_by_id(self.initial_state_id)
		self.current_state_index = 0
		var current_state = self.get_current_state()
		if current_state:
			current_state.enter())
			
	self.add_exit_method(func():
		var current_state = self.get_current_state()
		if current_state and current_state._status == Status.RUNNING:
			current_state.exit())
	super(id, skippable)

func update(delta: float, speed_scale: float = 1):
	super(delta, speed_scale)
	var current_state = self.get_current_state()
	if current_state:
		self.get_current_state().update(delta, speed_scale)
	
	for transition_callable in self.transitions:
		transition_callable.call()

#func transition_from(state_id: String) -> StateEvent:
	#if state_id not in self.state_events.keys():
		#self.state_events[state_id] = []
		#
	#var state_event = StateEvent.new()
	#self.state_events[state_id].append(state_event)
	#return state_event
	
#func transition_on_signal(from: String, to: String, sig: Signal):
	#sig.connect(func(): if self.get_current_state().id == from: self.transition_to(to))
	#
#func transition_on_message(from: String, to: String, message_path: String):
	#self.transitions.append(func():
		#if self.get_current_state().id == from:
			#if self.get_callable_from_condition_path(message_path).call():
				#self.transition_to(to)
		#)

func transition_dynamic(from: String, condition: Callable):
	self.transitions.append(func():
		if self.get_current_state().id == from:
			var return_value = condition.call()
			if return_value:
				self.transition_to(return_value))
			
func on(from: String, condition: Variant, callable: Callable):
	if condition is Signal:
		condition.connect(func(): if self.get_current_state().id == from: callable.call())
		
	elif condition is String:
		self.get_state_from_message_path(condition).add_message_handler(self.get_message_id_from_message_path(condition), callable)
					
	elif condition is Callable:
		self.transitions.append(func():
			if self.get_current_state().id == from:
				if condition.call():
					callable.call())

func transition_on(from: String, to: String, condition: Variant):
	self.on(from, condition, self.transition_to.bind(to))
	#if condition is Signal:
		#condition.connect(func(): if self.get_current_state().id == from: self.transition_to(to))
		#
	#elif condition is String:
		#self.transitions.append(func():
			#if self.get_current_state().id == from:
				#if self.get_callable_from_condition_path(condition).call():
					#self.transition_to(to))
					#
	#elif condition is Callable:
		#self.transitions.append(func():
			#if self.get_current_state().id == from:
				#if self.condition.call():
					#self.transition_to(to))
			
func add_state(state: State):
	if self.get_state(state.id):
		push_error("StateCraft Error: State with ID \"{0}\" already present in State Runner \"{1}\"".format({0: state.id, 1: self.id}))
	self.child_states.append(state)
	#if self.child_states.length() == 1:
		#self.initial_state_id = state.id
	return state

func get_state_from_message_path(message_path: String) -> State:
	var path_components: Array = Array(message_path.split("."))
	var message_id: String = path_components.pop_back()
	var current_state = self
	for path_component in path_components:
		current_state = current_state.get_state(path_component)
	return current_state
	
func get_message_id_from_message_path(message_path: String) -> String:
	var path_components: Array = Array(message_path.split("."))
	return path_components.pop_back()

#func get_callable_from_condition_path(condition_path: String):
	#var path_components: Array = Array(condition_path.split("."))
	#var condition_id: String = path_components.pop_back()
	#var current_state = self
	#for path_component in path_components:
		#current_state = current_state.get_state(path_component)
	#return current_state.get_condition(condition_id)

func get_state(state_id: String) -> State:
	for child_state in self.child_states:
		if child_state.id == state_id:
			return child_state
	return null
	#return self.child_states.get_value(state_id)
	
func get_current_state() -> State:
	if self.current_state_index < len(self.child_states):
		#return self.child_states.get_at_index(self.current_state_index)
		return self.child_states[self.current_state_index]
	return null
	
#func add_transition(from_state_id: String, to_state_id: String, condition: Variant) -> StateRunner:
	#if from_state_id not in self.state_events.keys():
		#self.state_events[from_state_id] = []
	#if condition is String:
		#condition = self.get_callable_from_condition_path(condition)
	#var state_event = StateEvent.new()
	#state_event.event = func(state): state.transition_to(to_state_id)
	#state_event.condition = condition
	#self.state_events[from_state_id].append(state_event)
	#return self
	
func transition_to(state_id: String):
	if not self.get_current_state():
		return
	self.get_current_state().exit()
	self.current_state_index = self.get_state_index(state_id)
	if self.current_state_index == -1:
		assert(false, "StateCraft Error: Tried to transition to unknown state \"{0}\"".format({0: state_id}))
	self.get_current_state().enter()


#func on_condition_met(state_id: String, condition_id: String, handler: Callable) -> StateRunner:
	#if state_id not in self.condition_handlers.keys():
		#self.condition_handlers[state_id] = {}
	#if condition_id not in self.condition_handlers[state_id].keys():
		#self.condition_handlers[state_id][condition_id] = []
	#self.condition_handlers[state_id][condition_id].append(handler)
	#return self
	
func get_state_index(state_id: String):
	for i in range(len(self.child_states)):
		if self.child_states[i].id == state_id:
			return i
	return -1
	
func as_string(indent: int = 0) -> String:
	var indent_string: String = ""
	for i in range(indent):
		indent_string += " "
	var s: String = indent_string + self.id + ": " + self.get_status_string() + " : " + str(len(self.child_states))
	for child_state in self.child_states:
		s += "\n" + child_state.as_string(indent + 4)
	return s
