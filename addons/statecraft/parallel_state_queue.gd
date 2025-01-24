class_name ParallelStateQueue extends StateRunner

func enter():
	super()
	for child_state in self.child_states:
		child_state.enter()

func update(delta: float, speed_scale: float = 1.0):
	super(delta, speed_scale)
	for state in self.child_states:
		state.update(delta, speed_scale)

func exit():
	super()
	for child_state in self.child_states:
		child_state.exit()
