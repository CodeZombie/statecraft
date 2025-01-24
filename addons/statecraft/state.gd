class_name State

enum Status{READY, RUNNING, WAITING_TO_EXIT, EXITED}

# TODO: CHeck to see if elapsed_runtime is accurate!!!!!

# NOTES:
# when calling _update from an eventqueue, we need to make sure we always pass the real delta time and time_scale.
# dont ever give it `delta * time_scale` - that should only ever happen when calling the user's custom method or calculating event runtime.
#
#class DynamicTween:
	#var scene_node: Node
	#var tween: Tween
	#var tween_definition_method: Callable
	#var on_finished: Variant
	#var _finished: bool = false
#
	#func _init(scene_node: Node, tween_definition_method: Callable, on_finished: Variant = null):
		#self.scene_node = scene_node
		#self.tween_definition_method = tween_definition_method
		#self.on_finished = on_finished
#
	#func start():
		#if self.tween:
			#self.tween.kill()
		#self._finished = false
		#self.tween = self.scene_node.create_tween()
		#tween_definition_method.call(self.tween)
		#self.tween.play()
		#self.tween.pause()
		#
	#func process(delta, speed_scale):
		#if self.tween and not self.is_finished():
			#self._finished = not self.tween.custom_step(delta * speed_scale)
			##if self.is_finished() and self.on_finished:
				##return self.on_finished.call()
	#
	#func is_finished() -> bool:
		#return self._finished
		#
	#func kill():
		#if self.tween:
			#self.tween.kill()
			#self.tween = null

#class DynamicTimer:
	#var duration: float
	#var elapsed: float = 0.0
	#var on_finished: Callable
	#
	#func _init(duration: int, on_finished: Callable):
		#self.duration = duration
		#self.on_finished = on_finished
	#
	#func reset():
		#self.elapsed = 0.0
	#
	#func process(delta: float, speed_scale: float):
		#self.elapsed += delta * speed_scale
		#if self.elapsed >= self.duration:
			#return self.on_finished.call()
		#
	#func copy() -> DynamicTimer:
		#return DynamicTimer.new(self.duration, self.on_finished)
		#
	#func is_done() -> bool:
		#return elapsed == -1
	#
#class TweenWrapper:
	#var tween: Tween
	#var terminal: bool
	#var has_finished: bool = false
	#
	#func _init(tween: Tween, terminal: bool = true):
		#self.tween = tween
		#self.terminal = terminal
	#
	#func step(delta: float):
		#self.has_finished = not self.tween.custom_step(delta)
				#
	#func is_finished():
		#return self.has_finished
		
var id: String
var on_enter_methods: Array[Callable] = []
var on_update_methods: Array[Callable] = []
var on_exit_methods: Array[Callable] = []
var skippable: bool
var created_by: String
#var dynamic_timers: Array[DynamicTimer] = []
#var dynamic_tweens: Array[DynamicTween] = []
var _status: Status = Status.READY
var props: Dictionary = {}
#var conditions: Dictionary[String, Callable] = {}

var message_handlers: Dictionary[String, Array] = {}

func copy(new_state_id: String):
	var copy_state = State.new(new_state_id, self.skippable)
	for enter_method in self.on_enter_methods:
		copy_state.add_enter_method(enter_method)
	for update_method in self.on_update_methods:
		copy_state.add_update_method(update_method)
	for exit_method in self.on_exit_methods:
		copy_state.add_exit_method(exit_method)
	return copy_state

#func exit():
	#self._status = Status.WAITING_TO_EXIT

func _init(id: String, skippable: bool = false):
	self.id = id
	self.skippable = skippable

	for call_dict in get_stack():
		self.created_by += " --> {source}.{function}:{line}".format(call_dict)

func add_to_runner(state_runner: StateRunner) -> State:
	state_runner.add_state(self)
	return self
	
func add_enter_method(on_enter_method: Callable) -> State:
	self.on_enter_methods.append(on_enter_method)
	return self

func add_update_method(closure_method: Callable) -> State:
	self.on_update_methods.append(closure_method)
	return self

func add_exit_method(closure_method: Callable) -> State:
	self.on_exit_methods.append(closure_method)
	return self
	
#func add_condition(condition_id: String, condition_callable: Callable) -> State:
	#self.conditions[condition_id] = condition_callable
	#return self
	#
#func get_condition(condition_id: String) -> Callable:
	#return self.conditions[condition_id]
	
func clear_all_enter_methods():
	self.on_enter_methods.clear()
	return self
