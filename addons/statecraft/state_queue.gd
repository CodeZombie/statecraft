class_name StateQueue extends StateRunner

var loop = false

func update(delta: float, speed_scale: float = 1.0) -> bool:
	var r_val: bool = super(delta, speed_scale)
	if r_val:
		return true

	if self.get_current_state().run(delta, speed_scale):
		if not self.advance() and loop == false:
			return true
	return false
		

func advance_on(from: String, condition: Variant) -> StateQueue:
	if condition is String:
		self.on_message(condition, self.advance)
	else:
		var target_state: State = self.get_state(from)
		target_state.on(condition, self.advance)
	return self
	
func advance() -> bool:
	var next_state_id: Variant = self.get_next_state_id()
	if next_state_id == null:
		return false
	self.transition_to(self.get_next_state_id())
	return true
	
func get_next_state_id() -> Variant:
	if self.current_state_index == len(self.child_states) - 1:
		if self.loop:
			return self.child_states[0].id
		return null
	return self.child_states[self.current_state_index + 1].id

func enter():
	self.current_state_index = 0
	super()
	
#func add_state(state: State) -> StateRunner:
	#super(state)
	#state.add_exit_event(self.advance)
	#return self
	
func process_immediately():
	self.skip_all_skippable_states()
	for event in self.queue:
		event.process_immediately()
	self.queue.clear()
	
func skip_all_skippable_states():
	self.queue = self.queue.filter(func(event): return not event.skippable)
	for state_queue in self.queue.filter(func(event): return event is StateQueue):
		state_queue.skip_all_skippable_events()
	
func clear():
	self.queue.clear()

func copy(new_id: String = self.id, _new_state = null) -> StateQueue:
	return super(new_id, StateQueue.new(new_id) if not _new_state else _new_state)
