class_name StateQueue extends StateRunner

func advance_on(from: String, condition: Variant) -> StateQueue:
	if condition is String:
		self.on_message(condition, func(): self.transition_to(self.get_next_state_id()))
	else:
		var target_state: State = self.get_state(from)
		target_state.on(condition, func(): self.transition_to(self.get_next_state_id()))
	return self
	
func get_next_state_id() -> String:
	if self.current_state_index + 1 == len(self.child_states):
		return self.child_states[0].id
	return self.child_states[self.current_state_index + 1].id

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
	
func clear():
	self.queue.clear()
