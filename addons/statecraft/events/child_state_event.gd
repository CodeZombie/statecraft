#class_name ChildStateEvent extends Event
#
#enum EventType {
	#ENTERED,
	#UPDATED,
	#EXITED
#}
#
#var EventTypeToSignalMap = {
	#EventType.ENTERED: "entered",
	#EventType.UPDATED: "updated",
	#EventType.EXITED: "exited"
#}
#
#var target_state_path: StringName
#var type: EventType
#
#func _init(target_state_path: StringName, type: EventType) -> void:
	#self.target_state_path = target_state_path
	#self.type = type
#
#func attach_to_state(state: State, callable: Callable, target_state_paths: Array[StringName] = [&""]) -> void:
	#var callable_: Callable = callable
	#if max(callable.get_unbound_arguments_count(), callable.get_argument_count()) > 0:
		#callable_ = callable.bind(state)
		#
	#state.recieve_message(RelayMessage.new(
		#self.target_state_path,
		#RelayMessage.Type.CONNECT_INTERNAL_SIGNAL,
		#{
			#"signal_name": EventTypeToSignalMap[self.type],
			#"callable": callable_,
			#"flags": 0,
			#"strip_args": false
		#},
		#true
	#))
#
#
#func attach_to_state(state: State, callable: Callable, running_state_paths: Array[StringName] = [&""]) -> void:
	#var callable_: Callable = State._bind_with_optional_state(state, callable)
	#var sig: Signal
	#
	#if running_state_paths == [&""] or len(running_state_paths) == 0:
		#state.on_broadcast(self.broadcast_name, callable_)
	#else:
		#sig = state.create_unique_signal()
		#state.on_broadcast(self.broadcast_name, func(): sig.emit())
		#
		#for running_state_path in running_state_paths:
			#if running_state_path == &"":
				#continue
				#
			#state.recieve_message(RelayMessage.new(
				#running_state_path,
				#RelayMessage.Type.CONNECT_EXTERNAL_SIGNAL,
				#{
					#'signal': sig,
					#'callable': callable_,
					#'strip_args': false
				#},
				#true
			#))
