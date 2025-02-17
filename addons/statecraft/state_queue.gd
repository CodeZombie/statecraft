class_name StateQueue extends StateRunner

enum ExecutionMode {SERIAL, PARALLEL}
enum ExitPolicy {KEEP, REMOVE}

var _execution_mode: ExecutionMode = ExecutionMode.SERIAL
var _exit_policy: ExitPolicy = ExitPolicy.KEEP
var _parallel_exited_states: Array[State] = []

var _child_states: Array[State] = []
var _exited_child_states: Array[State] = []

func add_state(state: State) -> StateRunner:
	return self.add_state_back(state)

func add_state_back(state: State) -> StateRunner:
	self._child_states.push_back(state)
	return self
	
func add_state_front(state: State) -> StateRunner:
	self._child_states.push_front(state)
	return self

func get_current_state() -> State:
	if len(self._child_states) > 0:
		return self._child_states[0]
	return null
	
func get_all_states() -> Array[State]:
	return self._exited_child_states + self._child_states

func enter() -> bool:
	self._child_states = self._exited_child_states + self._child_states
	self._exited_child_states = []
	
	self._parallel_exited_states = []
	return super()

func update(delta: float, speed_scale: float = 1.0) -> bool:
	var r_val: bool = super(delta, speed_scale)
	if r_val:
		return true
				
	if self._execution_mode == ExecutionMode.SERIAL:
		var current_state: State = self.get_current_state()
		if current_state:
			if self.get_current_state().run(delta, speed_scale):
				if not self.advance():
					return true
	else:
		var running_states: int = 0
		for state in self._child_states:
			if state not in self._parallel_exited_states:
				running_states += 1
				if state.run(delta, speed_scale):
					running_states -= 1
					if self._exit_policy == ExitPolicy.REMOVE:
						self._child_states.remove_at(self._child_states.find(self.get_current_state()))
					self._parallel_exited_states.append(state)
		if running_states == 0:
			return true
			
	return false
	
func set_execution_mode(execution_mode: ExecutionMode) -> StateQueue:
	self._execution_mode = execution_mode
	return self
	
func set_exit_policy(exit_policy: ExitPolicy) -> StateQueue:
	self._exit_policy = exit_policy
	return self

func advance_on(from: String, condition: Variant) -> StateQueue:
	if condition is String:
		self.on_message(condition, self.advance)
	else:
		for state in self.get_states(from):
			state.on(condition, self.advance)
	return self
	
func advance() -> bool:
	var current_state: State = self._child_states.pop_front()
	current_state.immediate_exit()
	
	if self._exit_policy == ExitPolicy.KEEP:
		self._exited_child_states.push_back(current_state)
	
	if len(self._child_states) == 0:
		return false
	
	return true
	
func get_next_state_id() -> Variant:
	if self.current_state_index == len(self.child_states) - 1:
		return null
	return self.child_states[self.current_state_index + 1].id
	
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
	var current_state = self.get_current_state()
	if current_state:
		current_state.immediate_exit()
	self.child_states.clear()

func copy(new_id: String = self.id, _new_state = null) -> StateQueue:
	return super(new_id, StateQueue.new(new_id) if not _new_state else _new_state)
