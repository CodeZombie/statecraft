class_name StateQueue extends StateContainer

enum ExecutionMode {SERIAL, PARALLEL}
enum ExitPolicy {KEEP, REMOVE}

var _execution_mode: ExecutionMode = ExecutionMode.SERIAL
var _exit_policy: ExitPolicy = ExitPolicy.KEEP

var _child_states: Array[State] = []

func add_state(state: State) -> StateContainer:
	self.listen_for_signals(state)
	return self.add_state_back(state)

func add_state_back(state: State) -> StateContainer:
	self._child_states.push_back(state)
	return self
	
func add_state_front(state: State, run_immediately: bool = true) -> StateContainer:
	self._child_states.push_front(state)
	if not run_immediately:
		state.status = StateStatus.EXITED
	return self
	
func get_running_states() -> Array[State]:
	var running_states: Array[State] = []
	for state in self._child_states:
		if state.status == StateStatus.RUNNING:
			running_states.append(state)
	return running_states

func get_current_state() -> State:
	for state in self._child_states:
		if state.status != StateStatus.EXITED:
			return state
	return null
	
func get_all_states() -> Array[State]:
	return self._child_states
	
func have_all_states_exited() -> bool:
	for state in self._child_states:
		if state.status != StateStatus.EXITED:
			return false
	return true

func update(delta: float, speed_scale: float = 1.0) -> bool:
	var r_val: bool = super(delta, speed_scale)
	if r_val:
		return true
	
	if self._execution_mode == ExecutionMode.SERIAL:
		var current_state: State = self.get_current_state()
		if current_state:
			if current_state.run(delta, speed_scale):
				if self._exit_policy == ExitPolicy.REMOVE:
					self._child_states.remove_at(self._child_states.find(current_state))
	else:
		for state in self._child_states.duplicate():
			if state.run(delta, speed_scale):
				if self._exit_policy == ExitPolicy.REMOVE:
					self._child_states.remove_at(self._child_states.find(state))
	
	if self.have_all_states_exited():
		return true
			
	return false
	
func set_execution_mode(execution_mode: ExecutionMode) -> StateQueue:
	self._execution_mode = execution_mode
	return self
	
func set_exit_policy(exit_policy: ExitPolicy) -> StateQueue:
	for state in self._child_states.duplicate():
		if state.status == StateStatus.EXITED:
			self._child_states.remove_at(self._child_states.find(state))
	self._exit_policy = exit_policy
	return self
	
func clear():
	for state in self.get_running_states():
		state.exit()
	self._child_states.clear()

func copy(new_id: String = self.id, _new_state = null) -> StateQueue:
	return super(new_id, StateQueue.new(new_id) if not _new_state else _new_state)
