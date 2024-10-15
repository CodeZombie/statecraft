extends Sprite2D


func get_rotate_state() -> State:
	var state = State.new("rotate")
	state.set_on_update(func(state, delta):
		self.rotation += PI/2 * delta)
	state.set_timeout(4)
	return state
