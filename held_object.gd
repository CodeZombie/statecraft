extends Sprite2D


func get_rotate_state() -> State:
	
	var rotate_state: State = State.new("rotate"
	).add_enter_method(func(props: Dictionary):
		print("Propssss: ")
		print(props)
		props['final_rotation'] = self.rotation + PI * 2
	).add_update_method(func(delta: float):
		self.rotation += PI * 2 * delta
	).add_exit_method(func(props: Dictionary):
		self.rotation = props['final_rotation']
	)
	
	return ParallelStateQueue.new("sprite_2d_rotate"
	).add_state(rotate_state
	).add_state(TimerState.new("rotate_timer", 1.0))
