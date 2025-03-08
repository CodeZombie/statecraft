class_name State extends SignalRelayNode

signal entered
signal updated(float)
signal exited
signal broadcast_(StringName)

enum ExecutionPosition {PRE_UPDATE, POST_UPDATE}
enum StateStatus {READY, RUNNING, EXITED}

# TODO: Check to see if elapsed_runtime is accurate!!!!!

var enter_events: Array[Callable] = []
var update_events: Array[Callable] = []
var exit_events: Array[Callable] = []

var skippable: bool
var created_by: String
var status: StateStatus = StateStatus.READY
var props: Dictionary = {}
#var actions: Array[Callable] = []
#var message_handlers: Dictionary[String, Array] = {}
var _exit_after_enter_if_no_update_events: bool = true
var loop: bool = false
var _debug_draw_label_running_color_fade_factor: float = 0.0

#var _signal_virtual_connections: Dictionary[StringName, Array] = {}


var _unique_id_counter: int = 0

# Timers can:
#	emit a signal
#	make a broadcast
#	run a function
#	execute a transition (?)
#	after_timer(0.5).emit_signal("my_sig")
#	after_timer(0.5, "my_signal").broadcast("my_bcast")
#	after_timer(0.5).execute(func(): pass)
#	after_timer(0.5).transition_to(&"state_node")
#	after_timer(0.5).set_blackboard_value(&"can_jump", true)


		
#var _countdowns: Array[Countdown]

###
### STATIC METHODS
###

static func _call_with_optional_state(state: State, callable: Callable) -> Variant:
	if callable.get_argument_count() == 1:
		return callable.call(state)
	else:
		return callable.call()

static func _bind_with_optional_state(state: State, callable: Callable) -> Callable:
	if callable.get_bound_arguments_count() == 1:
		return callable.bind(state)
	return callable

static func _invert_callable(callable: Callable) -> Callable:
	var arg_count: int = callable.get_argument_count()
	if arg_count == 0:
		return func(): return not callable.call()
	elif arg_count == 1:
		return func(arg_a: Variant): return not callable.call(arg_a) 
	elif arg_count == 2:
		return func(arg_a: Variant, arg_b: Variant): return not callable.call(arg_a, arg_b)
	elif arg_count == 3:
		return func(arg_a: Variant, arg_b: Variant, arg_c: Variant): return not callable.call(arg_a, arg_b, arg_c)
	assert(false, "Cannot invert callable with more than 3 arguments.")
	return Callable()
###
### PRIVATE METHODS
###

func _get_unique_id() -> int:
	var unique_id = self._unique_id_counter
	self._unique_id_counter += 1
	return unique_id
	
func _base_signal_callback(signal_name: StringName, args: Array):
	if self.status != StateStatus.RUNNING:
		return
	super(signal_name, args)


###
### BASIC METHODS
###

func copy(new_id: StringName = self.id, new_state = null) -> State:
	new_state = State.new(new_id) if not new_state else new_state
	new_state.skippable = self.skippable
	new_state._exit_after_enter_if_no_update_events = self._exit_after_enter_if_no_update_events
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

func is_running(state_to_path: StringName = &"") -> bool:
	return self.status == StateStatus.RUNNING

###
### EVENT HANDLER FACTORY CREATORS
###

func on_enter() -> EventHandlerFactory:
	return self.on_signal_path("entered")
	#return EventHandlerFactory.new(self, StateEvent.new(StateEvent.EventType.ENTERED))

func on_update() -> EventHandlerFactory:
	return self.on_signal_path("updated")
	#return EventHandlerFactory.new(self, StateEvent.new(StateEvent.EventType.UPDATED))

func on_exit() -> EventHandlerFactory:
	return self.on_signal_path("exited")
	#return EventHandlerFactory.new(self, StateEvent.new(StateEvent.EventType.EXITED))

func on_broadcast(broadcast_name: StringName) -> EventHandlerFactory:
	return EventHandlerFactory.new(self, BroadcastEvent.new(broadcast_name))

func on_signal(sig: Signal) -> EventHandlerFactory:
	return EventHandlerFactory.new(self, SignalEvent.new(sig))

func on_signal_path(signal_path: String) -> EventHandlerFactory:
	return EventHandlerFactory.new(self, SignalPathEvent.new(signal_path))

func on_timer(duration: float) -> EventHandlerFactory:
	return EventHandlerFactory.new(self, TimerEvent.new(duration))

func on(condition: Callable) -> EventHandlerFactory:
	return EventHandlerFactory.new(self, ConditionEvent.new(condition))

func on_inv(condition: Callable) -> EventHandlerFactory:
	return EventHandlerFactory.new(self, ConditionEvent.new(condition, true))


###
### EVENT HANDLERS
###

func add_on_broadcast_callback(broadcast_name: StringName, callable: Callable) -> State:
	self.broadcast_.connect(func(broadcast_name_: StringName):
		if self.status == StateStatus.RUNNING and broadcast_name == broadcast_name_:
			callable.call())
	return self

