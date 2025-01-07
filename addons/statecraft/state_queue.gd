class_name StateQueue extends State

var child_states: Array[State] = []
var initial_state_index: int = 0
var current_state_index: int
var next_state_id: int = 0

func _on_enter(state_stack):
	self.current_state_index = self.initial_state_index
	super(state_stack)

func add_state(event: State):
	self.child_states.push_back(event)
	return self
	
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
	
func transition_to(state_id: String):
	self._get_current_state().exit()
	self.next_state_id = get_child_state_index_by_id(state_id)

func skip_all_skippable_states():
	self.queue = self.queue.filter(func(event): return not event.skippable)
	for state_queue in self.queue.filter(func(event): return event is StateQueue):
		state_queue.skip_all_skippable_events()

func _on_child_state_exited():
	if self.current_state_index < len(self.child_states) - 1:
		self.next_state_id = self.current_state_index + 1
	else:
		self.exit()

func _on_update(state_stack, delta: float, speed_scale: float = 1.0):
	super(state_stack, delta, speed_scale)
	
	# If the current state has ended, transition to the next one.
	if self._get_current_state()._status == Status.WAITING_TO_EXIT:
		self._get_current_state()._on_exit([self] + state_stack)
		self._on_child_state_exited()
		self.current_state_index = self.next_state_id
		
	elif self._get_current_state()._status == Status.READY:
		self._get_current_state()._on_enter([self] + state_stack)
		
	elif self._get_current_state()._status == Status.RUNNING:
		self.child_states[self.current_state_index]._on_update([self] + state_stack, delta, speed_scale)

func clear():
	self.queue.clear()
	
func get_debug_string() -> String:
	var s: String = "\n" + self.id + ": " + self.get_status_string()
	for child_state in self.child_states:
		s += "\n   " + child_state.get_debug_string()
	return s
