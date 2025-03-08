#class_name StateEvent extends Event
#
#enum EventType {
	#ENTERED,
	#UPDATED,
	#EXITED
#}
#
#var type: EventType
#
#func _init(type: EventType) -> void:
	#self.type = type
#
#func attach_to_state(state: State, callable: Callable, target_state_paths: Array[StringName] = [&""]) -> void:
	#var signal_name: StringName
	#var callable_: Callable = callable
	#match self.type:
		#EventType.ENTERED:
			#if callable.get_argument_count() == 1:
				#callable_ = callable.bind(parent_state)
			#signal_name = "entered"
		#EventType.UPDATED:
			#if callable.get_argument_count() == 2:
				#callable_ = callable.bind(parent_state)
			#signal_name = "updated"
		#EventType.EXITED:
			#if callable.get_argument_count() == 1:
				#callable_ = callable.bind(parent_state)
			#signal_name = "exited"
			#
	#parent_state.recieve_message(RelayMessage.new(
		#"",
		#RelayMessage.Type.CONNECT_INTERNAL_SIGNAL,
		#{
			#'signal_name': signal_name,
			#'callable': callable_,
			#'flags': 0
		#},
		#false
	#))
	#
	#
	##var callable_: Callable = callable
	##match type:
		##EventType.ENTERED:
			##if callable.get_argument_count() == 1:
				##callable_ = callable.bind(state)
			##state.connect("entered", callable_)
		##EventType.UPDATED:
			##if callable.get_argument_count() == 2:
				##callable_ = callable.bind(state)
			##state.connect("updated", callable_)
		##EventType.EXITED:
			##if callable.get_argument_count() == 1:
				##callable_ = callable.bind(state)
			##state.connect("exited", callable_)
