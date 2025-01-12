class_name StateQueue extends State

class TransitionToNextState extends Message:
	func _process(state_queue: StateQueue):
		var old_state_on_exit_return_value: Variant = state_queue._get_current_state().execute_on_exit_event()
		if old_state_on_exit_return_value:
			return old_state_on_exit_return_value
			
		if state_queue.current_state_index < len(state_queue.child_states) - 1:
			state_queue.current_state_index += 1
			return state_queue._get_current_state().execute_on_enter_event()
		else:
			if state_queue.on_finished_method:
				return state_queue.on_finished_method.call()
			else:
				# Restart the StateQueue
				return state_queue.execute_on_enter_event()
	
class RestartCurrentState extends Message:
	pass

var child_states: Array[State] = []
var initial_state_index: int = 0
var current_state_index: int
#var next_state_id: int = 0
var on_finished_method: Variant = null

func execute_on_enter_event() -> Variant:
	self.current_state_index = self.initial_state_index
	self._get_current_state().execute_on_enter_event()
	return super()

func add_state(state: State):
	for child_state in self.child_states:
		if child_state.id == state.id:
			push_error("StateCraft Error: State with ID \"{0}\" already present in State Container \"{1}\"".format({0: state.id, 1: self.id}))
	self.child_states.push_back(state)
	return self
	
func set_on_finished(on_finished_method: Callable) -> StateQueue:
	self.on_enter_method = on_enter_method
	return self
	
func execute_on_finished_event() -> Variant:
	if self.on_finished_method:
		return self.on_finished_method.call()
	return null
		
func get_state(state_id: String) -> State:
	return self.child_states[self.get_child_state_index_by_id(state_id)]
	
func process_immediately():
	self.skip_all_skippable_states()
	for event in self.queue:
		event.process_immediately()
	self.queue.clear()

func get_current_state_id():
	return self.child_states[self.current_state_index].id

func get_child_state_index_by_id(state_id: String):
	for i in range(len(self.child_states)):
		if self.child_states[i].id == state_id:
			return i
	push_error("Statecraft Error: No child state \"", state_id, "\" could be found within \"", self.id, "\"")
	
func _get_current_state() -> State:
	return self.child_states[self.current_state_index]
	
#func transition_to(state_id: String):
	#self._get_current_state().exit()
	#self.next_state_id = get_child_state_index_by_id(state_id)

func skip_all_skippable_states():
	self.queue = self.queue.filter(func(event): return not event.skippable)
	for state_queue in self.queue.filter(func(event): return event is StateQueue):
		state_queue.skip_all_skippable_events()

#func _on_child_state_exited():
	#if self.current_state_index < len(self.child_states) - 1:
		#self.next_state_id = self.current_state_index + 1
	##else:
		##self.exit()

func execute_on_update_event(delta: float, speed_scale: float = 1.0):
	super(delta, speed_scale)
		
	var current_state_on_update_return_value: Variant = self._get_current_state().execute_on_update_event(delta, speed_scale)
	if current_state_on_update_return_value:
		return self._handle_message(current_state_on_update_return_value)
		
func clear():
	self.queue.clear()
	
func _handle_message(message: Message) -> Variant:
	# Checks to see if a message is targetting this node.
	# If it is, execute the message, returning anything it returns.
	# if it isn't, return the message so that it can be handled by the parent State.
	if message.recipient_state_id == null or message.recipient_state_id == self.id:
		return message._process(self)
	return message
	
func get_debug_string() -> String:
	var s: String = "\n" + self.id + ": " + self.get_status_string()
	for child_state in self.child_states:
		s += "\n   " + child_state.get_debug_string()
	return s
