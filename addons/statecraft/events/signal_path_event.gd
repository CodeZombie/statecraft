class_name SignalPathEvent extends Event

var signal_path: NodePath
#var signal_node_path: NodePath
#var signal_name: StringName

func _init(signal_path: NodePath):
	self.signal_path = signal_path
	#self.signal_name = signal_path.get_subname(0)
	#self.signal_path = NodePath(signal_path.get_concatenated_names())

#func attach_to_state(state: State, callable: Callable) -> void:
	#state.add_signal_path_callback(self.signal_path, callable)


#.on_signal_path("on_ground.jump").transition("sliding.decelerating", "jumping")
# What happens here is:
# the on_ground.jump signal is found in the `on_ground` state.
# it's Connects a callable to the signal which checks if `parent_state.is_running("sliding.decelerating")`, and if true,
# it executes `parent_state.transition_to("jumping")`


# func attach_to_state(state: State, callable: Callable, running_state_paths: Array = [&""]) -> void:
# 	print("SignalPathEvent({sig}).attach_to_state({0}, ..., {1})".format({0: state.id, 1: running_state_paths, 'sig': self.signal_path}))
# 	var callable_: Callable = State._bind_with_optional_state(state, callable)
# 	var sig: Signal
# 	print("nuhhhhh")
# 	if running_state_paths == [&""] or len(running_state_paths) == 0:
# 		state.add_signal_path_callback(self.signal_path, callable_)
# 	else:
# 		sig = state.create_unique_signal()
# 		state.add_signal_path_callback(self.signal_path, func():
# 			print("mitm sig for {0} called".format({0: self.signal_path}))
# 			sig.emit())
		
# 		for running_state_path in running_state_paths:
# 			if running_state_path == &"":
# 				continue
# 			print("Sending connect internal signal ({0}) to state {1}".format({0: sig.get_name(),1: running_state_path }))
# 			state.recieve_message(RelayMessage.new(
# 				running_state_path,
# 				RelayMessage.Type.CONNECT_EXTERNAL_SIGNAL,
# 				{
# 					'signal': sig,
# 					'callable': func(): print("piss and shit fuck"), #callable_,
# 					'strip_args': false
# 				},
# 				true
# 			))

func attach_to_state(state: State, callable: Callable, target_state_paths: Array[NodePath] = [^""] as Array[NodePath]) -> void:
	var bound_callable: Callable = SCUtils.weakbind_state_to_callable(state, callable)
	var bridge_signal: Signal
	var signal_name: StringName = self.signal_path.get_subname(0)
	var signal_node_path: NodePath = NodePath(self.signal_path.get_concatenated_names())

	for target_state_path in target_state_paths:
		if target_state_path.get_name_count() == 0:
			state.recieve_message(RelayMessage.new(
				signal_node_path,
				&"connect_signal_via_name",
				[signal_name, bound_callable],
				true
			))
		else:
			if not bridge_signal:
				bridge_signal = state.create_unique_signal()
				state.recieve_message(RelayMessage.new(
					signal_node_path,
					&"connect_signal_via_name",
					[signal_name, func(): bridge_signal.emit()],
					true
				))

			state.recieve_message(RelayMessage.new(
				target_state_path,
				&"connect_signal",
				[bridge_signal, bound_callable],
				true
			))
