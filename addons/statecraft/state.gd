class_name State extends SignalRelayNode

signal entered
signal processed(float)
signal exited
signal broadcast_(StringName)

enum ExecutionPosition {PRE_PROCESS, POST_PROCESS}
enum StateStatus {READY, RUNNING, EXITING, EXITED}

# TODO: Check to see if elapsed_runtime is accurate!!!!!

var enter_events: Array[Callable] = []
var process_events: Array[Callable] = []
var exit_events: Array[Callable] = []

var condition_events: Dictionary[Callable, Array] = {}

var skippable: bool
var created_by: String
var status: StateStatus = StateStatus.READY
var props: Dictionary = {}
var _exit_after_enter_if_no_process_events: bool = true
var loop: bool = false
var _debug_draw_label_running_color_fade_factor: float = 0.0

var _timers: Dictionary[float, SCUtils.CallbackTimer] = {}

var _dynamic_timers: Array[SCUtils.DynamicCallbackTimer] = []

var _unique_id_counter: int = 0

###
### STATIC METHODS
###


###
### PRIVATE METHODS
###

func _get_unique_id() -> int:
	var unique_id = self._unique_id_counter
	self._unique_id_counter += 1
	return unique_id
	
func _base_signal_callback(signal_name: StringName, args: Array):
	if self.status == StateStatus.READY or self.status == StateStatus.EXITED:
		return
	super(signal_name, args)


###
### BASIC METHODS
###

func copy(new_id: NodePath = self.id, new_state = null) -> State:
	new_state = State.new(new_id) if not new_state else new_state
	new_state.skippable = self.skippable
	new_state._exit_after_enter_if_no_process_events = self._exit_after_enter_if_no_process_events
	for enter_method in self.enter_events:
		new_state.add_enter_event(enter_method)
	for process_method in self.process_events:
		new_state.add_process_event(process_method)
	for exit_method in self.exit_events:
		new_state.add_exit_event(exit_method)
	return new_state

func _init(id: NodePath, auto_exit=true):
	super(id)
	self._exit_after_enter_if_no_process_events = auto_exit
	
	for call_dict in get_stack():
		self.created_by += " --> {source}.{function}:{line}".format(call_dict)


###
### EVENT HANDLER FACTORY CREATORS
###

func on_enter() -> EventActionCreatorReaction:
	return EventActionCreator.new(self).on_enter()

func on_exit() -> EventActionCreatorReaction:
	return EventActionCreator.new(self).on_exit()

func on_broadcast(broadcast_name: StringName) -> EventActionCreatorReaction:
	return EventActionCreator.new(self).on_broadcast(broadcast_name)

func on_signal(sig: Signal, arg_filter: Variant = null) -> EventActionCreatorReaction:
	return EventActionCreator.new(self).on_signal(sig, arg_filter)

func on_signal_path(signal_path: String) -> EventActionCreatorReaction:
	return EventActionCreator.new(self).on_signal(signal_path)

func on_timer(duration: float) -> EventActionCreatorReaction:
	return EventActionCreator.new(self).on_timer(duration)
	
func on_dynamic_timer(duration_callable: Callable) -> EventActionCreatorReaction:
	return EventActionCreator.new(self).on_dynamic_timer(duration_callable)

func if_true(condition: Callable) -> EventActionCreatorReaction:
	return EventActionCreator.new(self).if_true(condition)

func if_false(condition: Callable) -> EventActionCreatorReaction:
	return EventActionCreator.new(self).if_false(condition)


###
### EVENT HANDLERS
###

func add_enter_event(callables: Variant) -> State:
	if callables is Callable:
		callables = [callables]
		
	for callable in callables:
		self.enter_events.append(callable)
	return self
	
func add_process_event(callables: Variant) -> State:
	if callables is Callable:
		callables = [callables]
		
	for callable in callables:
		self.process_events.append(callable)
	return self

func add_exit_event(callables: Variant) -> State:
	if callables is Callable:
		callables = [callables]
		
	for callable in callables:
		self.exit_events.append(callable)
	return self

func add_on_condition_event(condition: Callable, callback: Callable, invert: bool = false) -> State:
	if condition not in self.condition_events.keys():
		self.condition_events[condition] = []
	self.condition_events[condition].append(callback)
	return self
	
func add_on_timer_event(timer_duration: float, callback: Callable) -> State:
	if timer_duration not in self._timers.keys():
		self._timers[timer_duration] = SCUtils.CallbackTimer.new()
	self._timers[timer_duration].add_callback(callback)
	return self

func add_on_dynamic_timer_event(timer_duration_callable: Callable, callback: Callable) -> State:
	var dynamic_callback_timer: SCUtils.DynamicCallbackTimer = SCUtils.DynamicCallbackTimer.new(timer_duration_callable)
	dynamic_callback_timer.add_callback(callback)
	self._dynamic_timers.append(dynamic_callback_timer)
	return self

