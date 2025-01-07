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
	var terminal: bool
	var _finished: bool = false

	func _init(tween_definition_method: Callable, terminal: bool, scene_node: Node):
		self.scene_node = scene_node
		self.tween_definition_method = tween_definition_method
		self.terminal = terminal

	func start():
		if self.tween:
			self.tween.kill()
		self._finished = false
		self.tween = self.scene_node.create_tween()
		tween_definition_method.call(self.tween)
		self.tween.play()
		self.tween.pause()
		
	func step(delta):
		if self.tween:
			self._finished = not self.tween.custom_step(delta)
	
	func is_finished() -> bool:
		return self._finished
		
	func kill():
		if self.tween:
			self.tween.kill()
			self.tween = null
		
	
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
var on_enter_method
var on_update_method
var on_exit_method
var skippable: bool
var created_by: String
var timeout_duration: float
var dynamic_tweens: Array[DynamicTween] = []
var custom_properties: Dictionary = {}
var _status: Status = Status.READY
var elapsed_runtime: float

func copy(new_state_id: String):
	var copy_state = State.new(new_state_id)
	copy_state.on_enter_method = self.on_enter_method
	copy_state.on_update_method = self.on_update_method
	copy_state.on_exit_method = self.on_exit_method
	copy_state.skippable = self.skippable
	copy_state.timeout_duration = self.timeout_duration
	for dynamic_tween in self.dynamic_tweens:
		copy_state.add_tween(dynamic_tween.terminal, dynamic_tween.scene_node, dynamic_tween.tween_definition_method)
	return copy_state

func exit():
	self._status = Status.WAITING_TO_EXIT

func run( speed_scale: float, loop: bool = false):
	if self._status == Status.READY:
		self._on_enter([])
		
	elif self._status == Status.RUNNING:
		var command = self._on_update([], Engine.get_main_loop().root.get_process_delta_time(), speed_scale)
		
	elif self._status == Status.WAITING_TO_EXIT:
		self._on_exit([])
		if loop:
			self._status = Status.READY
		else:
			self._status = Status.EXITED
		
func _init(id: String, skippable: bool = false):
	self.on_enter_method = null
	self.on_update_method = null
	self.on_exit_method = null
	self.id = id

	for call_dict in get_stack():
		self.created_by += " --> {source}.{function}:{line}".format(call_dict)

func set_on_enter(on_enter_method: Callable):
	self.on_enter_method = on_enter_method
	return self

func set_on_update(closure_method: Callable):

	self.on_update_method = closure_method
	return self

func set_on_exit(closure_method: Callable):
	var x = func():
		return closure_method
	self.on_exit_method = x.call()
	return self

func set_timeout(duration: float):
	self.timeout_duration = duration
	return self

#func attach_tween(tween: Tween, terminal: bool = true):
	#tween.stop() # In godot, tweens auto-play upon creation. We don't want that.
	#self.wrapped_tweens.append(TweenWrapper.new(tween, terminal))
	#return self
	#
func add_tween(terminal: bool, scene_node: Node, tween_definition_method: Callable):
	self.dynamic_tweens.append(DynamicTween.new(tween_definition_method, terminal, scene_node))
	return self
		
func _on_enter(state_stack):
	print(self.id + "._on_enter()")
	self.custom_properties = {}

	self.elapsed_runtime = 0.0

	if self.on_enter_method and is_method_still_bound(self.on_enter_method):
		self.on_enter_method.call([self] + state_stack)

	for dynamic_tween in self.dynamic_tweens:
		dynamic_tween.start()
		
	self._status = Status.RUNNING

func _on_update(state_stack, delta: float, speed_scale: float = 1):
	
	# If there's a timeout, check to see if it has elapsed, exiting if it has.
	self.elapsed_runtime += delta
	if self.timeout_duration and self.elapsed_runtime >= self.timeout_duration / speed_scale:
		return self.exit()
		
	# Check to see if all terminal tweens have ended. if they have, exit the event.
	var has_any_terminal_tweens = len(self.dynamic_tweens.filter(func(dt): return dt.terminal)) > 0
	var have_all_terminal_tweens_finished = true
	for dynamic_tween in self.dynamic_tweens:
		#wrapped_tween.tween.set_speed_scale(speed_scale)
		dynamic_tween.step(delta * speed_scale)
		if dynamic_tween.terminal and not dynamic_tween.is_finished():
			have_all_terminal_tweens_finished = false
	if has_any_terminal_tweens and have_all_terminal_tweens_finished:
		return self.exit()
		
	if self._status == Status.RUNNING:
		if self.on_update_method and is_method_still_bound(self.on_update_method):
			self.on_update_method.call([self] + state_stack, delta * speed_scale)

func _on_exit(state_stack, allow_repeat: bool = false):
	print(self.id + "._on_exit()")
	for dynamic_tween in dynamic_tweens:
		dynamic_tween.kill()
	if self.on_exit_method and is_method_still_bound(self.on_exit_method):
		self.on_exit_method.call([self] + state_stack)
	self._status = Status.READY

func process_immediately():
	if self.skippable:
		return
	while self._status != Status.WAITING_TO_EXIT:
		self._on_update(1, 1)

func is_method_still_bound(method: Callable) -> bool:
	if method.get_object() == null:
		push_error("ERROR: attemping to call method on State which has become unbound: ", self.created_by)
		return false
	return true
	
func get_debug_string() -> String:
	return self.id + ": " + self.get_status_string()

func get_status_string() -> String:
	return Status.keys()[self._status]
