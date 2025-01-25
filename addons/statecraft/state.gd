class_name State

enum Status{READY, RUNNING, WAITING_TO_EXIT, EXITED}

# TODO: CHeck to see if elapsed_runtime is accurate!!!!!

# NOTES:
# when calling _update from an eventqueue, we need to make sure we always pass the real delta time and time_scale.
# dont ever give it `delta * time_scale` - that should only ever happen when calling the user's custom method or calculating event runtime.
		
var id: String
var enter_events: Array[Callable] = []
var update_events: Array[Callable] = []
var exit_events: Array[Callable] = []
var skippable: bool
var created_by: String
var _status: Status = Status.READY
var props: Dictionary = {}
var actions: Array[Callable] = []
var message_handlers: Dictionary[String, Array] = {}

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

func _init(id: String, skippable: bool = false):
	self.id = id
	self.skippable = skippable

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
	sig.connect(action.call)
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
	
func emit(message_id: String):
	if message_id in self.message_handlers.keys():
		for message_handler_callable in self.message_handlers[message_id]:
			message_handler_callable.call()
	
func enter():

	self.props = {}
	
	self._status = Status.RUNNING
	
	for enter_method in self.enter_events:
		if is_method_still_bound(enter_method):
			if enter_method.get_argument_count() > 0:
				enter_method.call(self)
			else:
				enter_method.call()

func update(delta: float, speed_scale: float = 1):
	for update_method in self.update_events:
		if is_method_still_bound(update_method):
			if update_method.get_argument_count() == 2:
				update_method.call(self, delta * speed_scale)
			else:
				update_method.call(delta * speed_scale)
		
	for action in self.actions:
		action.call()

func exit():
	self._status = Status.READY
	for exit_method in self.exit_events:
		if is_method_still_bound(exit_method):
			if exit_method.get_argument_count() == 1:
				exit_method.call(self)
			else:
				exit_method.call()

func restart():
	self.exit()
	self.enter()

func run( speed_scale: float):
	if self._status == Status.READY:
		self.enter()
		
	if self._status == Status.RUNNING:
		self.update(Engine.get_main_loop().root.get_process_delta_time(), speed_scale)
		
	# TODO: How does exit() get run???????

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
	return Status.keys()[self._status]
