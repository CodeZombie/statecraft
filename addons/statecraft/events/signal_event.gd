class_name SignalEvent extends Event

var sig: Signal
var strip_args: bool 

func _init(sig: Signal, strip_args: bool = false):
	self.sig = sig
	self.strip_args = strip_args

#func attach_to_state(state_: State, target_state_path: StringName, callable: Callable) -> void:
	#
	#self.sig.connect(State._bind_with_optional_state(state_, callable))

func attach_to_state(state: State, callable: Callable, running_state_paths: Array = [&""]) -> void:
	var sig_ = self.sig
	var strip_args_ = self.strip_args
	
	for running_state_path in running_state_paths:
		state.recieve_message(RelayMessage.new(
			running_state_path,
			RelayMessage.Type.CONNECT_EXTERNAL_SIGNAL,
			{
				'signal': sig_,
				'callable': State._bind_with_optional_state(state, callable),
				'strip_args': strip_args_
				
			},
			len(running_state_path) > 0
		))