func add_entered_callback(enter_method: Callable) -> State:
	self.enter_events.append(enter_method)
	return self
	
func add_updated_callback(update_event: Callable) -> State:
	self.update_events.append(update_event)
	return self

func add_exited_callback(exit_event: Callable) -> State:
	self.exit_events.append(exit_event)
	return self



###
### ACTIONS
###

func broadcast(broadcast_name: StringName) -> void:
	self.recieve_message(RelayMessage.new(
		"**",
		RelayMessage.Type.EMIT_SIGNAL,
		{
			'signal_name': "broadcast_",
			'args': [broadcast_name]
		},
		false
	))

func set_prop(key: String, value: Variant) -> State:
	self.props[key] = value
	return self



func _handle_message(relay_message: RelayMessage) -> bool:
	if super(relay_message):
		return true
	if relay_message.message_type == RelayMessage.Type.ADD_ENTERED_CALLBACK:
		self.add_updated_callback(relay_message.args['callable'])
		return true
	if relay_message.message_type == RelayMessage.Type.ADD_UPDATED_CALLBACK:
		self.add_updated_callback(relay_message.args['callable'])
		return true
	if relay_message.message_type == RelayMessage.Type.ADD_EXITED_CALLBACK:
		self.add_updated_callback(relay_message.args['callable'])
		return true
	if relay_message.message_type == RelayMessage.Type.CALL_METHOD:
		if self._debug: print("{0}.handle_message[{1}]({2}({3}))".format({0:self.id, 1: relay_message.message_type, 2: relay_message.args['method_name'], 3: relay_message.args['args']}))
		self.callv(relay_message.args['method_name'], relay_message.args['args'])
		return true
		
	elif relay_message.message_type == RelayMessage.Type.EMIT_SIGNAL:
		self.callv("emit_signal", [relay_message.args['signal_name']] + relay_message.args['args'])
		return true
		
	elif relay_message.message_type == RelayMessage.Type.ATTACH_ON_BROADCAST_CALLBACK:
		self.add_on_broadcast_callback(relay_message.args['broadcast_name'], relay_message.args['callback'])
		return true
		
	return false
	


# func on_broadcast(broadcast_name: StringName, callable: Callable) -> State:
# 	self.broadcast_.connect(func(broadcast_name_: StringName):
# 		if self.status == StateStatus.RUNNING and broadcast_name == broadcast_name_:
# 			callable.call())
# 	return self


#func add_to_runner(state_runner: StateContainer) -> State:
	#state_runner.add_state(self)
	#return self
	




# Action Factory:
# on("signal_name").send_broadcast()
# on("...").emit_signal()
# on("...").transition_to(...)
# on("...").
# on(TimerEvent.new(0.25).and
#func on(event: Event) -> EventHandlerFactory:
	#return EventHandlerFactory.new(self, event)
	#if condition is Signal:
		#self.on_signal(condition, action)
		#
	#elif condition is String:
		#self.on_signal_path(condition, action)
		#
	#elif condition is Callable:
		#self.on_callable(condition, action)
		#
	#elif condition is Countdown:
		#self.on_signal(condition.elapsed, action)
		#
	#return self

#func on_2(condition: Variant) -> EventHandlerFactory:
	#return EventHandlerFactory.new()

# func clear_all_enter_methods():
# 	self.enter_events.clear()
# 	return self
	
# func clear_all_update_methods():
# 	self.update_events.clear()
# 	return self
	
# func clear_all_exit_methods():
# 	self.exit_events.clear()
# 	return self
	
func keep_alive() -> State:
	## Stops the State from automatically-exiting if there are no Update Events defined.
	self._exit_after_enter_if_no_update_events = false
	return self

#func emit_signal_on(signal_name: StringName, condition: Variant, args: Array = []) -> State:
	#self.on(condition, self.emit_signal.bindv([signal_name] + args))
	#return self
	
func enter() -> bool:
	if self._debug: print(self.id, " ENTER (State)", StateStatus.keys()[self.status])
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
	if self._debug: print(self.id, " UPDATING ", StateStatus.keys()[self.status])
		
	var custom_update_method_return_value: bool = false
	for update_method in self.update_events:
		#if self.status == StateStatus.EXITED:
			#custom_update_method_return_value = true
			#break
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
		
	#for action in self.actions:
		#action.call()
	if not custom_update_method_return_value:
		if self._exit_after_enter_if_no_update_events and len(self.update_events) == 0:
			return true
	self.updated.emit(delta * speed_scale)
	return custom_update_method_return_value


## Handles the exit routine for the state.
##
## This method changes the state's status to EXITED if it was previously RUNNING. 
## It then calls all the exit methods bound to this state. 
## 
## Returns: `true` if the exit routine was executed, `false` if the state was already exited.
func exit() -> bool:
	if self._debug: print(self.id, " EXIT (State) : ", StateStatus.keys()[self.status])
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
