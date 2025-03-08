class_name SignalPathEvent extends Event

var signal_path: StringName

func _init(signal_path: StringName):
	print("Signal Path Event: {0}".format({0: signal_path}))
	self.signal_path = signal_path

#func attach_to_state(state: State, callable: Callable) -> void:
	#state.add_signal_path_callback(self.signal_path, callable)


#.on_signal_path("on_ground.jump").transition("sliding.decelerating", "jumping")
# What happens here is:
# the on_ground.jump signal is found in the `on_ground` state.
# it's Connects a callable to the signal which checks if `parent_state.is_running("sliding.decelerating")`, and if true,
# it executes `parent_state.transition_to("jumping")`


func attach_to_state(state: State, callable: Callable, running_state_paths: Array = [&""]) -> void:
	print("SignalPathEvent({sig}).attach_to_state({0}, ..., {1})".format({0: state.id, 1: running_state_paths, 'sig': self.signal_path}))
	var callable_: Callable = State._bind_with_optional_state(state, callable)
	var sig: Signal
	print("nuhhhhh")
	if running_state_paths == [&""] or len(running_state_paths) == 0:
		state.add_signal_path_callback(self.signal_path, callable_)
	else:
		sig = state.create_unique_signal()
		state.add_signal_path_callback(self.signal_path, func():
			print("mitm sig for {0} called".format({0: self.signal_path}))
			sig.emit())
		
		for running_state_path in running_state_paths:
			if running_state_path == &"":
				continue
			print("Sending connect internal signal ({0}) to state {1}".format({0: sig.get_name(),1: running_state_path }))
			state.recieve_message(RelayMessage.new(
				running_state_path,
				RelayMessage.Type.CONNECT_EXTERNAL_SIGNAL,
				{
					'signal': sig,
					'callable': func(): print("piss and shit fuck"), #callable_,
					'strip_args': false
				},
				true
			))
