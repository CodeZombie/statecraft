class_name State extends RelayNode

signal entered
signal exited

enum ExecutionPosition {PRE_UPDATE, POST_UPDATE}
enum StateStatus {READY, RUNNING, EXITED}

enum RelayMessageType {CONNECT_EXTERNAL_SIGNAL, CONNECT_INTERNAL_SIGNAL}

# TODO: Check to see if elapsed_runtime is accurate!!!!!

var enter_events: Array[Callable] = []
var update_events: Array[Callable] = []
var exit_events: Array[Callable] = []
var skippable: bool
var created_by: String
var status: StateStatus = StateStatus.READY
var props: Dictionary = {}
var actions: Array[Callable] = []
#var message_handlers: Dictionary[String, Array] = {}
var _exit_after_enter_if_no_update_events: bool = true
var loop: bool = false
var _debug_draw_label_running_color_fade_factor: float = 0.0

var _signal_virtual_connections: Dictionary[StringName, Array] = {}

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
	super(id)
	self.id = id
	
	for call_dict in get_stack():
		self.created_by += " --> {source}.{function}:{line}".format(call_dict)

func _get_signal_argument_count(signal_: Signal) -> int:
	for signal_info in signal_.get_object().get_signal_list():
		if signal_info['name'] == signal_.get_name():
			return len(signal_info['args'])
	return -1

func _get_internal_signal_argument_count(signal_name: StringName) -> int:
	for signal_info in self.get_signal_list():
		if signal_info['name'] == signal_name:
			return len(signal_info['args'])
	return -1

func _base_signal_callback(signal_name: StringName, args: Array):
	if self.status != StateStatus.RUNNING:
		return
	if signal_name in self._signal_virtual_connections.keys():
		for callable in self._signal_virtual_connections[signal_name]:
			callable.call(self, args)
		
func _signal_callback_zero(signal_name: StringName):
	return _base_signal_callback(signal_name, [])
func _signal_callback_one(a: Variant, signal_name: StringName):
	return _base_signal_callback(signal_name, [a])
func _signal_callback_two(a: Variant, b: Variant, signal_name: StringName):
	return _base_signal_callback(signal_name, [a, b])
func _signal_callback_three(a: Variant, b: Variant, c: Variant, signal_name: StringName):
	return _base_signal_callback(signal_name, [a, b, c])
func _signal_callback_four(a: Variant, b: Variant, c: Variant, d: Variant, signal_name: StringName):
	return _base_signal_callback(signal_name, [a, b, c, d])
func _signal_callback_five(a: Variant, b: Variant, c: Variant, d: Variant, e: Variant, signal_name: StringName):
	return _base_signal_callback(signal_name, [a, b, c, d, e])
func _signal_callback_six(a: Variant, b: Variant, c: Variant, d: Variant, e: Variant, f: Variant, signal_name: StringName):
	return _base_signal_callback(signal_name, [a, b, c, d, e, f])
func _signal_callback_seven(a: Variant, b: Variant, c: Variant, d: Variant, e: Variant, f: Variant, g: Variant, signal_name: StringName):
	return _base_signal_callback(signal_name, [a, b, c, d, e, f, g])
func _signal_callback_eight(a: Variant, b: Variant, c: Variant, d: Variant, e: Variant, f: Variant, g: Variant, h: Variant, signal_name: StringName):
	return _base_signal_callback(signal_name, [a, b, c, d, e, f, g, h])
	
func _wrap_signal_callback(callable: Callable, strip_args: bool, signal_argument_count: int) -> Callable:
	var callable_arg_count: int = callable.get_argument_count()
	return func(object: Object, args: Array):
		if strip_args:
			if callable_arg_count == 0:
				callable.call()
			elif callable_arg_count == 1:
				callable.call(object)
			else:
				assert(false, "Callable has too many arguments for a strip-args connection: {0}".format({0: callable_arg_count}))
		else:
			if callable_arg_count == signal_argument_count:
				callable.callv(args)
			elif callable_arg_count == signal_argument_count + 1:
				callable.callv(args + [object])
			else:
				assert(false, "Callable has too many arguments ({0}) to connect to signal with an argument count of {1}".format({0: callable_arg_count, 1: signal_argument_count}))