func clear_all_update_methods():
	self.on_update_methods.clear()
	return self
func clear_all_exit_methods():
	self.on_exit_methods.clear()
	return self
#func clear_all_conditions():
	#self.conditions = {}
	#return self

#func add_timer(duration: float, on_finished: Callable):
	#self.dynamic_timers.append(DynamicTimer.new(duration, on_finished))
	#return self


#func add_tween(scene_node: Node, tween_definition_method: Callable, on_finished: Variant = null):
	#self.dynamic_tweens.append(DynamicTween.new(scene_node, tween_definition_method, on_finished))
	#return self

func add_message_handler(message_id: String, message_handler_callable: Callable):
	if message_id not in self.message_handlers.keys():
		self.message_handlers[message_id] = []
	self.message_handlers[message_id].append(message_handler_callable)

func emit(message_id: String):
	if message_id in self.message_handlers.keys():
		for message_handler_callable in self.message_handlers[message_id]:
			message_handler_callable.call()
	
func enter():

	self.props = {} # Clear props
	
	self._status = Status.RUNNING
	
	#for dynamic_tween in self.dynamic_tweens:
		#dynamic_tween.start()
		#
	#for dynamic_timer in self.dynamic_timers:
		#dynamic_timer.reset()
	for enter_method in self.on_enter_methods:
		if is_method_still_bound(enter_method):
			if enter_method.get_argument_count() > 0:
				enter_method.call(self)
			else:
				enter_method.call()

func update(delta: float, speed_scale: float = 1):
	#for dynamic_timer in self.dynamic_timers:
		#var dynamic_timer_return_value: Variant = dynamic_timer.process(delta, speed_scale)
		#if dynamic_timer_return_value:
			#return dynamic_timer_return_value
#
	#for dynamic_tween in self.dynamic_tweens:
		#var dynamic_tween_return_value: Variant = dynamic_tween.process(delta, speed_scale)
		#if dynamic_tween_return_value:
			#return dynamic_tween_return_value
	for update_method in self.on_update_methods:
		if is_method_still_bound(update_method):
			if update_method.get_argument_count() == 2:
				update_method.call(self, delta * speed_scale)
			else:
				update_method.call(delta * speed_scale)

func exit():
	self._status = Status.READY
	for exit_method in self.on_exit_methods:
		if is_method_still_bound(exit_method):
			if exit_method.get_argument_count() == 1:
				exit_method.call(self)
			else:
				exit_method.call()

	
func restart():
	self.exit()
	self.enter()

#func condition_met(condition_id: String) -> bool:
	#if condition_id in self.conditions.keys():
		#if self.conditions[condition_id].get_argument_count() == 1:
			#return self.conditions[condition_id].call(self)
		#else:
			#return self.conditions[condition_id].call()	
	#return false

#func get_messages() -> Array[String]:
	#var passed_message_ids: Array[String] = []
	#for message in self.messages:
		#var message_triggered: bool = message.condition.call()
		#if message_triggered:
			#passed_message_ids.append(message.id)
	#return passed_message_ids

# TODO: move this logic into the containers (StateQueue/StateMachine)
# maybe we add a "instantly_process_next_states(state_count: int)"
#func process_immediately():
	#if self.skippable:
		#return
	#while self._status != Status.WAITING_TO_EXIT:
		#self.execute_on_update_event(1, 1)

#func run_instantly(skip_if_skippable: bool = false):
	#if skip_if_skippable and self.skippable:
		#return
		#
	#self.execute_on_enter_event()

func run( speed_scale: float, loop: bool = false):
	if self._status == Status.READY:
		self.enter()
		
	if self._status == Status.RUNNING:
		self.update(Engine.get_main_loop().root.get_process_delta_time(), speed_scale)
		
	# TODO: How does exit() get run???????

	#elif self._status == Status.WAITING_TO_EXIT:
		#self._on_exit([])
		#if loop:
			#self._status = Status.READY
		#else:
			#self._status = Status.EXITED

func is_method_still_bound(method: Callable) -> bool:
	if method.get_object() == null:
		push_error("ERROR: attemping to call method on State which has become unbound: ", self.created_by)
		return false
	return true
	
func as_string(indent: int = 0) -> String:
	var indent_string: String = ""
	for i in range(indent):
		indent_string += " "
	return indent_string + self.id + ": " + self.get_status_string() + "e" + str(len(self.on_enter_methods))

func get_status_string() -> String:
	return Status.keys()[self._status]
