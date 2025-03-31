class_name StateMachine extends StateContainer

enum ResetOnExitMode {RESET, DO_NOT_RESET}

var states: Dictionary[NodePath, State] = {}

var reset_on_exit_mode: ResetOnExitMode = ResetOnExitMode.RESET

var initial_state_id: NodePath
var current_state_id: NodePath:
	set(value):
		var previously_current_state = self.get_current_state()
		
		if previously_current_state:
			#print("{id} txing from {from} to {to}".format({'id': self.id, 'from': previously_current_state.id, 'to': value}))
			previously_current_state.exit()
		#else:
			#print("{id} txing from Null to {to}".format({'id': self.id, 'to': value}))
		current_state_id = value
		var new_current_state = self.get_state(value)
		new_current_state.reset()
		
func from(state_node_path: Variant) -> EventActionCreator:
	if state_node_path is Array:
		return EventActionCreator.new(self, state_node_path)
	else:
		return EventActionCreator.new(self, [state_node_path])

###
### This is psychotic - way too many interfaces. Refactor all this shit.
###

func set_reset_on_exit_mode(reset_on_exit_mode: ResetOnExitMode) -> StateMachine:
	self.reset_on_exit_mode = reset_on_exit_mode
	return self

func copy(new_id: NodePath = self.id, _new_state = null) -> StateMachine:
	return super(new_id, StateMachine.new(new_id) if not _new_state else _new_state)
	
func get_running_states() -> Array[State]:
	return [self.get_current_state()]

func is_state_running(state_id: NodePath) -> bool:
	return self.current_state_id == state_id

func add(state: State) -> StateMachine:
	if state.id in self.states:
		push_error("StateCraft Error: State with ID \"{0}\" already present in State Machine \"{1}\"".format({0: state.id, 1: self.id}))
	self.propagate_relay_messages_to_child_node(state)
	self.states[state.id] = state
	if len(self.states.keys()) == 1:
		self.initial_state_id = state.id
	return self
	
func get_state(id: NodePath) -> State:
	if id not in self.states.keys():
		assert(false, "No state with id \"{0}\" in State Machine {1}".format({0: id, 1: self.id}))
	return self.states[id]
	
func get_all_children() -> Array:
	return self.states.values()
	
func get_current_state() -> State:
	if self.current_state_id in self.states.keys():
		return self.states[self.current_state_id]
	return null

func enter() -> bool:
	if self._debug: print(self.id, " ENTER (StateMachine)")
	if len(self.states) == 0:
		super()
		exit()
		return true
	#self.current_state_id = self.initial_state_id
	if not self.current_state_id:
		self.current_state_id = self.initial_state_id
	return super()
	
func process(delta: float, speed_scale: float = 1.0) -> bool:
	if self._debug: print(self.id, "process (StateMachine)")
	var r_val: bool = super(delta, speed_scale)
	if r_val:
		return true
	var current_state = self.get_current_state()
	if current_state:
		current_state.run(delta, speed_scale)
	return false
	
func exit() -> bool:
	if self._debug: print(self.id, " EXIT (StateMachine)")
	if self.reset_on_exit_mode == ResetOnExitMode.RESET:
		for state in self.get_all_children():
			state.exit()
	var x = super()
	if self.reset_on_exit_mode == ResetOnExitMode.RESET:
		self.current_state_id = self.initial_state_id
	return x

func transition_to(state_path: NodePath) -> StateContainer:
	if self._debug: print("{0}.transitioning from {from} to {to}".format({0: self.id, 'from': current_state_id, 'to': state_path}))
	
	var target_state: State = self.get_state(NodePath(state_path.get_name(0)))
	
	if not target_state:
		assert(false, "StateMachine {0} tried to transition to unknown state \"{1}\"".format({0: self.id, 1: state_path}))
		
	self.current_state_id = target_state.id
	
	if state_path.get_name_count() > 1:
		self.get_current_state().transition_to(state_path.slice(1))
	
	return self
	
func transition_to_dynamic(state_id_return_method: Callable) -> StateMachine:
	self.transition_to(SCUtils.call_with_possible_args(state_id_return_method, [self]))
	return self
