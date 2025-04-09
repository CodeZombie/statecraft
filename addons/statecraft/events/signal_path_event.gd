class_name SignalPathEvent extends StateEvent

var signal_path: NodePath

func _init(signal_path: NodePath):
	self.signal_path = signal_path

func attach_to_state(state: State, callable: Callable, target_state_paths: Array = [^""]) -> void:
	var bound_callable: Callable = SCUtils.weakbind_state_to_callable(state, callable)
	var bridge_signal: Signal
	var signal_name: StringName = self.signal_path.get_subname(0)
	var signal_node_path: NodePath = NodePath(self.signal_path.get_concatenated_names())

	for target_state_path in target_state_paths:
		if target_state_path.get_name_count() == 0:
			state.recieve_message(RelayMessage.new(
				signal_node_path,
				&"connect_signal_via_name",
				[signal_name, bound_callable]
			))
		else:
			if not bridge_signal:
				bridge_signal = state.create_unique_signal()
				state.recieve_message(RelayMessage.new(
					signal_node_path,
					&"connect_signal_via_name",
					[signal_name, func(): bridge_signal.emit()],
				))

			state.recieve_message(RelayMessage.new(
				target_state_path,
				&"connect_signal",
				[bridge_signal, bound_callable],
			))
