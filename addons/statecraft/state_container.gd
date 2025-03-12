class_name StateContainer extends State

## An abstract class used as the base for all States that execute other states.
##
## This class

var signal_handles: Dictionary = {}


func _init(id: NodePath):
	super(id)
	self.keep_alive()
	
func enter() -> bool:
	if self._debug: print(self.id, " ENTER (StateContainer)")
	for state in self.get_all_children():
		state.reset()
	return super()
	
func exit() -> bool:
	if self._debug: print(self.id, " EXIT (StateContainer)")
	if super():
		for state in self.get_all_children():
			state.exit()
		#var current_state = self.get_current_state()
		#if current_state:
			#current_state.exit()
		return true
	return false
			
func get_running_states() -> Array[State]:
	assert(false, "Cannot call `get_running_states()` on abstract class StateContainer")
	return []
	
#func get_all_states() -> Array[State]:
	#assert(false, "Cannot call `get_all_states()` on abstract StateContainer.")
	#return []

func get_states(state_id: NodePath) -> Array[State]:
	var matches: Array[State] = []
	for state in self._child_states:
		if state.id == state_id:
			matches.append(state)
	return matches
	
	
func transition_to(state_path: NodePath) -> StateContainer:
	if self._debug: print("{0} is passing a transition event: {to}".format({0: self.id, 'to': state_path}))
	#var state_path: Array
	#if state_id.contains('.'):
		#state_path = Array(state_id.split('.'))
		#state_id = state_path.pop_front()
	
	var target_states: Array[State] = self.get_states(NodePath(state_path.get_name(0)))
	
	if len(target_states) == 0:
		assert(false, "StateContainer {0} tried to pass a transition event to an unknown state \"{1}\"".format({0: self.id, 1: state_path}))
	
	if state_path:
		for target_state in target_states:
			target_state.transition_to(state_path.slice(1))
	
	return self
	


#func is_running(state_to_path: StringName = &"") -> bool:
	#var children: Array = [self]
	#if state_to_path != &"":
		#children = self.get_children_via_path(state_to_path)
	#for child in children:
		#if child.status == StateStatus.RUNNING:
			#return true
	#return false

# Recursive tree-search is probably a red flag in a high-performance library like this, 
# but what can ya do :^)
#func is_running(state_id: StringName) -> bool:
	#var target_state_path: Array = state_id.split('.')
	#if len(target_state_path) > 1:
		#var next_node = target_state_path.pop_front()
		#for child in self.get_states(next_node):
			#if child.is_running(".".join(target_state_path)):
				#return true
	#else:
		#for child in self.get_states(state_id):
			#if child.status == StateStatus.RUNNING:
				#return true
	#return false
	
func as_string(indent: int = 0) -> String:
	var indent_string: String = ""
	for i in range(indent):
		indent_string += " "
	var s: String = "{indent_string} {id} : {status}".format({
		'indent_string': indent_string,
		'id': self.id,
		'status': self.get_status_string()
	})
	for child_state in self.get_all_children():
		s += "\n" + child_state.as_string(indent + 4)
	return s
	
func copy(new_id: NodePath = self.id, _new_state = null) -> StateContainer:
	_new_state = super(new_id, StateContainer.new(new_id) if not _new_state else _new_state)
	for child_state in self.get_all_children():
		#TODO: _new_state does not necessarily have an `add_state` method. Plsfix
		_new_state.add_state(child_state.copy(child_state.id))
	return _new_state
	
func draw(node: Node2D, position: Vector2 = Vector2.ZERO, text_size: float = 16, padding_size: float = 8, delta: float = Engine.get_main_loop().root.get_process_delta_time()) -> float:
	var y_offset = super(node, position, text_size, padding_size, delta)
	var initial_y_offset = y_offset
	var line_width: float = 4
	for i in range(len(self.get_all_children())):
		var state: State = self.get_all_children()[i]
		var indent_width: float = max(16, padding_size)
		var cell_height: float = (text_size + padding_size * 2) * 1.3
		var child_state_colors: Array[Color] = state._get_debug_draw_colors() 
		node.draw_line(position + Vector2(0, y_offset + cell_height / 2), position + Vector2(indent_width, y_offset  + cell_height / 2), child_state_colors[1], line_width)
		
		y_offset += state.draw(node, Vector2(position.x + indent_width, position.y + y_offset), text_size, padding_size, delta)
		
	var colors: Array[Color] = self._get_debug_draw_colors()
	node.draw_line(position + Vector2(line_width / 2, 0), position + Vector2(line_width / 2, y_offset), colors[1], line_width)
	return y_offset 
