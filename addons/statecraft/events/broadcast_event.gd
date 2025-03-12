class_name BroadcastEvent extends Event

var broadcast_name: StringName

func _init(broadcast_name_: StringName):
	self.broadcast_name = broadcast_name_
	#
#func attach_to_state(state: State, callable: Callable, target_state_paths: Array[StringName] = [&""]) -> void:
	#for target_state_path in target_state_paths:
		#state.recieve_message(RelayMessage.new(
			#target_state_path,
			#RelayMessage.Type.ATTACH_ON_BROADCAST_CALLBACK,
			#{
				#'broadcast_name': self.broadcast_name,
				#'callback': State._bind_with_optional_state(state, callback)
			#},
			#target_state_path != &""
		#))
	##state.add_on_broadcast_callback(self.broadcast_name, callback)
#

# func attach_to_state(state: State, callable: Callable, running_state_paths: Array = [&""]) -> void:
# 	var callable_: Callable = State._bind_with_optional_state(state, callable)
# 	var sig: Signal
	
# 	if running_state_paths == [&""] or len(running_state_paths) == 0:
# 		state.add_on_broadcast_callback(self.broadcast_name, callable_)
# 	else:
# 		sig = state.create_unique_signal()
# 		state.add_on_broadcast_callback(self.broadcast_name, func(): sig.emit())
		
# 		for running_state_path in running_state_paths:
# 			if running_state_path == &"":
# 				continue
			
# 			state.recieve_message(RelayMessage.new(
# 				running_state_path,
# 				RelayMessage.Type.CONNECT_EXTERNAL_SIGNAL,
# 				{
# 					'signal': sig,
# 					'callable': callable_,
# 					'strip_args': false
# 				},
# 				true
# 			))

func attach_to_state(state: State, callable: Callable, target_state_paths: Array[NodePath] = [^""] as Array[NodePath]) -> void:
	var bound_callable: Callable = SCUtils.weakbind_state_to_callable(state, callable)
	var broadcast_name_: StringName = self.broadcast_name

	for target_state_path in target_state_paths:
		if target_state_path.get_name_count() == 0:
			state.add_on_broadcast_callback(broadcast_name_, bound_callable)
		else:
			state.recieve_message(RelayMessage.new(
				target_state_path,
				&"add_on_broadcast_callback",
				[broadcast_name_, bound_callable],
				true
			))