func add_on_broadcast_event(broadcast_name: StringName, callable: Callable) -> State:
	self.broadcast_.connect(func(broadcast_name_: StringName):
		if self.status == StateStatus.RUNNING and broadcast_name == broadcast_name_:
			callable.call())
	return self

func broadcast(broadcast_name: StringName) -> void:
	self.propagate_message_to_children(RelayMessage.new(^"**", &"emit_signal", [broadcast_name]))

func set_prop(key: String, value: Variant) -> State:
	self.props[key] = value
	return self

func keep_alive() -> State:
	## Stops the State from automatically-exiting if there are no process Events defined.
	self._exit_after_enter_if_no_process_events = false
	return self
	
func enter() -> bool:
	if self._debug: print(self.id, " ENTER (State)", StateStatus.keys()[self.status])
	self.status = StateStatus.RUNNING
	self.props = {}
	var custom_enter_method_return_value: bool = false
	
	# Reset timers:
	for timer in self._timers.values():
		timer.reset()

	for dynamic_timer in self._dynamic_timers:
		dynamic_timer.reset()
	
	# run Enter events
	for enter_method in self.enter_events:
		#if is_method_still_bound(enter_method):
		if enter_method.get_argument_count() > 0:
			if enter_method.call(self):
				custom_enter_method_return_value = true
		else:
			if enter_method.call():
				custom_enter_method_return_value = true
				
	for condition_event in self.condition_events.keys():
		if condition_event.call():
			for callback in self.condition_events[condition_event]:
				callback.call()
				
	self.entered.emit()
	return custom_enter_method_return_value

func process(delta: float, speed_scale: float = 1) -> bool:
	if self._debug: print(self.id, " PROCESSING ", StateStatus.keys()[self.status])
	
	# TODO: should this go after the custom_process_method_return_value return check???
	for condition_event in self.condition_events.keys():
		if condition_event.call():
			for callback in self.condition_events[condition_event]:
				if self.status != StateStatus.RUNNING:
					return true
				callback.call()

	for timer_duration in self._timers.keys():
		if self.status != StateStatus.RUNNING:
			return true
		self._timers[timer_duration].process(timer_duration, delta * speed_scale)
	
	for dynamic_timer in self._dynamic_timers:
		if self.status != StateStatus.RUNNING:
			return true
		dynamic_timer.process(delta * speed_scale)
		
	if self.status != StateStatus.RUNNING:
		return true
	
	var custom_process_method_return_value: bool = false
	for process_method in self.process_events:
		if self.status != StateStatus.RUNNING:
			return true
		if process_method.get_argument_count() == 0:
			if process_method.call():
				custom_process_method_return_value = true
		elif process_method.get_argument_count() == 1:
			if process_method.call(delta * speed_scale):
				custom_process_method_return_value = true
		else:
			if process_method.call(delta * speed_scale, self):
				custom_process_method_return_value = true
				
	if not custom_process_method_return_value:
		if self._exit_after_enter_if_no_process_events and len(self.process_events) == 0:
			return true
	self.processed.emit(delta * speed_scale)
	return custom_process_method_return_value


## Handles the exit routine for the state.
##
## This method changes the state's status to EXITED if it was previously RUNNING. 
## It then calls all the exit methods bound to this state. 
## 
## Returns: `true` if the exit routine was executed, `false` if the state was already exited.
func exit() -> bool:
	if self._debug: print(self.id, " EXIT (State) : ", StateStatus.keys()[self.status])
	if self.status == StateStatus.RUNNING:
		self.status = StateStatus.EXITING
		for exit_method in self.exit_events:
			#if is_method_still_bound(exit_method):
			if exit_method.get_argument_count() == 1:
				exit_method.call(self)
			else:
				exit_method.call()
		
		self.exited.emit()
		self.status = StateStatus.EXITED
		return true
	return false
	
	
## Resets the State to make it ready for running later.
func reset():
	if self._debug: print(self.id, " RESET (State)", StateStatus.keys()[self.status])
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
	#print("{0} -> {1}".format({0: self.id, 1: StateStatus.keys()[self.status]}))
	if self.status == StateStatus.READY:
		if self.enter():
			self.exit()
		#return false
		
	if self.status == StateStatus.RUNNING:
		if self.process(delta, speed_scale):
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

func as_string(indent: int = 0) -> String:
	var indent_string: String = ""
	for i in range(indent):
		indent_string += " "
		
	var timer_string: String = ""
	for timer in self._timers.values():
		timer_string += "{0}".format({0: timer.elapsed_time})

	for dynamic_timer in self._dynamic_timers:
		timer_string += "{0}".format({0: dynamic_timer.elapsed_time})
		
	return "{indent_string} {id} : {status} -> {timers}".format({
		'indent_string': indent_string,
		'id': self.id,
		'status': self.get_status_string(),
		'timers': timer_string
	})

func get_status_string() -> String:
	return StateStatus.keys()[self.status]
	
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
		y_offset += _draw_text_with_box("Process Events: {0}".format({0: len(self.process_events)}), position + Vector2(max(16, padding_size), y_offset), text_size, padding_size, node, colors[0], info_color_b).y
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
