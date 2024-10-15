class_name State

class EXIT_COMMAND:
	pass
	
enum StateState{WAITING, RUNNING, EXITING}

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
	var create_tween_method: Callable
	var terminal: bool
	var _finished: bool = false

	func _init(create_tween_method_closure: Callable, terminal: bool, scene_node: Node):
		self.scene_node = scene_node
		self.create_tween_method = create_tween_method_closure.call()
		self.terminal = terminal
	
	func start():
		if self.tween:
			self.tween.kill()
		self._finished = false
		self.tween = self.scene_node.create_tween()
		create_tween_method.call(self.tween)
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
var elapsed_runtime: float
var dynamic_tweens: Array[DynamicTween] = []
var custom_properties: Dictionary = {}

var _state: StateState = StateState.WAITING

# Static Methods:
static func exit():
	return EXIT_COMMAND.new()
	
# Instance Methods
func run(delta: float, speed_scale: float):
	if _state == StateState.WAITING:
		self._on_enter()
		
	if self._state == StateState.RUNNING:
		var command = self._on_update(delta, speed_scale)
		
		if command is State.EXIT_COMMAND:
			self._on_exit()
		
func _init(id: String, skippable: bool = false):
	self.on_enter_method = null
	self.on_update_method = null
	self.on_exit_method = null
	self.id = id

	for call_dict in get_stack():
		self.created_by += " --> {source}.{function}:{line}".format(call_dict)

func set_on_enter(closure_method: Callable):
	self.on_enter_method = closure_method.call()
	return self

func set_on_update(closure_method: Callable):
	self.on_update_method = closure_method.call()
	return self

func set_on_exit(closure_method: Callable):
	self.on_exit_method = closure_method.call()
	return self

func set_timeout(duration: float):
	self.timeout_duration = duration
	return self

#func attach_tween(tween: Tween, terminal: bool = true):
	#tween.stop() # In godot, tweens auto-play upon creation. We don't want that.
	#self.wrapped_tweens.append(TweenWrapper.new(tween, terminal))
	#return self
	#
func add_tween(terminal: bool, scene_node: Node, tween_creation_closure: Callable):
	self.dynamic_tweens.append(DynamicTween.new(tween_creation_closure, terminal, scene_node))
	return self
		
func _on_enter():
	print(self.id + "._on_enter()")
	self.custom_properties = {}

	self.elapsed_runtime = 0.0

	if self.on_enter_method and is_method_still_bound(self.on_enter_method):
		self.on_enter_method.call(self)

	for dynamic_tween in self.dynamic_tweens:
		dynamic_tween.start()
		
	self._state = StateState.RUNNING

func _on_update(delta: float, speed_scale: float = 1):
	# on_update can return a "EXIT_COMMAND", which will ask the parent state to exit this current one.
	var command = null
	
	# If there's a timeout, check to see if it has elapsed, exiting if it has.
	self.elapsed_runtime += delta
	
	if self.timeout_duration and self.elapsed_runtime >= self.timeout_duration / speed_scale:
		command = State.exit()
		
	# Check to see if all terminal tweens have ended. if they have, exit the event.
	var has_any_terminal_tweens = len(self.dynamic_tweens.filter(func(dt): return dt.terminal)) > 0
	var have_all_terminal_tweens_finished = true
	for dynamic_tween in self.dynamic_tweens:
		#wrapped_tween.tween.set_speed_scale(speed_scale)
		dynamic_tween.step(delta * speed_scale)
		if dynamic_tween.terminal and not dynamic_tween.is_finished():
			have_all_terminal_tweens_finished = false
	if has_any_terminal_tweens and have_all_terminal_tweens_finished:
		command = State.exit()

	if self.on_update_method and is_method_still_bound(self.on_update_method):
		var on_update_method_return_value = self.on_update_method.call(self, delta * speed_scale)
		if on_update_method_return_value is EXIT_COMMAND:
			command = on_update_method_return_value
		elif on_update_method_return_value != null:
			push_error("Statecraft Error: A State's `on_update` method should not return anything except State Commands.")
	
	if command is EXIT_COMMAND:
		return command

func _on_exit(allow_repeat: bool = false):
	print(self.id + "._on_exit()")
	self._state = StateState.EXITING
	for dynamic_tween in dynamic_tweens:
		dynamic_tween.kill()
	if self.on_exit_method and is_method_still_bound(self.on_exit_method):
		self.on_exit_method.call(self)
		
	self._state = StateState.WAITING

func process_immediately():
	if self.skippable:
		return
	
	while self._on_update(1, 1) is not EXIT_COMMAND:
		pass

func is_method_still_bound(method: Callable) -> bool:
	if method.get_object() == null:
		push_error("ERROR: attemping to call method on State which has become unbound: ", self.created_by)
		return false
	return true
