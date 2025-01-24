class_name StateRunner extends State

var child_states: Array[State] = []
var current_state_index: int = 0

func enter():
	super()
	self.current_state_index = 0
	var current_state = self.get_current_state()
	if current_state:
		current_state.enter()

func update(delta: float, speed_scale: float = 1):
	super(delta, speed_scale)
	var current_state = self.get_current_state()
	if current_state:
		self.get_current_state().update(delta, speed_scale)

func exit():
	super()
	var current_state = self.get_current_state()
	if current_state and current_state._status == Status.RUNNING:
		current_state.exit()
		
func on_message(message_path: String, action: Callable):
	var path_components: Array = Array(message_path.split("."))
	var message_id: String = path_components.pop_back()
	if len(path_components) > 0:
		var current_state = path_components.pop_front()
		return self.get_state(current_state).on_message(".".join(path_components + [message_id]), action)
	return super(message_path, action)

func transition_dynamic(from: String, condition: Callable) -> StateRunner:
	self.actions.append(func():
		if self.get_current_state().id == from:
			var return_value = condition.call()
			if return_value:
				self.transition_to(return_value))
	return self
		
func transition_on(from: String, to: String, condition: Variant) -> StateRunner:
	if condition is String:
		self.on_message(condition, self.transition_to.bind(to))
	else:
		var target_state: State = self.get_state(from)
		target_state.on(condition, func(): self.transition_to(to))
	return self
			
func add_state(state: State) -> StateRunner:
	if self.get_state(state.id):
		push_error("StateCraft Error: State with ID \"{0}\" already present in State Runner \"{1}\"".format({0: state.id, 1: self.id}))
	self.child_states.append(state)
	return self

func get_state_from_message_path(message_path: String) -> State:
	var path_components: Array = Array(message_path.split("."))
	var message_id: String = path_components.pop_back()
	var current_state = self
	for path_component in path_components:
		current_state = current_state.get_state(path_component)
	return current_state

func get_state(state_id: String) -> State:
	for child_state in self.child_states:
		if child_state.id == state_id:
			return child_state
	return null

func get_current_state() -> State:
	if self.current_state_index < len(self.child_states):
		#return self.child_states.get_at_index(self.current_state_index)
		return self.child_states[self.current_state_index]
	return null
	
func transition_to(state_id: String) -> StateRunner:
	if not self.get_current_state():
		return
	self.get_current_state().exit()
	self.current_state_index = self.get_state_index(state_id)
	if self.current_state_index == -1:
		assert(false, "StateCraft Error: Tried to transition to unknown state \"{0}\"".format({0: state_id}))
	self.get_current_state().enter()
	return self

func get_state_index(state_id: String):
	for i in range(len(self.child_states)):
		if self.child_states[i].id == state_id:
			return i
	return -1
	
func as_string(indent: int = 0) -> String:
	var indent_string: String = ""
	for i in range(indent):
		indent_string += " "
	var s: String = indent_string + self.id + ": " + self.get_status_string() + " : " + str(len(self.actions))
	for child_state in self.child_states:
		s += "\n" + child_state.as_string(indent + 4)
	return s
