extends Sprite2D


func get_rotate_state() -> State:
	return State.new(
		"sprite_2d_rotate"
	).set_on_enter(func(props):
		props['final_rotation'] = self.rotation + PI * 2
	).set_on_update(func(delta):
		self.rotation += PI * 2 * delta
	).add_timer(1, func():
		return StateQueue.TransitionToNextState.new()
	).set_on_exit(func(props):
		self.rotation = props['final_rotation']
	)
