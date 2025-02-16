class_name StateRunner extends State

var child_states: Array[State] = []
var current_state_index: int = 0

func enter():
	super()
	self.current_state_index = 0

#func update(delta: float, speed_scale: float = 1):
	#super(delta, speed_scale)
	#var current_state = self.get_current_state()
	#if current_state:
		#self.get_current_state().run(delta, speed_scale)

func exit():
	super()
	var current_state = self.get_current_state()
	
	if current_state and current_state.is_running:
		current_state.exit()
		
func on_message(message_path: String, action: Callable):
	var path_components: Array = Array(message_path.split("."))
	var message_id: String = path_components.pop_back()
	
	if action.get_argument_count() > 0 and action.get_bound_arguments_count() == 0:
		action = action.bind(self)
		
	if len(path_components) > 0:
		var current_state = path_components.pop_front()
		return self.get_state(current_state).on_message(".".join(path_components + [message_id]), action)
	return super(message_path, action)

func get_state_from_message_path(message_path: String) -> State:
	var path_components: Array = Array(message_path.split("."))
	var message_id: String = path_components.pop_back()
	var current_state = self
	for path_component in path_components:
		current_state = current_state.get_state(path_component)
	return current_state

func get_state(state_id: String) -> State:
	for state in self.child_states:
		if state.id == state_id:
			return state
	return null

func get_current_state() -> State:
	if self.current_state_index < len(self.child_states):
		return self.child_states[self.current_state_index]
	return null
	
func add_state(state: State) -> StateRunner:
	return self.add_state_back(state)

func add_state_back(state: State) -> StateRunner:
	self.child_states.push_back(state)
	return self
	
func add_state_front(state: State) -> StateRunner:
	self.child_states.push_front(state)
	return self
	
func transition_to(state_id: String) -> StateRunner:
	if not self.get_current_state():
		return
	var current_state = self.get_current_state()
	if current_state and current_state.is_running:
		current_state.exit()
	self.current_state_index = self.get_state_index(state_id)
	if self.current_state_index == -1:
		assert(false, "StateCraft Error: Tried to transition to unknown state \"{0}\"".format({0: state_id}))
	return self

func transition_dynamic(from: String, condition: Callable) -> StateRunner:
	self.actions.append(func():
		if self.get_current_state().id == from:
			var return_value = condition.call(self) if condition.get_argument_count() > 0 else condition.call()
			if return_value:
				self.transition_to(return_value))
	return self
		
func transition_on(from: String, to: String, condition: Variant, additional_callable_condition: Variant = null) -> StateRunner:
	var transition_callable: Callable = self.transition_to.bind(to)
	if additional_callable_condition:
		transition_callable = func():
			if additional_callable_condition.call():
				self.transition_to(to)
				
	if condition is String:
		self.on_message(condition, transition_callable)
	else:
		var target_state: State = self.get_state(from)
		target_state.on(condition, transition_callable)
	return self

func transition_on_exit(from: String, to: String) -> StateRunner:
	print("Adding transition_on_exit for {0}: {1} -> {2}".format({0: self.id, 1: from, 2: to}))
	self.get_state(from).on_exit_transition_method = self.transition_to.bind(to)
	return self
	
func from(state_id: String) -> TransitionChainFrom:
	return TransitionChainFrom.new(self, state_id)

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

func copy(new_id: String = self.id, _new_state = null) -> StateRunner:
	_new_state = super(new_id, StateRunner.new(new_id) if not _new_state else _new_state)
	for child_state in self.child_states:
		_new_state.add_state(child_state.copy(child_state.id))
	return _new_state
	
func draw(position: Vector2, node: Node2D, text_size: float = 16, padding_size: float = 8, delta: float = Engine.get_main_loop().root.get_process_delta_time()) -> float:
	var y_offset = super(position, node, text_size, padding_size, delta)
	var initial_y_offset = y_offset
	var line_width: float = 4
	for i in range(len(self.child_states)):
		var indent_width: float = max(16, padding_size)
		var cell_height: float = (text_size + padding_size * 2) * 1.3
		var child_state_colors: Array[Color] = self.child_states[i]._get_debug_draw_colors() 
		node.draw_line(position + Vector2(0, y_offset + cell_height / 2), position + Vector2(indent_width, y_offset  + cell_height / 2), child_state_colors[1], line_width)

		y_offset += self.child_states[i].draw(Vector2(position.x + indent_width, position.y + y_offset), node, text_size, padding_size, delta)

	var colors: Array[Color] = self._get_debug_draw_colors()
	node.draw_line(position + Vector2(line_width / 2, 0), position + Vector2(line_width / 2, y_offset), colors[1], line_width)
	return y_offset 
