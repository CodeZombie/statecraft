class_name SignalRelayNode extends RelayNode

var _signal_virtual_connections: Dictionary[StringName, Array] = {}

var _unique_signal_name_iterator: int = 0

func create_unique_signal() -> Signal:
	var signal_name: StringName = StringName("__INTERNAL_SIGNAL_{0}".format({0:self._unique_signal_name_iterator}))
	self._unique_signal_name_iterator += 1
	self.add_user_signal(signal_name)
	return self.get_signal(signal_name)

func add_user_signal(signal_name: String, arguments: Array = []) -> void:
	super(signal_name, arguments)
	self.handle_all_relay_messages_of_type(&"connect_signal_via_path")
	
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
			elif callable_arg_count == 0:
				callable.call()
			else:
				assert(false, "{cb} Callable argument count ({0}) does not match signal with an argument count of {1}".format({'cb': self.created_by, 0: callable_arg_count, 1: signal_argument_count}))

func connect_signal(sig: Signal, callable: Callable, strip_args: bool = false) -> void:
	var signal_name: StringName = sig.get_name()
	var signal_unique_id: StringName = StringName(signal_name + str(sig.get_object_id()))
	var signal_argument_count: int = self._get_signal_argument_count(sig)
	
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
		
	if callable not in self._signal_virtual_connections[signal_unique_id]:
		self._signal_virtual_connections[signal_unique_id].append(self._wrap_signal_callback(callable, strip_args, signal_argument_count))

func connect_signal_via_name(signal_name: StringName, callable: Callable, flags: int = 0, strip_args: bool = false) -> void:
	
	if not self.has_signal(signal_name):
		print(self.id, " does not have signal ", signal_name)
		return
		
	self.connect_signal(self.get_signal(signal_name), callable, strip_args)
	#print(self.id, ":", signal_name, " connected")
	#var signal_argument_count: int = self._get_internal_signal_argument_count(signal_name)
	#var callable_argument_count: int = max(callable.get_unbound_arguments_count(), callable.get_argument_count())
	#if callable_argument_count == signal_argument_count:
		#self.connect(signal_name, callable, flags)
	#elif callable_argument_count == signal_argument_count + 1:
		#self.connect(signal_name, callable.bind(self), flags)
	#else:
		#assert(false, str("Error: could not connected ", self.id, ":", signal_name, ". Callable arg count mismatch."))
