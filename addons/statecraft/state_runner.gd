class_name StateRunner extends State

func _init(id: String):
	super(id)
	self.keep_alive()

func enter() -> bool:
	for state in self.get_all_states():
		state.reset()
	return super()

#func update(delta: float, speed_scale: float = 1):
	#super(delta, speed_scale)
	#var current_state = self.get_current_state()
	#if current_state:
		#self.get_current_state().run(delta, speed_scale)

func exit() -> bool:
	if super():
		var current_state = self.get_current_state()
		if current_state:
			current_state.exit()
		return true
	return false
			
func get_current_state() -> State:
	assert(false, "Cannot call `get_current_state()` on abstract StateRunner.")
	return null
	
func get_all_states() -> Array[State]:
	assert(false, "Cannot call `get_all_states()` on abstract StateRunner.")
	return []

func on_message(message_path: String, action: Callable):
	## Given a message, identified via a path (eg. gun_machine.firing.bullet_created),
	## this method attaches the action callback to the `bullet_created` message of the `firing` state.
	var path_components: Array = Array(message_path.split("."))
	var message_id: String = path_components.pop_back()
	
	if action.get_argument_count() > 0 and action.get_bound_arguments_count() == 0:
		action = action.bind(self)
		
	if len(path_components) > 0:
		var current_state = path_components.pop_front()
		for state in self.get_states(current_state):
			return state.on_message(".".join(path_components + [message_id]), action)
	return super(message_path, action)

func get_state_from_message_path(message_path: String) -> State:
	var path_components: Array = Array(message_path.split("."))
	var message_id: String = path_components.pop_back()
	var current_state = self
	for path_component in path_components:
		current_state = current_state.get_state(path_component)
	return current_state

func get_states(state_id: String) -> Array[State]:
	var matches: Array[State] = []
	for state in self._child_states:
		if state.id == state_id:
			matches.append(state)
	return matches
	






#func get_state_index(state_id: String):
	#for i in range(len(self.child_states)):
		#if self.child_states[i].id == state_id:
			#return i
	#return -1
	
func as_string(indent: int = 0) -> String:
	var indent_string: String = ""
	for i in range(indent):
		indent_string += " "
	var s: String = indent_string + self.id + ": " + self.get_status_string() + " : " + str(len(self.actions))
	for child_state in self._child_states:
		s += "\n" + child_state.as_string(indent + 4)
	return s

func copy(new_id: String = self.id, _new_state = null) -> StateRunner:
	_new_state = super(new_id, StateRunner.new(new_id) if not _new_state else _new_state)
	for child_state in self._child_states:
		_new_state.add_state(child_state.copy(child_state.id))
	return _new_state
	
func draw(node: Node2D, position: Vector2 = Vector2.ZERO, text_size: float = 16, padding_size: float = 8, delta: float = Engine.get_main_loop().root.get_process_delta_time()) -> float:
	var y_offset = super(node, position, text_size, padding_size, delta)
	var initial_y_offset = y_offset
	var line_width: float = 4
	for i in range(len(self.get_all_states())):
		var state: State = self.get_all_states()[i]
		var indent_width: float = max(16, padding_size)
		var cell_height: float = (text_size + padding_size * 2) * 1.3
		var child_state_colors: Array[Color] = state._get_debug_draw_colors() 
		node.draw_line(position + Vector2(0, y_offset + cell_height / 2), position + Vector2(indent_width, y_offset  + cell_height / 2), child_state_colors[1], line_width)

		y_offset += state.draw(node, Vector2(position.x + indent_width, position.y + y_offset), text_size, padding_size, delta)

	var colors: Array[Color] = self._get_debug_draw_colors()
	node.draw_line(position + Vector2(line_width / 2, 0), position + Vector2(line_width / 2, y_offset), colors[1], line_width)
	return y_offset 
