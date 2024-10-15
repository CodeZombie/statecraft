class_name StateQueue extends State

var child_states: Array[State] = []
var current_state_index: int = 0

func _on_enter():
	self.current_state_index = 0
	super()

func add_state(event: State):
	self.child_states.push_back(event)
	return self

func process_immediately():
	self.skip_all_skippable_events()
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
	
func transition_to(state_id: String):
	if self.child_states[self.current_state_index]._state != StateState.EXITING:
		self.child_states[self.current_state_index]._on_exit(true)
	self.current_state_index = get_child_state_index_by_id(state_id)

func skip_all_skippable_events():
	self.queue = self.queue.filter(func(event): return not event.skippable)
	for state_queue in self.queue.filter(func(event): return event is StateQueue):
		state_queue.skip_all_skippable_events()

func _on_child_state_exited():
	if self.current_state_index < len(self.child_states) - 1:
		self.current_state_index += 1
	else:
		return State.exit()

func _on_update(delta: float, speed_scale: float = 1.0):
	var my_command = super(delta, speed_scale)
	if my_command is State.EXIT_COMMAND:
			return my_command

	if self.child_states[self.current_state_index]._state == StateState.WAITING:
		self.child_states[self.current_state_index]._on_enter()
		
	var child_state_command = self.child_states[self.current_state_index]._on_update(delta, speed_scale)
	
	if child_state_command is State.EXIT_COMMAND:
		self.child_states[self.current_state_index]._on_exit()
		return self._on_child_state_exited()
				
func clear():
	self.queue.clear()
