class_name State

enum Status{READY, RUNNING, WAITING_TO_EXIT, EXITED}

#TODO:
# in the EventQueue and StateMachine, we need to check the return types from the `_process` method
# to make sure they're valid commands OR null.
# all other returns should raise an error telling the user not to return anything but valid commands.

# CHeck to see if elapsed_runtime is accurate!!!!!

# NOTES:
# when calling _update from an eventqueue, we need to make sure we always pass the real delta time and time_scale.
# dont ever give it `delta * time_scale` - that should only ever happen when calling the user's custom method or calculating event runtime.
class DynamicTween:
	var scene_node: Node
	var tween: Tween
	var tween_definition_method: Callable
	var on_finished: Variant
	var _finished: bool = false

	func _init(scene_node: Node, tween_definition_method: Callable, on_finished: Variant = null):
		self.scene_node = scene_node
		self.tween_definition_method = tween_definition_method
		self.on_finished = on_finished

	func start():
		if self.tween:
			self.tween.kill()
		self._finished = false
		self.tween = self.scene_node.create_tween()
		tween_definition_method.call(self.tween)
		self.tween.play()
		self.tween.pause()
		
	func process(delta, speed_scale):
		if self.tween and not self.is_finished():
			self._finished = not self.tween.custom_step(delta * speed_scale)
			if self.is_finished() and self.on_finished:
				return self.on_finished.call()
	
	func is_finished() -> bool:
		return self._finished
		
	func kill():
		if self.tween:
			self.tween.kill()
			self.tween = null

class DynamicTimer:
	var duration: float
	var elapsed: float = 0.0
	var on_finished: Callable
	
	func _init(duration: int, on_finished: Callable):
		self.duration = duration
		self.on_finished = on_finished
	
	func reset():
		self.elapsed = 0.0
	
	func process(delta: float, speed_scale: float):
		self.elapsed += delta * speed_scale
		if self.elapsed >= self.duration:
			return self.on_finished.call()
		
	func copy() -> DynamicTimer:
		return DynamicTimer.new(self.duration, self.on_finished)
		
	func is_done() -> bool:
		return elapsed == -1

	
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
var on_enter_method = null
var on_update_method = null
var on_exit_method = null
var skippable: bool
var created_by: String
var dynamic_timers: Array[DynamicTimer] = []
var dynamic_tweens: Array[DynamicTween] = []
var _status: Status = Status.READY
var _props: Dictionary = {}

func copy(new_state_id: String):
	var copy_state = State.new(new_state_id)
	copy_state.on_enter_method = self.on_enter_method
	copy_state.on_update_method = self.on_update_method
	copy_state.on_exit_method = self.on_exit_method
	copy_state.skippable = self.skippable
	for dynamic_timer in self.dynamic_timers:
		copy_state.add_timer(dynamic_timer.duration, dynamic_timer.on_finished)
	for dynamic_tween in self.dynamic_tweens:
		copy_state.add_tween(dynamic_tween.scene_node, dynamic_tween.tween_definition_method, dynamic_tween.on_finished)
	return copy_state

#func exit():
	#self._status = Status.WAITING_TO_EXIT

func run( speed_scale: float, loop: bool = false):
	if self._status == Status.READY:
		self.execute_on_enter_event()
		
	else:
		self.execute_on_update_event(Engine.get_main_loop().root.get_process_delta_time(), speed_scale)
		#
	#elif self._status == Status.WAITING_TO_EXIT:
		#self._on_exit([])
		#if loop:
			#self._status = Status.READY
		#else:
			#self._status = Status.EXITED
		
func _init(id: String, skippable: bool = false):
	self.id = id
	self.skippable = skippable

	for call_dict in get_stack():
		self.created_by += " --> {source}.{function}:{line}".format(call_dict)

func set_on_enter(on_enter_method: Callable):
	self.on_enter_method = on_enter_method
	return self

func set_on_update(closure_method: Callable):
	self.on_update_method = closure_method
	return self

func set_on_exit(closure_method: Callable):
	self.on_exit_method = closure_method
	return self

func add_timer(duration: float, on_finished: Callable):
	self.dynamic_timers.append(DynamicTimer.new(duration, on_finished))
	return self


func add_tween(scene_node: Node, tween_definition_method: Callable, on_finished: Variant = null):
	self.dynamic_tweens.append(DynamicTween.new(scene_node, tween_definition_method, on_finished))
	return self
	
func execute_on_enter_event() -> Variant:
	print(self.id + ".execute_on_enter_event()")
	
	self._props = {} # Clear props
	
	self._status = Status.RUNNING
	
	for dynamic_tween in self.dynamic_tweens:
		dynamic_tween.start()
		
	for dynamic_timer in self.dynamic_timers:
		dynamic_timer.reset()
		
	if self.on_enter_method and is_method_still_bound(self.on_enter_method):
		if self.on_enter_method.get_argument_count() > 0:
			return self.on_enter_method.call(self._props)
		else:
			return self.on_enter_method.call()
	
	return null

func execute_on_update_event(delta: float, speed_scale: float = 1) -> Variant:
	for dynamic_timer in self.dynamic_timers:
		var dynamic_timer_return_value: Variant = dynamic_timer.process(delta, speed_scale)
		if dynamic_timer_return_value:
			return dynamic_timer_return_value

	for dynamic_tween in self.dynamic_tweens:
		var dynamic_tween_return_value: Variant = dynamic_tween.process(delta, speed_scale)
		if dynamic_tween_return_value:
			return dynamic_tween_return_value
		
	if self.on_update_method and is_method_still_bound(self.on_update_method):
		var update_method_return_value: Variant
		if self.on_update_method.get_argument_count() == 2:
			update_method_return_value = self.on_update_method.call(self._props, delta * speed_scale)
		else:
			update_method_return_value = self.on_update_method.call(delta * speed_scale)
		if update_method_return_value:
			return update_method_return_value
			
	return null

func execute_on_exit_event(allow_repeat: bool = false) -> Variant:
	print(self.id + ".execute_on_exit_event()")
	
	self._status = Status.READY
	
	for dynamic_tween in dynamic_tweens:
		dynamic_tween.kill()
		
	if self.on_exit_method and is_method_still_bound(self.on_exit_method):
		if self.on_exit_method.get_argument_count() == 1:
			return self.on_exit_method.call(self._props)
		else:
			return self.on_exit_method.call()
		
	return null

# TODO: move this logic into the containers (StateQueue/StateMachine)
# maybe we add a "instantly_process_next_states(state_count: int)"
#func process_immediately():
	#if self.skippable:
		#return
	#while self._status != Status.WAITING_TO_EXIT:
		#self.execute_on_update_event(1, 1)

func is_method_still_bound(method: Callable) -> bool:
	if method.get_object() == null:
		push_error("ERROR: attemping to call method on State which has become unbound: ", self.created_by)
		return false
	return true
	
func get_debug_string() -> String:
	return self.id + ": " + self.get_status_string()

func get_status_string() -> String:
	return Status.keys()[self._status]
