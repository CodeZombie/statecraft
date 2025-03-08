class_name SignalRelayNode extends RelayNode

var _signal_virtual_connections: Dictionary[StringName, Array] = {}

var _unique_signal_name_interator: int = 0

# TODO:
# Implement WeakRefs for signal connections.
# This will allow us to connect signals to states or helper objects that may need to be deleted, and we don't want
# their references caught in signals or objects that won't allow them to delete.
# Use this as reference: https://gist.github.com/CodeZombie/ab87f5c004364a522c5a9efc53038bd2
# We may also want to wrap all callbacks in:
func _wrap_weakref_callback(object: Variant, callable: Callable) -> Callable:
	var weakref: WeakRef = WeakRef(object)
	return func():
		var object_: Object = weakref.get_ref()
		if object_:
			callable.call(object_)

# So now when we want to attach a child_state_a's callback `func(child_state): ...` to a parent state,
# we can do `parent_state.add_on_enter_callbac(_wrap_weakref_callback(child_state_a, func(state): print(state.id)))`
# and that'll work up until child_state_a is deleted, at which point the callback stops working.

###
### PUBLIC METHODS
###

func add_signal_callback(sig: Signal, callable: Callable, strip_args: bool = true) -> SignalRelayNode:
	self.recieve_message(RelayMessage.new(
		^"",
		RelayMessage.Type.CONNECT_EXTERNAL_SIGNAL,
		{
			"signal": sig,
			"callable": callable,
			"flags": 0,
			"strip_args": strip_args
		},
		false
	))
	return self

func add_signal_path_callback(signal_path: NodePath, callable: Callable, strip_args: bool = true) -> SignalRelayNode:
	#print("{0}.add_signal_path_callback({1}, ...)".format({0: self.id, 1: signal_path}))
	#var signal_path_array: Array[StringName] = RelayMessage.node_path_string_to_node_path_array(signal_path)
	#print("Signal path array: ", signal_path_array)
	#var signal_name: StringName = signal_path_array.pop_back()
	#print("signal_name: ", signal_name)
	#var target_node_path: StringName = '.'.join(signal_path_array)

	var signal_name: StringName = signal_path.get_subname(0)
	var target_node_path: NodePath = NodePath(signal_path.get_concatenated_names())

	self.recieve_message(RelayMessage.new(
		target_node_path,
		RelayMessage.Type.CONNECT_INTERNAL_SIGNAL,
		{
			"signal_name": signal_name,
			"callable": callable,
			"flags": 0,
			"strip_args": strip_args
		},
		true
	))
	return self
	
func create_unique_signal() -> Signal:
	var signal_name: StringName = StringName("__INTERNAL_SIGNAL_{0}".format({0:self._unique_signal_name_interator}))
	self._unique_signal_name_interator += 1
	self.add_user_signal(signal_name)
	return self.get_signal(signal_name)

func add_user_signal(signal_name: String, arguments: Array = []) -> void:
	super(signal_name, arguments)
	self.handle_all_permanent_messages_of_type(RelayMessage.Type.CONNECT_INTERNAL_SIGNAL)
	
func add_signal(signal_name: String, arguments: Array = []) -> SignalRelayNode:
	self.add_user_signal(signal_name, arguments)
	return self
	
func get_signal(signal_name) -> Variant:
	if self.has_signal(signal_name):
		return Signal(self, signal_name)
	return null

func get_signals_from_path(signal_path: NodePath) -> Variant: # Signal || null

	var signal_name: StringName = signal_path.get_subname(0)
	var target_node_path: NodePath = NodePath(signal_path.get_concatenated_names())
	var children_that_may_have_that_signal: Array = self.get_children(target_node_path)

	var signals: Array[Signal] = []
	for child in children_that_may_have_that_signal:
		var match_signal = child.get_signal(signal_name)
		if match_signal:
			signals.append(match_signal)
	return null

###
### PRIVATE METHODS
###

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
	#if self.status != StateStatus.RUNNING:
		#return
	print("Base signal callback: ", signal_name)
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
	if self._debug: print("{id}._handle_message: {msg}".format({'id': self.id, 'msg': relay_message}))
	if relay_message.message_type == RelayMessage.Type.CONNECT_EXTERNAL_SIGNAL:
		print("{0} handling internal sig connect message".format({0: self.id}))
		var signal_name: StringName = relay_message.args['signal'].get_name()
		print("    ", signal_name)
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
			print("    connecting: ", signal_unique_id)
			sig.connect(signal_callback_method.bind(signal_unique_id))
		
		if signal_unique_id not in self._signal_virtual_connections.keys():
			
			self._signal_virtual_connections[signal_unique_id] = []
			
		var callable: Callable = relay_message.args['callable']
		if callable not in self._signal_virtual_connections[signal_unique_id]:
			print("    attaching virtual")
			self._signal_virtual_connections[signal_unique_id].append(self._wrap_signal_callback(callable, relay_message.args['strip_args'], signal_argument_count))

		return true
		
	elif relay_message.message_type == RelayMessage.Type.CONNECT_INTERNAL_SIGNAL:
		print("{0}.handle(CONNECT_INTERNAL_SIGNAL)".format({0: self.id}))
		var signal_name: StringName = relay_message.args['signal_name']
		var signal_argument_count: int = self._get_internal_signal_argument_count(signal_name)
		var callable: Callable = relay_message.args['callable']
		var callable_argument_count: int = max(callable.get_unbound_arguments_count(), callable.get_argument_count())
		if callable_argument_count == signal_argument_count:
			self.connect(signal_name, callable, relay_message.args['flags'])
		elif callable_argument_count == signal_argument_count + 1:
			self.connect(signal_name, callable.bind(self), relay_message.args['flags'])

		return true
		
	return false
