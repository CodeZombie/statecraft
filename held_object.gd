extends Sprite2D


func get_rotate_state() -> State:
	return TimerState.new("rotate_timer", 1.0)\
	.add_enter_event(func(state: State):
		state.props['final_rotation'] = self.rotation + PI * 2)\
	.add_update_event(func(delta: float):
		self.rotation += PI * 2 * delta)\
	.add_exit_event(func(state: State):
			self.rotation = state.props['final_rotation'])
