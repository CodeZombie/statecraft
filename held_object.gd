extends Sprite2D


func get_rotate_state() -> State:
	var state = State.new("rotate_wheee")
	
	state.set_on_enter(func(props):
		props['final_rotation'] = self.rotation + PI * 2
	)
	state.set_on_update(func(delta):
		self.rotation += PI * 2 * delta
	)
	state.add_timer(1, func():
		return StateQueue.TransitionToNextState.new()
	)
	state.set_on_exit(func(props):
		self.rotation = props['final_rotation']
	)
	return state
