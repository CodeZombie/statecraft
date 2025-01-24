extends Sprite2D


func get_rotate_state() -> State:
	return ParallelStateQueue.new("sprite_2d_rotate")\
	.add_state(
		State.new("rotate")\
		.add_enter_method(func(state: State):
			state.props['final_rotation'] = self.rotation + PI * 2)\
		.add_update_method(func(delta: float):
			self.rotation += PI * 2 * delta)\
		.add_exit_method(func(state: State):
			self.rotation = state.props['final_rotation']))\
	.add_state(TimerState.new("rotate_timer", 1.0))
	
