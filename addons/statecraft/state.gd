class_name State
## A state.
##
## Long description of what a state is.

#signal signal_emitted(signal_path: StringName, args: Array)

enum ExecutionPosition {PRE_UPDATE, POST_UPDATE}

enum StateStatus {READY, RUNNING, EXITED}

# TODO: CHeck to see if elapsed_runtime is accurate!!!!!

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
#var message_handlers: Dictionary[String, Array] = {}
var _exit_after_enter_if_no_update_events: bool = true
var loop: bool = false
var _debug_draw_label_running_color_fade_factor: float = 0.0

# TODO: Change this to a Dictionary of [callable, flag]s. with StringName keys.
#	this way when we need to check if a deferred signal connection has already been added to this list in
#	`add_deferred_signal_connection`, it'll be way faster, as we wont need to loop through every single
#	deferred connection, only the callables linked directly to that signal_path.
var _deferred_signal_connections: Array[Dictionary] = []
## An array of dicts describing signal connections that should be made, but can't yet
## because the desired signal does not yet exist.


## Copies a state blah blah blah
##
## Long description of the copy method...
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

func _init(id: String, signal_names: Array = []):
	self.id = id
	
	for signal_name in signal_names:
		self.add_signal(signal_name)
	
	for call_dict in get_stack():
		self.created_by += " --> {source}.{function}:{line}".format(call_dict)

func add_user_signal(signal_name: String, arguments: Array = []) -> void:
	## Creates a signal for this State
	super(signal_name, arguments)
	self.connect_deferred_signals()

func add_signal(signal_name: String, arguments: Array = []) -> State:
	self.add_user_signal(signal_name, arguments)
	return self

func connect_deferred_signals() -> void:
	# Connect any deferred signal connections that match this new signal's name.
	var connected_deferred_signal_connections: Array = []
	for deferred_signal_connection in self._deferred_signal_connections:
		if len(deferred_signal_connection['signal_path']) == 1:
			if self.has_user_signal(deferred_signal_connection['signal_path'][0]):
				self.connect(deferred_signal_connection['signal_path'][0], deferred_signal_connection['callable'], deferred_signal_connection['flags'])
				connected_deferred_signal_connections.append(deferred_signal_connection)
				
	for connected_deferred_signal_connection in connected_deferred_signal_connections:
		self._deferred_signal_connections.erase(connected_deferred_signal_connection)

func add_deferred_signal_connection(signal_path: Array[StringName], callable: Callable, flags: int = 0) -> void:
	for deferred_signal_connection in self._deferred_signal_connections:
		if deferred_signal_connection['signal_path'] == signal_path and deferred_signal_connection['callable'] == callable:
			return
	self._deferred_signal_connections.append({
		"signal_path": signal_path,
		"callable": callable,
		"flags": flags
	})
	self.connect_deferred_signals()
	
func connect(signal_path: StringName, callable: Callable, flags: int = 0) -> int:
	var signal_path_array: PackedStringArray = signal_path.split(".")
	if len(signal_path_array) == 1:
		return super(signal_path, callable, flags)
	self.add_deferred_signal_connection(signal_path_array, callable, flags)
	return 0

func add_to_runner(state_runner: StateContainer) -> State:
	state_runner.add_state(self)
	return self
	
func add_enter_event(enter_method: Callable) -> State:
	self.enter_events.append(enter_method)
	return self
	
func add_enter_event_closure(enter_closure: Callable) -> State:
	self.enter_events.append(enter_closure.call())
	return self

func add_update_event(update_event: Callable) -> State:
	self.update_events.append(update_event)
	return self

func add_exit_event(exit_event: Callable) -> State:
	self.exit_events.append(exit_event)
	return self
	
func on_signal(sig: Signal, action: Callable) -> State:
	sig.connect(func():
		if self.status == StateStatus.RUNNING: 
			if action.get_argument_count() > 0:
				action.call(self)
			else:
				action.call())
	return self
	
func discard_args(callable: Callable) -> Callable:
	return func(a=null, b=null, c=null, d=null, e=null, f=null, g=null, h=null, i=null, j=null, k=null):
		callable.call()

func on_signal_path(signal_path: String, action: Callable) -> State:
	# No point wrapping this in a `if self.status == StateStatus.RUNNING
	# because signal_path can only connect to self or self.child's signals, which
	# could never possibly emit unless they were running.
	# And the only way they could be running is if self was running.
	if action.get_argument_count() == 0:
		self.connect(signal_path, discard_args(action))
	elif action.get_argument_count() == 1:
		self.connect(signal_path, discard_args(action.bind(self)))
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
		self.on_signal_path(condition, action)
		#self.on_message(condition, action)
		
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

