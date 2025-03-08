class_name ConditionEvent extends Event

var condition: Callable
var invert: bool

func _init(condition: Callable, invert: bool = false):
	self.condition = condition
	self.invert = invert

#func attach_to_state(state: State, target_state_path: StringName, callable: Callable) -> void:
	#var condition_ = self.condition
	#var invert_ = self.invert
	#state.add_updated_callback(func(delta_: float, state_: State):
		#if invert_:
			#if not State._call_with_optional_state(state_, condition_):
				#State._call_with_optional_state(state_, callable)
		#else:
			#if State._call_with_optional_state(state_, condition_):
				#State._call_with_optional_state(state_, callable)
		#)

#func attach_to_state(state: State, callable: Callable, target_state_paths: Array[StringName] = [&""]) -> void:
	#var callable_: Callable = State._bind_with_optional_state(state, callable)
	#if self.invert:
		#callable_ = State._invert_bound_callable(callable_)
	#state.recieve_message(RelayMessage.new(
		#target_state_path,
		#RelayMessage.Type.ADD_UPDATED_CALLBACK,
		#{
			#'callable': callable_
		#},
		#len(target_state_path) > 0
	#))


#Add a function to state's `updated` callback which, if succesful, emits a signal.
# for each 	`running_state_paths`, attach a listener to that signal that calls `callable`

#func attach_to_ddstate(state: State, callable: Callable, running_state_paths: Array = [&""]) -> void:
	#print("ConditionEvent.attach_to_state({0}, ..., {1})".format({0: state.id, 1: running_state_paths}))
	#var condition_: Callable = self.condition
	#if self.invert:
		#condition_ = State._invert_callable(condition_)
	#
	#var callable_: Callable = func(delta: float, state_: State):
		#if State._call_with_optional_state(state_, condition_):
			#if callable.get_argument_count() == 0:
				#callable.call()
			#elif callable.get_argument_count() == 1:
				#callable.call(delta)
			#elif callable.get_argument_count() == 2:
				#callable.call(delta, state)
			##State._call_with_optional_state(state_, callable)
			#
	#var spe: SignalPathEvent = SignalPathEvent.new(&"updated")
	#spe.attach_to_state(state, callable_, running_state_paths)
	
	
func attach_to_state(state: State, callable: Callable, running_state_paths: Array = [&""]) -> void:
	var condition_: Callable = State._bind_with_optional_state(state, self.condition)
	var callable_: Callable = State._bind_with_optional_state(state, callable)
	
	
	for state_path in running_state_paths:
		state.recieve_message(RelayMessage.new(
			state_path,
			RelayMessage.Type.ADD_UPDATED_CALLBACK,
			{
				'callable': func(): if condition_.call(): callable_.call()
			}
		))
	
	#var callable_: Callable = func(delta: float, state_: State):
		#if condition_:
			#if callable.get_argument_count() == 0:
				#callable.call()
			#elif callable.get_argument_count() == 1:
				#callable.call(delta)
			#elif callable.get_argument_count() == 2:
				#callable.call(delta, state)
#
	#var sig: Signal
	#
	#if running_state_paths == [&""] or len(running_state_paths) == 0:
		#state.add_updated_callback(callable_)
		##state.add_signal_path_callback(self.signal_path, callable_)
	#else:
		#sig = state.create_unique_signal()
		#state.add_updated_callback(func(delta: float, state: State): sig.emit())
		#
		#for running_state_path in running_state_paths:
			#state.recieve_message(RelayMessage.new(
				#running_state_path,
				#RelayMessage.Type.CONNECT_EXTERNAL_SIGNAL,
				#{
					#'signal': sig,
					#'callable': func(): callable_,
					#'strip_args': false
				#},
				#true
			#))
