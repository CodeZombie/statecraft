class_name TimerEvent extends StateEvent

var duration: float

func _init(duration: float):
	self.duration = duration

func attach_to_state(state: State, callable: Callable, target_state_paths: Array = [^""]) -> void:
	var bound_callable: Callable = SCUtils.weakbind_state_to_callable(state, callable)
	var bridge_signal: Signal

	for target_state_path in target_state_paths:
		if target_state_path.get_name_count() == 0:
			state.add_on_timer_event(self.duration, bound_callable)
		else:
			if not bridge_signal:
				bridge_signal = state.create_unique_signal()
				state.add_on_timer_event(self.duration, func(): bridge_signal.emit())
				
			state.recieve_message(RelayMessage.new(
				target_state_path,
				&"connect_signal",
				[bridge_signal, bound_callable],
			))
			
