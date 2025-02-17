class_name State

enum ExecutionPosition {PRE_UPDATE, POST_UPDATE}

enum StateStatus {READY, ENTERED, EXITED}

# TODO: CHeck to see if elapsed_runtime is accurate!!!!!

# NOTES:
# when calling _update from an eventqueue, we need to make sure we always pass the real delta time and time_scale.
# dont ever give it `delta * time_scale` - that should only ever happen when calling the user's custom method or calculating event runtime.
		
var id: String
var enter_events: Array[Callable] = []
var update_events: Array[Callable] = []
var exit_events: Array[Callable] = []
var on_exit_transition_method: Callable
var skippable: bool
var created_by: String
var status: StateStatus = StateStatus.READY
var props: Dictionary = {}
var actions: Array[Callable] = []
var message_handlers: Dictionary[String, Array] = {}
var _exit_after_enter_if_no_update_events: bool = true

var _debug_draw_label_running_color_fade_factor: float = 0.0

func copy(new_id: String = self.id, new_state = null) -> State:
	new_state = State.new(new_id) if not new_state else new_state
	new_state.skippable = self.skippable
	for enter_method in self.enter_events:
		new_state.add_enter_event(enter_method)
	for update_method in self.update_events:
		new_state.add_update_event(update_method)
	for exit_method in self.exit_events:
		new_state.add_exit_event(exit_method)
	return new_state

func _init(id: String):
	self.id = id

	for call_dict in get_stack():
		self.created_by += " --> {source}.{function}:{line}".format(call_dict)

func add_to_runner(state_runner: StateRunner) -> State:
	state_runner.add_state(self)
	return self
	
func add_enter_event(enter_method: Callable) -> State:
	self.enter_events.append(enter_method)
	return self

func add_update_event(update_event: Callable) -> State:
	self.update_events.append(update_event)
	return self

func add_exit_event(exit_event: Callable) -> State:
	self.exit_events.append(exit_event)
	return self
	
func get_state_from_message_path(message_path: String) -> State:
	var path_components: Array = Array(message_path.split("."))
	var message_id: String = path_components.pop_back()
	if len(path_components) > 0:
		assert(false, "State object {0} is of type State which cannot contain children, and therefore cannot resolve message path: \"{1}\"".format({0: self.id, 1: message_path}))
	return self

func on_message(message_path: String, action: Callable) -> State:
	var path_components: Array = Array(message_path.split("."))
	var message_id: String = path_components.pop_back()
	
	if len(path_components) > 0:
		assert(false, "State object {0} is of type State which cannot contain children, and therefore cannot resolve message path: \"{1}\"".format({0: self.id, 1: message_path}))
	
	if message_id not in self.message_handlers.keys():
		self.message_handlers[message_id] = []
		
	self.message_handlers[message_id].append(action)
	return self
	
func on_signal(sig: Signal, action: Callable) -> State:
	sig.connect(func():
		if self.status == StateStatus.ENTERED: 
			if action.get_argument_count() > 0:
				action.call(self)
			else:
				action.call())
	return self

func on_callable(callable: Callable, action: Callable) -> State:
	self.actions.append(func():
		if callable.call():
			action.call())
	return self

func on(condition: Variant, action: Callable) -> State:
	if condition is Signal:
		self.on_signal(condition, action)
		
	elif condition is String:
		self.on_message(condition, action)
		
	elif condition is Callable:
		self.on_callable(condition, action)
		
	return self

func clear_all_enter_methods():
	self.enter_events.clear()
	return self
	
func clear_all_update_methods():
	self.update_events.clear()
	return self
	
func clear_all_exit_methods():
	self.exit_events.clear()
	return self
	
func keep_alive() -> State:
	## Stops the State from automatically-exiting if there are no Update Events defined.
	self._exit_after_enter_if_no_update_events = false
	return self
	
func emit(message_id: String):
	if message_id in self.message_handlers.keys():
		for message_handler_callable in self.message_handlers[message_id]:
			message_handler_callable.call()
			
func emit_on(message_id: String, condition: Variant) -> State:
	self.on(condition, self.emit.bind(message_id))
	return self
	
func enter() -> bool:
	self.status = StateStatus.ENTERED
	self.props = {}
	var custom_enter_method_return_value: bool = false
	
	for enter_method in self.enter_events:
		if is_method_still_bound(enter_method):
			if enter_method.get_argument_count() > 0:
				if enter_method.call(self):
					custom_enter_method_return_value = true
			else:
				if enter_method.call():
					custom_enter_method_return_value = true
	return custom_enter_method_return_value

func update(delta: float, speed_scale: float = 1) -> bool:
	var custom_update_method_return_value: bool = false
	for update_method in self.update_events:
		if is_method_still_bound(update_method):
			if update_method.get_argument_count() > 1:
				if update_method.call(self, delta * speed_scale):
					custom_update_method_return_value = true
			else:
				if update_method.call(delta * speed_scale):
					custom_update_method_return_value = true
		
	for action in self.actions:
		action.call()
		
	if self._exit_after_enter_if_no_update_events and len(self.update_events) == 0:
		return true
	
	return custom_update_method_return_value

