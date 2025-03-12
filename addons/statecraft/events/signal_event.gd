class_name SignalEvent extends Event

var sig: Signal
var strip_args: bool 

func _init(sig: Signal, strip_args: bool = false):
	self.sig = sig
	self.strip_args = strip_args

#func attach_to_state(state_: State, target_state_path: StringName, callable: Callable) -> void:
	#
	#self.sig.connect(State._bind_with_optional_state(state_, callable))

# func attach_to_state(state: State, callable: Callable, running_state_paths: Array = [&""]) -> void:
# 	var sig_ = self.sig
# 	var strip_args_ = self.strip_args
	
# 	for running_state_path in running_state_paths:
# 		state.recieve_message(RelayMessage.new(
# 			running_state_path,
# 			RelayMessage.Type.CONNECT_EXTERNAL_SIGNAL,
# 			{
# 				'signal': sig_,
# 				'callable': State._bind_with_optional_state(state, callable),
# 				'strip_args': strip_args_
				
# 			},
# 			len(running_state_path) > 0
# 		))


func attach_to_state(state: State, callable: Callable, target_state_paths: Array[NodePath] = [^""] as Array[NodePath]) -> void:
	var signal_ = self.sig
	var strip_args_ = self.strip_args
	var bound_callable: Callable = SCUtils.weakbind_state_to_callable(state, callable)
	
	for target_state_path in target_state_paths:
		if target_state_path.get_name_count() == 0:
			state.connect_signal(signal_, SCUtils.call_with_possible_args(callable, [state]), strip_args_)
		else:
			state.recieve_message(RelayMessage.new(
				target_state_path,
				&"connect_signal",
				[signal_, bound_callable, strip_args_],
				true
			))