func _handle_message(relay_message: RelayMessage) -> bool:
	if relay_message.message_type == RelayMessageType.CONNECT_EXTERNAL_SIGNAL:
		var signal_name: StringName = relay_message.args['signal'].get_name()
		var sig: Signal = relay_message.args['signal']
		var signal_unique_id: StringName = StringName(signal_name + str(sig.get_object_id()))
		var signal_argument_count: int = self._get_signal_argument_count(relay_message.args['signal'])
		
		var signal_callback_method: Callable
		if signal_argument_count == 0:
			signal_callback_method = self._signal_callback_zero
		elif signal_argument_count == 1:
			signal_callback_method = self._signal_callback_one
		elif signal_argument_count == 2:
			signal_callback_method = self._signal_callback_two
		elif signal_argument_count == 3:
			signal_callback_method = self._signal_callback_three
		elif signal_argument_count == 4:
			signal_callback_method = self._signal_callback_four
		elif signal_argument_count == 5:
			signal_callback_method = self._signal_callback_five
		elif signal_argument_count == 6:
			signal_callback_method = self._signal_callback_six
		elif signal_argument_count == 7:
			signal_callback_method = self._signal_callback_seven
		elif signal_argument_count == 8:
			signal_callback_method = self._signal_callback_eight
		else:
			assert(false, "Error: Cannot connect signal \"{0}\", which requires {1} arguments. StateCraft does not support connecting signals with more than 8 arguments. Please harass the Godot maintainers to add VarArg support to gdscript :)".format({0: signal_name, 1: signal_argument_count}))
		if not sig.is_connected(signal_callback_method):
			sig.connect(signal_callback_method.bind(signal_unique_id))
		
		if signal_unique_id not in self._signal_virtual_connections.keys():
			self._signal_virtual_connections[signal_unique_id] = []
			
		var callable: Callable = relay_message.args['callable']
		if callable not in self._signal_virtual_connections[signal_unique_id]:
			self._signal_virtual_connections[signal_unique_id].append(self._wrap_signal_callback(callable, relay_message.args['strip_args'], signal_argument_count))
		return true
		
	elif relay_message.message_type == RelayMessageType.CONNECT_INTERNAL_SIGNAL:
		var signal_name: StringName = relay_message.args['signal_name']
		var signal_argument_count: int = self._get_internal_signal_argument_count(signal_name)
		var callable: Callable = relay_message.args['callable']
		var callable_argument_count: int = callable.get_argument_count()
		if callable_argument_count == signal_argument_count:
			self.connect(signal_name, callable, relay_message.args['flags'])
		elif callable_argument_count == signal_argument_count + 1:
			self.connect(signal_name, callable.bind(self), relay_message.args['flags'])
		return true
		
	return false
	
func add_user_signal(signal_name: String, arguments: Array = []) -> void:
	super(signal_name, arguments)
	self.handle_all_permanent_messages_of_type(RelayMessageType.CONNECT_INTERNAL_SIGNAL)
	
func add_signal(signal_name: String, arguments: Array = []) -> State:
	self.add_user_signal(signal_name, arguments)
	return self

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

func on_signal(sig: Signal, callable: Callable, strip_args: bool = true) -> State:
	self.recieve_message(RelayMessage.new(
		[],
		RelayMessageType.CONNECT_EXTERNAL_SIGNAL,
		{
			"signal": sig,
			"callable": callable,
			"flags": 0,
			"strip_args": strip_args
		},
		false
	))
	return self

func on_signal_path(signal_path: String, callable: Callable, strip_args: bool = true) -> State:
	var target_node_path: Array[StringName] = RelayMessage.node_path_string_to_node_path_array(signal_path)
	var signal_name: StringName = target_node_path[-1]
	self.recieve_message(RelayMessage.new(
		target_node_path.slice(0, -1),
		RelayMessageType.CONNECT_INTERNAL_SIGNAL,
		{
			"signal_name": signal_name,
			"callable": callable,
			"flags": 0,
			"strip_args": strip_args
		},
		true
	))
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
	self.entered.emit()
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
		
		self.exited.emit()
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