func exit() -> bool:
	## returns true if it ran the exit routine.
	## returns false if it's already exited.
	if self.status == StateStatus.ENTERED:
		self.status = StateStatus.EXITED
		for exit_method in self.exit_events:
			if is_method_still_bound(exit_method):
				if exit_method.get_argument_count() == 1:
					exit_method.call(self)
				else:
					exit_method.call()
		return true
	return false
	
func immediate_exit():
	# TODO: rename to "exit_and_reset()"
	if self.status == StateStatus.ENTERED:
		self.exit()
	if self.status == StateStatus.EXITED:
		self.status = StateStatus.READY

func restart():
	self.immediate_exit()
	self.enter()

func run(delta: float = Engine.get_main_loop().root.get_process_delta_time(), speed_scale: float = 1.0):
	if self.status == StateStatus.READY:
		if self.enter():
			self.exit()
		
	if self.status == StateStatus.ENTERED:
		if self.update(delta, speed_scale):
			self.exit()
			
	if self.status == StateStatus.EXITED:
		if self.on_exit_transition_method:
			if self.on_exit_transition_method.get_argument_count() == 1:
				self.on_exit_transition_method.call(self)
			else:
				self.on_exit_transition_method.call()
		self.status = StateStatus.READY
		return true
	return false

func is_method_still_bound(method: Callable) -> bool:
	if method.get_object() == null:
		push_error("ERROR: attemping to call method on State which has become unbound: ", self.created_by)
		return false
	return true
	
func as_string(indent: int = 0) -> String:
	var indent_string: String = ""
	for i in range(indent):
		indent_string += " "
	return indent_string + self.id + ": " + self.get_status_string() + "e" + str(len(self.enter_events))

func get_status_string() -> String:
	if self.status == StateStatus.READY: return "READY"
	if self.status == StateStatus.ENTERED: return "ENTERED"
	if self.status == StateStatus.EXITED: return "EXITED"
	return "UNKNOWN"
	
func _draw_text_with_box(text: String, position: Vector2, font_size: float, padding_size: float, node: Node2D, text_color: Color, box_color: Color) -> Vector2:
	var text_size: Vector2 = ThemeDB.fallback_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	node.draw_rect(Rect2(position, Vector2(text_size.x + padding_size * 2, text_size.y + padding_size * 2)), box_color)
	node.draw_string(ThemeDB.fallback_font, position + Vector2(padding_size, padding_size + text_size.y / 1.25), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, text_color)
	return text_size + Vector2(padding_size * 2, padding_size * 2)
	
func _get_debug_draw_colors() -> Array[Color]:
	return [
		Color.DARK_SLATE_GRAY.lerp(Color.WHITE_SMOKE, self._debug_draw_label_running_color_fade_factor), 
		Color.LIGHT_GRAY.lerp(Color.DEEP_SKY_BLUE, self._debug_draw_label_running_color_fade_factor)
	]
func draw(position: Vector2, node: Node2D, text_size: float = 16, padding_size: float = 8, delta: float = Engine.get_main_loop().root.get_process_delta_time()) -> float:

	var y_offset: float = 0.0
	if self.status == StateStatus.ENTERED:
		self._debug_draw_label_running_color_fade_factor = 1.0
	else: self._debug_draw_label_running_color_fade_factor = max(0.0, self._debug_draw_label_running_color_fade_factor - delta * 3)
	var colors = self._get_debug_draw_colors()
	var header_size: Vector2 = self._draw_text_with_box(
		self.id, 
		position, 
		text_size, 
		padding_size, 
		node, 
		colors[0], 
		colors[1])
	y_offset += header_size.y
	var rect: Rect2 = Rect2(position, header_size)
	#node.draw_rect(rect, Color(1.0, 0, 0, 0.5))
	if rect.has_point(node.get_local_mouse_position()):
		var info_color_b: Color = colors[1]
		info_color_b.a = 0.5
		y_offset += _draw_text_with_box("Status: {0}".format({0: self.get_status_string()}), position + Vector2(max(16, padding_size), y_offset), text_size, padding_size, node, colors[0], info_color_b).y
		y_offset += _draw_text_with_box("Enter Events: {0}".format({0: len(self.enter_events)}), position + Vector2(max(16, padding_size), y_offset), text_size, padding_size, node, colors[0], info_color_b).y
		y_offset += _draw_text_with_box("Update Events: {0}".format({0: len(self.update_events)}), position + Vector2(max(16, padding_size), y_offset), text_size, padding_size, node, colors[0], info_color_b).y
		y_offset += _draw_text_with_box("Exit Events: {0}".format({0: len(self.exit_events)}), position + Vector2(max(16, padding_size), y_offset), text_size, padding_size, node, colors[0], info_color_b).y
		y_offset += _draw_text_with_box("Message Handlers: {0}".format({0: len(self.message_handlers)}), position + Vector2(max(16, padding_size), y_offset), text_size, padding_size, node, colors[0], info_color_b).y

	return y_offset
