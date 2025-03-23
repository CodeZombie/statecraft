class_name BroadcastEvent extends StateEvent

var broadcast_name: StringName

func _init(broadcast_name_: StringName):
	self.broadcast_name = broadcast_name_

func attach_to_state(state: State, callable: Callable, target_state_paths: Array = [^""]) -> void:
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
			))