func emit_signal_on(signal_name: StringName, condition: Variant, args: Array = []) -> State:
	self.on(condition, self.emit_signal.bindv([signal_name] + args))
	return self
	
func enter() -> bool:
	self.status = StateStatus.RUNNING
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
			if update_method.get_argument_count() == 0:
				if update_method.call():
					custom_update_method_return_value = true
			elif update_method.get_argument_count() == 1:
				if update_method.call(delta * speed_scale):
					custom_update_method_return_value = true
			else:
				if update_method.call(delta * speed_scale, self):
					custom_update_method_return_value = true
		
	for action in self.actions:
		action.call()
		
	if self._exit_after_enter_if_no_update_events and len(self.update_events) == 0:
		return true
	
	return custom_update_method_return_value


## Handles the exit routine for the state.
##
## This method changes the state's status to EXITED if it was previously RUNNING. 
## It then calls all the exit methods bound to this state. 
## If an `on_exit_transition_method` is defined, it will be called as well.
## 
## Returns: `true` if the exit routine was executed, `false` if the state was already exited.
func exit() -> bool:
	if self.status == StateStatus.RUNNING:
		self.status = StateStatus.EXITED
		for exit_method in self.exit_events:
			if is_method_still_bound(exit_method):
				if exit_method.get_argument_count() == 1:
					exit_method.call(self)
				else:
					exit_method.call()
		
		# TODO: I hate this. Is there some way we can get rid of this on_exit_transition_method?
		#	perhaps we can just emit a signal after the exit() method finishes running its callbacks,
		# 	and anything can connect to that callback? That seems way more flexible and we dont need this special-case
		#	logic.
		if self.on_exit_transition_method:
			if self.on_exit_transition_method.get_argument_count() == 1:
				self.on_exit_transition_method.call(self)
			else:
				self.on_exit_transition_method.call()
		else:
			return true
	return false
	
	
## Resets the State to make it ready for running later.
func reset():
	if self.status == StateStatus.RUNNING:
		self.exit()
	if self.status == StateStatus.EXITED:
		self.status = StateStatus.READY


## Executes the state logic for a single frame.
##
## Parameters:
## [param delta]: The time elapsed since the last frame. Defaults to the main loop's process delta time.
## [param speed_scale]: A multiplier for the delta time to control the speed of the state execution. Defaults to 1.0.
func run(delta: float = Engine.get_main_loop().root.get_process_delta_time(), speed_scale: float = 1.0):
	if self.status == StateStatus.READY:
		if self.enter():
			self.exit()
		
	if self.status == StateStatus.RUNNING:
		if self.update(delta, speed_scale):
			self.exit()
			
	if self.status == StateStatus.EXITED:
		if self.loop:
			self.status = StateStatus.READY
			return false
		return true
		
	return false
	
func run_instantly(timeout_duration_s: float = 0.25):
	var was_looping: bool = self.loop
	self.loop = false
	
	var start_time: int = Time.get_ticks_msec()
	
	while true:
		if Time.get_ticks_msec() > start_time + (timeout_duration_s * 1000):
			push_error("StateCraft Warning: run_instantly({0}) timed out.".format({0: timeout_duration_s}))
			break
		if self.run(0.1, 1.0):
			break
			
	if was_looping:
		self.loop = true
	return true

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
	if self.status == StateStatus.RUNNING: return "RUNNING"
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
func draw(node: Node2D, position: Vector2 = Vector2.ZERO, text_size: float = 16, padding_size: float = 8, delta: float = Engine.get_main_loop().root.get_process_delta_time()) -> float:

	var y_offset: float = 0.0
	if self.status == StateStatus.RUNNING:
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
		var signal_names = []
		for signal_info in get_signal_list():
			if not signal_info['name'] in ["script_changed", "property_list_changed"]:
				signal_names.append(signal_info['name'])
			
		y_offset += _draw_text_with_box("Signals: {0}".format({0: ", ".join(PackedStringArray(signal_names))}), position + Vector2(max(16, padding_size), y_offset), text_size, padding_size, node, colors[0], info_color_b).y

		var signal_connections: int = 0
		for signal_info in self.get_signal_list():
			signal_connections += len(self.get_signal_connection_list(signal_info['name']))
		y_offset += _draw_text_with_box("Signal Connections: {0}".format({0: signal_connections}), position + Vector2(max(16, padding_size), y_offset), text_size, padding_size, node, colors[0], info_color_b).y

	return y_offset
